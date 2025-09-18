1. Clone the repository to local environment.
2. Put the file to convert to excel_paths.py .
3. Update excel_path_list[13] in "target = excel_path_list[13]" to the correct target.
4. Run convert.py . The output file name will be in "current_target.txt"
5. Remember to install "Code Runner" extensions in Visual Studio Code to run Ruby. Or run "bundle exec ruby to_asciimath_bulk.rb".
6. The output file should be "ascii_ilearning_***.csv"
7. Search if there is any "Failed to parse" in the output file. If any, copy the fail string to upgrade "toasciimath.rb" and upgrade the code accordingly. After upgraded "toasciimath.rb", copy new code to "to_asciimath_bulk.rb", and restart from Step 5.
8. If there is no "Failed to parse" in the output file, then uploaded to iLearning...