require 'plurimath'
require 'cgi'

#latex轉換成asciimath的主要邏輯與條整，可將要轉換的latex放在latex_list用於測試

latex_list = [
  '$\, {\kern 1pt} y=x{\kern 1pt} {\kern 1pt}$'
]


latex_list.each do |latex|

  #使極限符號能正確顯示
  latex.gsub!(/\\mathop\{\\lim\s*\}/, '')
  latex.gsub!(/\\limits(\s*_\{[^}]+\})/, '\\lim\1')

  latex.gsub!(/{\\rm lim}/, '\1') #遇到{\rm lim}直接刪除
  latex.gsub!(/\{\\rm\s+(.*?)\}/ , '\1') #遇到 {\rm n} 後只保留n
  latex.gsub!(/\\mathop\{(.*?)\}/, '\1') #遇到 \mathtop{n} 後只保留n
  latex.gsub!(/\\;/, "\u2004") # 把\;換成three-per-em space
  latex.gsub!(/\\,/, "\u2009") # 把\,換成thin space
  latex.gsub!(/\{\\kern\s*1pt\}/, "\u2009")

  # 調整不支援的符號
  latex.gsub!(/\\textit/, '')
  latex.gsub!(/\\texstyle/, '')
  latex.gsub!(/\\hphantom\{\\cdot\}/, '')
  latex.gsub!(/\\textrm\{(.*?)\}/, '\1')
  puts latex
  
  formula = Plurimath::Math.parse(latex, :latex)

  #極限表達的修正

  asciimath = formula.to_asciimath

  # 移除 left/right 使括號正常顯示
  asciimath.gsub!(/left/, "")
  asciimath.gsub!(/right/, "")

  # 還原中文
  asciimath = CGI.unescapeHTML(asciimath)
  asciimath = asciimath.gsub(/&#x([\da-fA-F]+);/) { [$1.hex].pack("U") }

  #  換行符號處理，使分段定義函數能正確顯示
  asciimath.gsub!(/:\[(.*?)\]:/m) do
    body = $1.gsub(/"\s*"/, '],[')
    ":[" + body + "]:"
  end

  # 替換中括號內的分號為逗號，讓分段定義函數的範圍部分能對齊
  asciimath.gsub!(/\[(.*?)\]/m) do |match|
    "[" + $1.gsub(/;/, ',') + "]"
  end

  # 調整不支援的符號
    replacements = {
      /"P{geqslant}"/ => '>=',
      /"P{duni}"/ => 'bigcup',
      /"P{mid}"/ => '|',
      /"P{smblkcircle}"/ => 'cdot',
      /"P{Re}"/ => 'R',
      /"P{underline}"/ => '_',
      /𝜔/ => 'omega',
      /, ; ;/ => '|',
      /rm\(([^)]*)\)/ => '\1', #遇到 rm(n) 後只保留n
      /"P{intx}"/ => 'int x',
    }

    replacements.each do |pattern, replacement|
      asciimath.gsub!(pattern, replacement)
    end


  puts asciimath
  puts
end




