#!/usr/bin/env ruby
# file: to_asciimath_bulk_utf16le.rb

require 'csv'
require 'plurimath'
require 'cgi'

# 1. 輸入／輸出檔名
INPUT_CSV  = 'converted_puretext_ilearning.csv'
OUTPUT_CSV = 'ilearning_ascii_wrapped_utf16le.csv'

# 2. 把一段 LaTeX 轉成純 AsciiMath
def latex2ascii(latex)
  return '' if latex.nil? || latex.empty?

  # 刪掉純排版的 \left / \right
  s = latex.gsub(/\\left|\\right/, '')

  # 解析並輸出 AsciiMath
  ast   = Plurimath::Math.parse(s, :latex)
  ascii = ast.to_asciimath

  # 解除 &gt; &le; 等 HTML entity，還原 Unicode code point
  ascii = CGI.unescapeHTML(ascii)
  ascii = ascii.gsub(/&#x([\da-fA-F]+);/) { [$1.hex].pack('U') }

  ascii.strip
end

# 3. 包成 <div><span class="fs-equation">…</span></div>
def wrap_fs(expr)
  return '' if expr.nil? || expr.empty?
  %Q{<div><span class="fs-equation">`#{expr}`</span></div>}
end

# 4. 讀一次拿到表頭
headers = CSV.read(INPUT_CSV, encoding: 'bom|utf-8', headers: true).headers

# 5. 開檔並手動寫入 UTF-16LE BOM (0xFFFE)
File.open(OUTPUT_CSV, 'wb') do |f|
  # 寫入 UTF-16LE 的 BOM (FE FF → 寫成 LE 就是 FF FE)
  f.write "\uFEFF".encode('UTF-16LE')

  # 初始化 CSV writer，外層為 UTF-16LE，內部轉自 UTF-8
  csv = CSV.new(f,
    write_headers: true,
    headers: headers,
    encoding: 'UTF-16LE:UTF-8'
  )

  # 6. 逐列處理
  CSV.foreach(INPUT_CSV, encoding: 'bom|utf-8', headers: true) do |row|
    # 題目欄 (假設是 Unnamed: 3)
    if row['Unnamed: 3']&.include?('$')
      row['Unnamed: 3'] = row['Unnamed: 3'].gsub(/\$([^$]+)\$/) do
        wrap_fs(latex2ascii($1))
      end
    end

    # 選項欄 Unnamed: 7 ~ Unnamed: 26
    (7..26).each do |i|
      col = "Unnamed: #{i}"
      next unless row[col]&.include?('$')
      row[col] = row[col].gsub(/\$([^$]+)\$/) do
        wrap_fs(latex2ascii($1))
      end
    end

    csv << row
  end
end

puts "完成：#{OUTPUT_CSV}（UTF-16 LE + BOM）"
