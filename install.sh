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

# .zshrc をリンク
if [ -f "$DOTFILES_DIR/config/zsh/zshrc" ]; then
    link_file "$DOTFILES_DIR/config/zsh/zshrc" "$HOME/.zshrc"
fi

# ~/.claude/settings.json をリンク
mkdir -p "$HOME/.claude"
link_file "$DOTFILES_DIR/config/claude/settings.json" "$HOME/.claude/settings.json"

# Anthropic API キーの設定
read -p "この PC で Anthropic API キーを使用しますか? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    touch "$HOME/.claude_anthropic_enabled"
    if ! security find-generic-password -s "anthropic-api-key" -w &>/dev/null; then
        read -s -p "Anthropic API キーを入力してください: " api_key
        echo
        security add-generic-password -s "anthropic-api-key" -w "$api_key"
        echo "✅ API キーを Keychain に登録しました"
    fi
fi
