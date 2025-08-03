require 'plurimath'
require 'cgi'


latex_list = [
  '若$f\left(x\right)=\left\{\begin{array}{c} {x^{3} +1,\quad x\le 0} \\ {2+x,\quad 0<x<2} \\ {4,\quad x\ge 2} \end{array}\right.$，則 $f\left(f\left(0\right)\right)+f\left(f\left(3\right)\right)$=?',
  '$f\\left(g\\left(x\\right)\\right)=\\left\\{\\begin{array}{c} {0;\\quad -1<x} \\\\ {1;\\quad -5\\le x\\le -1} \\\\ {3;\\quad x<-5} \\end{array}\\right.$',
  '利用絕對值特性，得$f\left(x\right)= \frac{1}{2}(x+\left| x \right|)=\left\{\begin{array}{c} {x;\quad x\geqslant 0} \\ {0;\quad x<0} \end{array}\right.$ ，'
]

latex_list.each do |latex|
  formula = Plurimath::Math.parse(latex, :latex)
  asciimath = formula.to_asciimath

  # 移除 left/right 使括號正常顯示
  asciimath.gsub!(/left/, "")
  asciimath.gsub!(/right/, "")

  # 還原中文
  asciimath = CGI.unescapeHTML(asciimath)
  asciimath = asciimath.gsub(/&#x([\da-fA-F]+);/) { [$1.hex].pack("U") }

  # 換行符號處理(也太鬼畫符了吧)
  asciimath.gsub!(/:\[(.*?)\]:/m) do
    body = $1.gsub(/"\s*"/, '],[')
    ":[" + body + "]:"
  end

  #一些小調整
  asciimath.gsub!(/"P{geqslant}"/,'>=')
  asciimath.gsub!(/\$/,"")

  puts asciimath
  puts
end




