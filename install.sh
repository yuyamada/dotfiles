#!/bin/bash

# Dotfiles セットアップスクリプト
# このスクリプトは dotfiles をホームディレクトリにシンボリックリンクします

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

# シンボリックリンクを作成する関数
link_file() {
    local src="$1"
    local dst="$2"
    
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
            return
        fi
        echo "⚠️  既存のファイル/ディレクトリが見つかりました: $dst"
        read -p "上書きしますか? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
        rm -rf "$dst"
    fi
    
    # ディレクトリが存在しない場合は作成
    mkdir -p "$(dirname "$dst")"
    
    ln -s "$src" "$dst"
}

# config ディレクトリ内の各ツールを .config にリンク
if [ -d "$DOTFILES_DIR/config" ]; then
    for dir in "$DOTFILES_DIR/config"/*; do
        if [ -d "$dir" ]; then
            dirname=$(basename "$dir")
            link_file "$dir" "$HOME/.config/$dirname"
        fi
    done
fi
