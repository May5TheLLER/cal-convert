from latex2asciimath.latex2ascii import latex2ascii

latex = r"\frac{x}{1+x}"
asciimath = latex2ascii(latex)
print(asciimath)  # 會輸出: x/(1+x)