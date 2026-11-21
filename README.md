## Setup (once)
1. Clone the repository to local environment.
2. Install Python packages: `pip install -r requirements.txt`
3. Install Ruby packages: `bundle install`

## Convert question banks
1. Put the question bank `.xlsx` files into the `input/` folder. File names should start with the chapter number, e.g. `5 - 1 Find Areas Between Curves & Volumes ....xlsx`.
2. Run one of:
   - `python run_all.py 5-1` to convert chapter 5-1 (several chapters: `python run_all.py 5-1 7-2`)
   - `python run_all.py --all` to convert every file in `input/`
   - `python run_all.py` to pick from a numbered list of chapters
3. The results are written to `output/`. The file to upload is `ascii_ilearning_***.csv`. The summary at the end shows how many questions were converted and how many LaTeX segments failed.
4. If a chapter reports failures, search for "Failed to parse" in its output file. Copy the failing string into TEST_LATEX_LIST in "toasciimath.rb" (or pass it as an argument: `bundle exec ruby toasciimath.rb '$...$'`), then update the rules (LATEX_RULES / ASCII_RULES) in "toasciimath.rb" until it converts correctly. "to_asciimath_bulk.rb" uses the rules in "toasciimath.rb" directly, so there is no need to copy code. Run step 2 again.
5. If there is no "Failed to parse" in the output file, upload it to iLearning.

`--input` and `--output` change the folders if needed. The two steps can also be run on their own: `python convert.py input/xxx.xlsx` and `bundle exec ruby to_asciimath_bulk.rb output/ilearning_xxx.csv`.
