#!/usr/bin/env ruby
# file: to_asciimath_bulk.rb
#
# 把 convert.py 產出的 iLearning CSV 裡的 LaTeX（$…$）批次轉成 AsciiMath。
# 轉換規則全部定義在 toasciimath.rb，這裡直接引用，不需要再複製規則過來。

require 'csv'
require_relative 'toasciimath'

# 1. 輸入／輸出檔名：由命令列指定，輸出放在同一個資料夾，檔名前面加上 ascii_
#    用法：bundle exec ruby to_asciimath_bulk.rb output/ilearning_xxx.csv
abort '用法：bundle exec ruby to_asciimath_bulk.rb <ilearning_xxx.csv>' if ARGV.empty?
INPUT_CSV  = ARGV[0]
OUTPUT_CSV = File.join(File.dirname(INPUT_CSV), 'ascii_' + File.basename(INPUT_CSV))

# 2. 要轉換的欄位：題目、解說、選項 1～20
COLUMNS = ['Unnamed: 3', 'Unnamed: 5'] + (7..26).map { |i| "Unnamed: #{i}" }

# 3. 處理 CSV
headers = CSV.read(INPUT_CSV, encoding: 'bom|utf-8', headers: true).headers
failed  = 0

CSV.open(OUTPUT_CSV, 'w', encoding: 'bom|utf-8', write_headers: true, headers: headers) do |out_csv|
  CSV.foreach(INPUT_CSV, encoding: 'bom|utf-8', headers: true) do |row|
    COLUMNS.each do |col|
      next unless row[col]
      row[col] = ToAsciiMath.convert_text(row[col])
      failed += row[col].scan('Failed to parse').size
    end
    out_csv << row
  end
end

puts "轉檔完成，輸出：#{OUTPUT_CSV}"
puts "有 #{failed} 段 LaTeX 轉換失敗，請搜尋 \"Failed to parse\" 並到 toasciimath.rb 補規則" if failed > 0
