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
            if [ "$dirname" = "claude" ] || [ "$dirname" = "agents" ] || [ "$dirname" = "cursor" ]; then
                continue
            fi
            link_file "$dir" "$HOME/.config/$dirname"
        fi
    done
fi

# .zshrc をリンク
if [ -f "$DOTFILES_DIR/config/zsh/zshrc" ]; then
    link_file "$DOTFILES_DIR/config/zsh/zshrc" "$HOME/.zshrc"
fi

# karabiner.json をリンク（ディレクトリごとではなくファイル単体）
mkdir -p "$HOME/.config/karabiner"
link_file "$DOTFILES_DIR/config/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"

# ~/.serena/ をリンク
mkdir -p "$HOME/.serena"
link_file "$DOTFILES_DIR/config/serena/serena_config.yml" "$HOME/.serena/serena_config.yml"

# ~/.claude/ をリンク
mkdir -p "$HOME/.claude"
link_file "$DOTFILES_DIR/config/claude/settings.json" "$HOME/.claude/settings.json"
for skill_dir in "$DOTFILES_DIR/config/claude/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    target_dir="$HOME/.claude/skills/$skill_name"
    mkdir -p "$target_dir"
    # リンク対象のファイルとサブディレクトリを再帰的に処理
    find "$skill_dir" -mindepth 1 -maxdepth 1 | while read -r item; do
        item_name=$(basename "$item")
        if [ -d "$item" ]; then
            mkdir -p "$target_dir/$item_name"
            for f in "$item"/*; do
                [ -f "$f" ] || continue
                link_file "$f" "$target_dir/$item_name/$(basename "$f")"
            done
        elif [ -f "$item" ]; then
            link_file "$item" "$target_dir/$item_name"
        fi
    done
done
link_file "$DOTFILES_DIR/config/agents/AGENTS.md" "$HOME/.claude/CLAUDE.md"

# Cursorのグローバルルールとしてコピー
cp "$DOTFILES_DIR/config/agents/AGENTS.md" "$HOME/.cursorrules"

# Cursor CLI の許可リストを同期
if [ -f "$DOTFILES_DIR/config/cursor/permissions.json" ]; then
    mkdir -p "$HOME/.cursor"
    if [ -f "$HOME/.cursor/cli-config.json" ]; then
        if command -v jq &> /dev/null; then
            jq --slurpfile perm "$DOTFILES_DIR/config/cursor/permissions.json" '.permissions = $perm[0]' "$HOME/.cursor/cli-config.json" > "$HOME/.cursor/cli-config.json.tmp" && mv "$HOME/.cursor/cli-config.json.tmp" "$HOME/.cursor/cli-config.json"
            echo "✅ Cursor CLI の許可リストを更新しました"
        else
            echo "⚠️  jq がインストールされていないため、Cursor CLI 許可リストの同期をスキップします"
        fi
    else
        # 新規作成（jqがなくても単純な文字列結合で作成）
        echo "{\"version\": 1, \"permissions\": $(cat "$DOTFILES_DIR/config/cursor/permissions.json")}" > "$HOME/.cursor/cli-config.json"
        echo "✅ Cursor CLI の設定を新規作成しました"
    fi
fi

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
