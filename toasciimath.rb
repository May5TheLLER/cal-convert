require 'plurimath'
require 'cgi'

#latex = '若$f\left(x\right)=\left\{\begin{array}{c} {x^{3} +1,\quad x\le 0}
#         \\ {2+x,\quad 0<x<2} \\ {4,\quad x\ge 2} \end{array}\right.$，
#         則 $f\left(f\left(0\right)\right)+f\left(f\left(3\right)\right)$=?'

latex = '$f\left(x\right)=\frac{1}{2} \left(x+\left|x\right|\right)$；
         $g\left(x\right)=\left\{\begin{array}{c} {1;\quad 1<x} \\ 
         {2;\quad 0\le x\le 1} \\ {3;\quad x<0} \end{array}\right.$ ，'
formula = Plurimath::Math.parse(latex, :latex)
asciimath = formula.to_asciimath

#把left right給移除使括號正常顯示
asciimath.gsub!(/left/, "")
asciimath.gsub!(/right/, "")


#把中文給還原
asciimath = CGI.unescapeHTML(asciimath)
asciimath = asciimath.gsub(/&#x([\da-fA-F]+);/) { [$1.hex].pack("U") }

#讓換行符號正確顯示(這也太鬼畫符了吧)
asciimath.gsub!(/:\[(.*?)\]:/m) do
  body = $1.gsub(/"\s*"/, '),(')
  ":(" + body + "):"
end

puts asciimath



