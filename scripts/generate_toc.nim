## README目次自動生成スクリプト
##
## このスクリプトはREADME.mdファイルを解析し、
## 見出しから自動的に目次を生成します。

import os, re, strutils, sequtils

type
  TocEntry = object
    level: int      # 見出しレベル（# = 1, ## = 2, etc.）
    title: string   # 見出しテキスト
    anchor: string  # マークダウンアンカー

# 見出しを見つけるための正規表現
let headingRegex = re"^(#+)\s+(.+?)(?:\s*{#([^}]+)})?$"

# マークダウンアンカーを生成する
proc generateAnchor(title: string): string =
  result = title.toLowerAscii()
    .replace(re"[^\w\- ]", "")   # 英数字、ハイフン、空白以外を削除
    .replace(re"\s+", "-")       # 空白をハイフンに置換
    .strip(chars={'-'})          # 先頭と末尾のハイフンを削除

# ファイルからTOCエントリを抽出
proc extractHeadings(filename: string): seq[TocEntry] =
  result = @[]
  
  let content = readFile(filename)
  let lines = content.splitLines()
  
  for line in lines:
    var matches: array[4, string]
    if line.match(headingRegex, matches):
      let level = matches[1].len
      let title = matches[2]
      # マークダウンに明示的なアンカーがある場合はそれを使用、なければ生成
      let anchor = if matches[3].len > 0: matches[3] else: generateAnchor(title)
      
      result.add(TocEntry(level: level, title: title, anchor: anchor))

# TOCエントリからマークダウン目次を生成
proc generateToc(entries: seq[TocEntry]): string =
  for entry in entries:
    # インデントは見出しレベルに応じて増やす
    let indent = "    ".repeat(entry.level - 1)
    result.add(indent & "* [" & entry.title & "](#" & entry.anchor & ")\n")

# TOCをファイルに書き込む
proc updateToc(filename: string) =
  let content = readFile(filename)
  
  # 既存のTOCを検索
  let tocStartMarker = "<!-- AutoContentStart -->"
  let tocEndMarker = "<!-- AutoContentEnd -->"
  
  let tocStartPos = content.find(tocStartMarker)
  let tocEndPos = content.find(tocEndMarker)
  
  if tocStartPos == -1 or tocEndPos == -1:
    echo "TOCマーカーが見つかりません。マーカーがREADME.mdに含まれていることを確認してください。"
    return
  
  # 見出しを抽出（見出しレベル1は目次には含めない）
  var headings = extractHeadings(filename)
  headings = headings.filterIt(it.level > 1) # 見出しレベル1は除外
  
  # 新しいTOCを生成
  let newToc = tocStartMarker & "\n" & generateToc(headings) & tocEndMarker
  
  # READMEの既存TOCを置換
  let oldTocSection = content[tocStartPos..tocEndPos + tocEndMarker.len - 1]
  let updatedContent = content.replace(oldTocSection, newToc)
  
  # 更新されたコンテンツを書き込み
  writeFile(filename, updatedContent)
  echo "TOCを更新しました。"

# メイン処理
when isMainModule:
  if paramCount() < 1:
    echo "使用法: nim r generate_toc.nim <README.mdへのパス>"
    quit(1)
  
  let filename = paramStr(1)
  if not fileExists(filename):
    echo "ファイルが見つかりません: " & filename
    quit(1)
  
  updateToc(filename)