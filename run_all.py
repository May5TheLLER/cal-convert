"""題庫轉檔的主程式：Excel 題庫 → iLearning CSV → 數學式轉成 AsciiMath

把題庫 xlsx 放進 input/ 資料夾後執行：
    python run_all.py 5-1          # 只轉「5 - 1 ...」那份
    python run_all.py 5-1 7-2      # 一次轉多份
    python run_all.py --all        # 轉 input/ 裡的全部題庫
    python run_all.py              # 不帶參數：列出所有章節讓你選
結果會放在 output/，最後上傳到 iLearning 的是 ascii_ilearning_*.csv。
"""
import argparse
import glob
import os
import re
import shutil
import subprocess
import sys

from convert import convert

HERE = os.path.dirname(os.path.abspath(__file__))


def list_question_banks(input_dir):
    """input/ 裡所有的題庫，依章節編號排序（略過 Excel 開檔時產生的 ~$ 暫存檔）"""
    files = [f for f in glob.glob(os.path.join(input_dir, "*.xlsx"))
             if not os.path.basename(f).startswith("~$")]

    def chapter_key(path):
        m = re.match(r"\s*(\d+)\s*-\s*(\d+)", os.path.basename(path))
        return (int(m.group(1)), int(m.group(2))) if m else (float("inf"), 0)

    return sorted(files, key=lambda f: (chapter_key(f), os.path.basename(f)))


def find_chapter(files, chapter):
    """用章節編號（例如 5-1）找出檔名開頭是「5 - 1」的題庫"""
    m = re.fullmatch(r"\s*(\d+)\s*-\s*(\d+)\s*", chapter)
    if not m:
        sys.exit(f"章節編號格式不對：{chapter}（應該像 5-1 這樣）")
    pattern = re.compile(rf"\s*{m.group(1)}\s*-\s*{m.group(2)}(?!\d)")
    matches = [f for f in files if pattern.match(os.path.basename(f))]
    if not matches:
        sys.exit(f"在 input 資料夾找不到章節 {chapter} 的題庫")
    if len(matches) > 1:
        names = "\n  ".join(os.path.basename(f) for f in matches)
        sys.exit(f"章節 {chapter} 對應到不只一份題庫：\n  {names}")
    return matches[0]


def choose_interactively(files):
    """沒有指定章節時，列出所有題庫讓使用者輸入編號"""
    for i, f in enumerate(files, 1):
        print(f"{i:>3}. {os.path.basename(f)}")
    answer = input("\n要轉換哪幾份？輸入編號（可用空白分隔多個，all 代表全部）：").strip()
    if answer.lower() == "all":
        return files
    try:
        return [files[int(x) - 1] for x in answer.split()]
    except (ValueError, IndexError):
        sys.exit("輸入的編號不正確")


def ruby_command():
    """優先使用 bundle exec ruby（會用 Gemfile 裡的套件），找不到 bundle 時退回 ruby"""
    bundle = shutil.which("bundle")
    if bundle:
        return [bundle, "exec", "ruby"]
    ruby = shutil.which("ruby")
    if ruby:
        return [ruby]
    sys.exit("找不到 ruby，請先安裝 Ruby 並執行 bundle install")


def main():
    parser = argparse.ArgumentParser(description="把 Excel 題庫轉成可匯入 iLearning 的 CSV")
    parser.add_argument("chapters", nargs="*", help="章節編號，例如 5-1 7-2")
    parser.add_argument("--all", action="store_true", help="轉換 input 資料夾裡的全部題庫")
    parser.add_argument("--input", default=os.path.join(HERE, "input"), help="題庫 xlsx 所在的資料夾（預設 input/）")
    parser.add_argument("--output", default=os.path.join(HERE, "output"), help="輸出資料夾（預設 output/）")
    args = parser.parse_args()

    files = list_question_banks(args.input)
    if not files:
        sys.exit(f"在 {args.input} 找不到任何 .xlsx 題庫")

    if args.all:
        targets = files
    elif args.chapters:
        targets = [find_chapter(files, c) for c in args.chapters]
    else:
        targets = choose_interactively(files)

    ruby = ruby_command()
    summary = []
    for xlsx in targets:
        name = os.path.basename(xlsx)
        print(f"\n=== {name}")
        csv_path, n_questions = convert(xlsx, args.output)
        subprocess.run(ruby + [os.path.join(HERE, "to_asciimath_bulk.rb"), csv_path], check=True, cwd=HERE)

        ascii_path = os.path.join(os.path.dirname(csv_path), "ascii_" + os.path.basename(csv_path))
        with open(ascii_path, encoding="utf-8-sig") as f:
            failed = f.read().count("Failed to parse")
        summary.append((name, n_questions, failed, ascii_path))

    print("\n=== 摘要")
    for name, n_questions, failed, ascii_path in summary:
        status = "全部成功" if failed == 0 else f"{failed} 段轉換失敗，請搜尋 \"Failed to parse\""
        print(f"{name}：{n_questions} 題，{status}")
        print(f"  → {ascii_path}")


if __name__ == "__main__":
    main()
