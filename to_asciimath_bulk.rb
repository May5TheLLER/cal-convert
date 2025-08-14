
#!/usr/bin/env ruby
# file: to_asciimath_bulk.rb

require 'csv'
require 'plurimath'
require 'cgi'

# 1. 輸入／輸出檔名

target = File.read("current_target.txt").strip
INPUT_CSV = target

OUTPUT_CSV = 'ascii_' + target

# 2. 把一段 LaTeX 轉成純 AsciiMath
def latex2ascii(latex)

  return '' if latex.nil? || latex.empty?
  begin

    # 使極限符號能正確顯示
    latex.gsub!(/\\mathop\{\\lim\s*\}/, '')
    latex.gsub!(/\\limits(\s*_\{[^}]+\})/, '\\lim\1')
    latex.gsub!(/{\\rm lim}/, '\1') #遇到{\rm lim}直接刪除
    latex.gsub!(/\{\\rm\s+(.*?)\}/ , '\1') #遇到 {\rm n} 後只保留n
    latex.gsub!(/\\mathop\{(.*?)\}/, '\1') #遇到 \mathtop{n} 後只保留n

    # 正確轉換Latex的\; \,避免被PluriMath直接轉成分號和逗號
    latex.gsub!(/\\;/, "\u2004") # 把\;換成three-per-em space
    latex.gsub!(/\\,/, "\u2009") # 把\,換成thin space
    
    # 調整不支援的符號
    latex.gsub!(/\\textit/, '')

    ast   = Plurimath::Math.parse(latex, :latex)
    ascii = ast.to_asciimath

    # 刪掉純排版的 \left / \right
    ascii.gsub!(/left/, "")
    ascii.gsub!(/right/, "")

    # 解除 &gt; &le; 等 HTML entity，還原 Unicode code point
    ascii = CGI.unescapeHTML(ascii)
    ascii = ascii.gsub(/&#x([\da-fA-F]+);/) { [$1.hex].pack('U') }

    #  換行符號處理，使分段定義函數能正確顯示
    ascii.gsub!(/:\[(.*?)\]:/m) do
     body = $1.gsub(/"\s*"/, '],[')
     ":[" + body + "]:"
    end

    # 替換中括號內的分號為逗號，讓分段定義函數的範圍部分能對齊
    ascii.gsub!(/\[(.*?)\]/m) do |match|
      "[" + $1.gsub(/;/, ',') + "]"
    end

    # 調整不支援的符號
    replacements = {
      /"P{geqslant}"/      => '>=',
      /"P{duni}"/          => 'bigcup',
      /"P{mid}"/           => '|',
      /"P{smblkcircle}"/   => 'cdot',
      /"P{Re}"/            => 'R',
      /"P{underline}"/     => '_',
      /𝜔/                  => 'omega',
      /, ; ;/              => '|',
      /rm\(([^)]*)\)/      => '\1'
    }
    replacements.each { |pattern, replacement| ascii.gsub!(pattern, replacement) }
    


    ascii.strip
  rescue => e

    "Failed to parse"

  end
end

# 3. 包上 ` `
def wrap_fs(eq)
  return '' if eq.nil? || eq.empty?
  %Q{`#{eq}`}
end

# 4. 處理 CSV
CSV.open(OUTPUT_CSV, "w",
         encoding: "bom|utf-8",
         write_headers: true,
         headers: CSV.read(INPUT_CSV, encoding: "bom|utf-8", headers: true).headers) do |out_csv|

  CSV.foreach(INPUT_CSV, encoding: "bom|utf-8", headers: true) do |row|
    # 4-a. 題目欄
    if row['Unnamed: 3'] && row['Unnamed: 3'].include?('$')
      raw = row['Unnamed: 3']
      # 提取所有 $…$，逐段轉
      conv1 = raw.gsub(/\$([^$]+)\$/) { |m|
        wrap_fs( latex2ascii($1) )
      }
      row['Unnamed: 3'] = conv1
    end

    # 4-b. 解說攔
    if row['Unnamed: 5'] && row['Unnamed: 5'].include?('$')
      raw = row['Unnamed: 5']
      # 提取所有 $…$，逐段轉
      conv2 = raw.gsub(/\$([^$]+)\$/) { |m|
        wrap_fs( latex2ascii($1) )
      }
      row['Unnamed: 5'] = conv2
    end

    # 4-c. 選項欄 (Unnamed: 7 to Unnamed: 26)
    (7..26).each do |i|
      col = "Unnamed: #{i}"
      next unless row[col] && row[col].include?('$')
      raw = row[col]
      row[col] = raw.gsub(/\$([^$]+)\$/) { wrap_fs( latex2ascii($1) ) }
    end

    out_csv << row
  end
end

puts "轉檔完成，輸出：#{OUTPUT_CSV}"