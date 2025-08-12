require 'plurimath'
require 'cgi'

#latex轉換成asciimath的主要邏輯與條整，可將要轉換的latex放在latex_list用於測試

latex_list = [
  '$\textit{c}$'
]


latex_list.each do |latex|

  #使極限符號能正確顯示
  latex.gsub!(/\\mathop\{\\lim\s*\}/, '')
  latex.gsub!(/\\limits(\s*_\{[^}]+\})/, '\\lim\1')

  # 調整不支援的符號
  latex.gsub!(/\\textit/, '')
  puts latex
  
  formula = Plurimath::Math.parse(latex, :latex)

  #極限表達的修正

  asciimathmath = formula.to_asciimathmath

  # 移除 left/right 使括號正常顯示
  asciimathmath.gsub!(/left/, "")
  asciimathmath.gsub!(/right/, "")

  # 還原中文
  asciimathmath = CGI.unescapeHTML(asciimathmath)
  asciimathmath = asciimathmath.gsub(/&#x([\da-fA-F]+);/) { [$1.hex].pack("U") }

  # 換行符號處理
  asciimathmath.gsub!(/:\[(.*?)\]:/m) do
    body = $1.gsub(/"\s*"/, '],[')
    ":[" + body + "]:"
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
      /rm\(([^)]*)\)/ => '\1',
    }

    replacements.each do |pattern, replacement|
      asciimathmath.gsub!(pattern, replacement)
    end


  puts asciimathmath
  puts
end




