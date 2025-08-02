require 'plurimath'
#puts "Hello, world!"
asciimath = "$ f left( x right) = frac(1)(2) left( x + left| x right| right) $"
formula = Plurimath::Math.parse(asciimath, :asciimath)
latex = formula.to_latex
puts latex

