#!/bin/bash
# パスを省略形に変換（中間ディレクトリは頭文字のみ）
path="${1:-$PWD}"
short="${path/#$HOME/~}"
dir=$(dirname "$short")
base=$(basename "$short")
abbr=$(echo "$dir" | sed 's|/\([^/]\)[^/]*|/\1|g')
echo "${abbr}/${base}"
