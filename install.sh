#!/bin/bash

# Dotfiles セットアップスクリプト
# このスクリプトは dotfiles をホームディレクトリにシンボリックリンクします
#
# Usage:
#   ./install.sh                  # すべてセットアップ
#   ./install.sh claude langfuse  # 指定したターゲットのみ
#
# Targets:
#   configs     config/* を ~/.config/ にリンク
#   git         ~/.config/git/ 以下のファイルをリンク
#   zsh         ~/.zshrc をリンク
#   karabiner   ~/.config/karabiner/karabiner.json をリンク
#   serena      ~/.serena/serena_config.yml をリンク
#   claude      ~/.claude/ 以下をリンク
#   cursor      Cursor CLI の許可リストを同期
#   ccvm        ~/.local/bin/ccvm をリンク
#   langfuse    ~/.local/bin/langfuse-setup をリンク
#   anthropic   Anthropic API キーを Keychain に登録

set -euo pipefail

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

    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
}

# ---- Targets ----

setup_configs() {
    if [ ! -d "$DOTFILES_DIR/config" ]; then return; fi
    for dir in "$DOTFILES_DIR/config"/*; do
        [ -d "$dir" ] || continue
        dirname=$(basename "$dir")
        case "$dirname" in
            claude|agents|cursor|git|lima|langfuse) continue ;;
        esac
        link_file "$dir" "$HOME/.config/$dirname"
    done
}

setup_git() {
    mkdir -p "$HOME/.config/git"
    for git_file in "$DOTFILES_DIR/config/git"/*; do
        [ -f "$git_file" ] || continue
        link_file "$git_file" "$HOME/.config/git/$(basename "$git_file")"
    done
}

setup_zsh() {
    if [ -f "$DOTFILES_DIR/config/zsh/zshrc" ]; then
        link_file "$DOTFILES_DIR/config/zsh/zshrc" "$HOME/.zshrc"
    fi
}

setup_karabiner() {
    mkdir -p "$HOME/.config/karabiner"
    link_file "$DOTFILES_DIR/config/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
}

setup_serena() {
    mkdir -p "$HOME/.serena"
    link_file "$DOTFILES_DIR/config/serena/serena_config.yml" "$HOME/.serena/serena_config.yml"
}

setup_claude() {
    mkdir -p "$HOME/.claude"
    link_file "$DOTFILES_DIR/config/claude/settings.json" "$HOME/.claude/settings.json"
    link_file "$DOTFILES_DIR/config/claude/statusline.py" "$HOME/.claude/statusline.py"
    for skill_dir in "$DOTFILES_DIR/config/claude/skills"/*/; do
        [ -d "$skill_dir" ] || continue
        link_file "$skill_dir" "$HOME/.claude/skills/$(basename "$skill_dir")"
    done
    link_file "$DOTFILES_DIR/config/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
    link_file "$DOTFILES_DIR/config/claude/agents" "$HOME/.claude/agents"
    link_file "$DOTFILES_DIR/config/claude/rules" "$HOME/.claude/rules"
    mkdir -p "$HOME/.claude/hooks"
    for hook_file in "$DOTFILES_DIR/config/claude/hooks"/*; do
        [ -f "$hook_file" ] || continue
        link_file "$hook_file" "$HOME/.claude/hooks/$(basename "$hook_file")"
    done
    # Cursor のグローバルルールとしてコピー
    cp "$DOTFILES_DIR/config/claude/CLAUDE.md" "$HOME/.cursorrules"
}

setup_cursor() {
    if [ ! -f "$DOTFILES_DIR/config/cursor/permissions.json" ]; then return; fi
    mkdir -p "$HOME/.cursor"
    if [ -f "$HOME/.cursor/cli-config.json" ]; then
        if command -v jq &>/dev/null; then
            jq --slurpfile perm "$DOTFILES_DIR/config/cursor/permissions.json" '.permissions = $perm[0]' "$HOME/.cursor/cli-config.json" > "$HOME/.cursor/cli-config.json.tmp" && mv "$HOME/.cursor/cli-config.json.tmp" "$HOME/.cursor/cli-config.json"
            echo "✅ Cursor CLI の許可リストを更新しました"
        else
            echo "⚠️  jq がインストールされていないため、Cursor CLI 許可リストの同期をスキップします"
        fi
    else
        echo "{\"version\": 1, \"permissions\": $(cat "$DOTFILES_DIR/config/cursor/permissions.json")}" > "$HOME/.cursor/cli-config.json"
        echo "✅ Cursor CLI の設定を新規作成しました"
    fi
}

setup_ccvm() {
    mkdir -p "$HOME/.local/bin"
    link_file "$DOTFILES_DIR/bin/ccvm" "$HOME/.local/bin/ccvm"
}

setup_langfuse() {
    mkdir -p "$HOME/.local/bin"
    link_file "$DOTFILES_DIR/bin/langfuse-setup" "$HOME/.local/bin/langfuse-setup"
}

setup_anthropic() {
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
}

setup_all() {
    setup_configs
    setup_git
    setup_zsh
    setup_karabiner
    setup_serena
    setup_claude
    setup_cursor
    setup_ccvm
    setup_langfuse
    setup_anthropic
}

# ---- Dispatch ----

if [ $# -eq 0 ]; then
    setup_all
else
    for target in "$@"; do
        case "$target" in
            configs|config) setup_configs ;;
            git)            setup_git ;;
            zsh)            setup_zsh ;;
            karabiner)      setup_karabiner ;;
            serena)         setup_serena ;;
            claude)         setup_claude ;;
            cursor)         setup_cursor ;;
            ccvm)           setup_ccvm ;;
            langfuse)       setup_langfuse ;;
            anthropic)      setup_anthropic ;;
            *)
                echo "Unknown target: $target" >&2
                echo "Available: configs git zsh karabiner serena claude cursor ccvm langfuse anthropic" >&2
                exit 1
                ;;
        esac
    done
fi
