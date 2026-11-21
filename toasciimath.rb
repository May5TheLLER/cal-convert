#!/usr/bin/env ruby
# file: toasciimath.rb
#
# LaTeX → AsciiMath 的轉換規則都集中在這個檔案。
#
# 用法：
#   1. 測試規則：直接執行這個檔案
#        bundle exec ruby toasciimath.rb                 # 跑下方 TEST_LATEX_LIST 裡的範例
#        bundle exec ruby toasciimath.rb '$\frac{1}{x}$' # 或從命令列帶入要測試的 LaTeX
#   2. 批次轉檔：to_asciimath_bulk.rb 會 require 這個檔案，直接使用同一套規則，
#      所以在這裡改好規則後，不需要再複製到 to_asciimath_bulk.rb。

require 'plurimath'
require 'cgi'

module ToAsciiMath
  # 交給 Plurimath 解析「之前」，先對 LaTeX 做的替換（依序套用，順序有影響）
  LATEX_RULES = [
    # 使極限符號能正確顯示
    [/\\mathop\{\\lim\s*\}/, ''],
    [/\\sum\s+\\limits/, '\\sum'],               # 遇到 \sum \limits 保留 sum 刪除
    [/\\sum\s*\\limits/, '\\sum'],               # 遇到 \sum\limits 保留 sum 刪除
    [/\\limits(\s*_\{[^}]+\})/, '\\lim\1'],
    [/{\\rm lim}/, '\1'],                        # 遇到 {\rm lim} 直接刪除
    [/\{\\rm\s+(.*?)\}/, '\1'],                  # 遇到 {\rm n} 後只保留 n
    [/\\mathop\{(.*?)\}/, '\1'],                 # 遇到 \mathop{n} 後只保留 n

    # 正確轉換 LaTeX 的 \; \,，避免被 Plurimath 直接轉成分號和逗號
    [/\\;/, "\u2004"],                           # 把 \; 換成 three-per-em space
    [/\\,/, "\u2009"],                           # 把 \, 換成 thin space
    [/\{\\kern\s*1pt\}/, "\u2009"],

    # 調整不支援的符號
    [/\\textit/, ''],
    [/\\textstyle/, ''],
    [/\\textrm\{(.*?)\}/, '\1'],
    [/\\hphantom\{\\cdot\}/, ''],
    [/\\overrightarrow/, '\\vec'],
    [/!\\!\\!\\!\\int\\nolimits/, 'int'],
    [/\\underline\{(.*?)\}/, '?'],
    [/\\!\\!\\!\\!/, ''],
  ].freeze

  # Plurimath 轉出 AsciiMath「之後」，修正不支援的符號
  ASCII_RULES = [
    [/"P{geqslant}"/,    '>='],
    [/"P{duni}"/,        'bigcup'],
    [/"P{mid}"/,         '|'],
    [/"P{smblkcircle}"/, 'cdot'],
    [/"P{Re}"/,          'R'],
    [/"P{underline}"/,   '_'],
    [/𝜔/,                'omega'],
    [/, ; ;/,            '|'],
    [/rm\(([^)]*)\)/,    '\1'],                  # 遇到 rm(n) 後只保留 n
    [/"P{intx}"/,        'int x'],
  ].freeze

  module_function

  # 把一段 LaTeX（不含外層的 $）轉成 AsciiMath。轉換失敗時會丟出例外。
  # 注意：前處理規則會直接修改傳入的字串（與原本 gsub! 的行為相同）。
  def convert(latex)
    LATEX_RULES.each { |pattern, replacement| latex.gsub!(pattern, replacement) }

    ascii = Plurimath::Math.parse(latex, :latex).to_asciimath

    # 刪掉純排版的 left / right，使括號正常顯示
    ascii.gsub!(/left/, '')
    ascii.gsub!(/right/, '')

    # 解除 &gt; &le; 等 HTML entity，還原 Unicode code point（例如中文）
    ascii = CGI.unescapeHTML(ascii)
    ascii = ascii.gsub(/&#x([\da-fA-F]+);/) { [$1.hex].pack('U') }

    # 換行符號處理，使分段定義函數能正確顯示
    ascii.gsub!(/:\[(.*?)\]:/m) do
      body = $1.gsub(/"\s*"/, '],[')
      ':[' + body + ']:'
    end

    # 替換中括號內的分號為逗號，讓分段定義函數的範圍部分能對齊
    ascii.gsub!(/\[(.*?)\]/m) { '[' + $1.gsub(/;/, ',') + ']' }

    ASCII_RULES.each { |pattern, replacement| ascii.gsub!(pattern, replacement) }

    ascii.strip
  end

  # 批次轉檔用：失敗時不中斷，回傳 "Failed to parse: <前處理後的 LaTeX>"，方便之後搜尋並補規則
  def latex2ascii(latex)
    return '' if latex.nil? || latex.empty?
    latex = latex.dup
    convert(latex)
  rescue StandardError
    'Failed to parse: ' + latex
  end

  # 把一段文字裡所有的 $…$ 逐段轉成 `AsciiMath`
  def convert_text(text)
    return text unless text && text.include?('$')
    text.gsub(/\$([^$]+)\$/) do
      eq = latex2ascii($1)
      eq.empty? ? '' : "`#{eq}`"
    end
  end
end

# ---- 直接執行這個檔案時：測試規則 -------------------------------------------
if __FILE__ == $PROGRAM_NAME
  # 把要測試的 LaTeX 放在這裡（可以含 $…$ 和中文，跟題庫裡的寫法一樣）
  TEST_LATEX_LIST = [
    '$\, {\kern 1pt} y=x{\kern 1pt} {\kern 1pt}$',
  ]

  inputs = ARGV.empty? ? TEST_LATEX_LIST : ARGV
  inputs.each do |text|
    puts "輸入：#{text}"
    puts "輸出：#{ToAsciiMath.convert_text(text)}"
    puts
  end
end
