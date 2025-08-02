require 'plurimath'
require 'cgi'

latex = '若$f\left(x\right)=\left\{\begin{array}{c} {x^{3} +1,\quad x\le 0}
         \\ {2+x,\quad 0<x<2} \\ {4,\quad x\ge 2} \end{array}\right.$，
         則 $f\left(f\left(0\right)\right)+f\left(f\left(3\right)\right)$=?'
formula = Plurimath::Math.parse(latex, :latex)
asciimath = formula.to_asciimath
#把left right給移除
asciimath.gsub!(/left/, "")
asciimath.gsub!(/right/, "")

#把中文給還原
asciimath = CGI.unescapeHTML(asciimath)
asciimath = asciimath.gsub(/&#x([\da-fA-F]+);/) { [$1.hex].pack("U") }
puts asciimath

