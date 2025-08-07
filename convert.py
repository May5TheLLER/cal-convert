import pandas as pd
import ast
import csv


# === 1. 讀取 Excel 題庫 ===
excel_path = "1 - 1 Functions 函數.xlsx"  

df = pd.read_excel(excel_path)

# === 2. 建立轉換後資料表 ===
n_rows = len(df) + 2
converted = pd.DataFrame(index=range(n_rows))

# === 3. 固定欄位 ===
converted["version: 4"] = ["題組", ""] + [""] * len(df)
converted["Unnamed: 1"] = ["類別", ""] + [""] * len(df)

# === 4. 題型欄位 ===
def map_question_type(t):
    return {"是非題": 1, "單選題": 2, "複選題": 3}.get(t, 2)

converted["Unnamed: 2"] = ["題型:\n(1)是非\n(2)單選\n(3)複選\n(4)填充\n(5)問答\n(6)說明", "2"] + [
    map_question_type(q) for q in df["類型"]
]

# === 5. 包裝 AsciiMath 題幹 ===
def wrap_asciimath(text):
    content = str(text).replace("`", "'")
    return content

converted["Unnamed: 3"] = ["題目", ""] + [wrap_asciimath(q) for q in df["題目"]]

# === 6. 正確答案轉換 ===
def map_answer(ans):
    ans = str(ans).strip()
    if ans.lower() == "true":
        return 1
    elif ans.lower() == "false":
        return 2
    elif ans in "ABCDEFGHIJ":
        return "ABCDEFGHIJ".index(ans) + 1
    else:
        return ""

converted["Unnamed: 4"] = ["答案\n若為是非題:\n(1)答案為是\n(2)答案為否", "1"] + [map_answer(a) for a in df["正確答案"]]

# === 7. 題解 ===
converted["Unnamed: 5"] = ["解說\n(說明沒有解說)", "無"] + [x if isinstance(x, str) and x.strip() else "無" for x in df["題解"]]

# === 8. 難易度 ===
def map_difficulty(level):
    return {"難度一": 1, "難度二": 2, "難度三": 3}.get(level, 2)

converted["Unnamed: 6"] = ["難易度:\n(1)容易\n(2)適中\n(3)困難", "2"] + [map_difficulty(l) for l in df["難度"]]

# === 9. 選項展開（支援最多 20 個）===
max_choices = 20
choices_data = [[] for _ in range(max_choices)]

for row in df["選項"]:
    try:
        opts = ast.literal_eval(row) if isinstance(row, str) else []
        for i in range(max_choices):
            if i < len(opts):
                txt = wrap_asciimath(opts[i])
            else:
                txt = ""
            choices_data[i].append(txt)
    except Exception:
        for i in range(max_choices):
            choices_data[i].append("")

for i in range(max_choices):
    colname = f"Unnamed: {7 + i}"
    header = f"選項{i+1}" if i < 4 else ""
    converted[colname] = [header, ""] + choices_data[i]

# === 10. 分數欄 ===
converted["Unnamed: 27"] = ["分數 (僅支援自訂配分)", "0"] + [0] * len(df)

# === 11. 匯出為 CSV（iLearning 可用）===
converted.to_csv("converted_ilearning.csv", index=False, encoding="utf-8-sig")
print(" 題庫已成功轉換並匯出為 converted_ilearning.csv")
