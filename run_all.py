import subprocess




print("Running convert.py ...")
subprocess.run(["python", "convert.py"], check=True)


print("Running to_asciimath_bulk.rb ...")
subprocess.run(["ruby", "to_asciimath_bulk.rb"], check=True)

print("整合流程完成！")