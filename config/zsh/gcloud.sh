source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"

# kubectl の補完は /opt/homebrew/share/zsh/site-functions/_kubectl にキャッシュ済み。
# kubectl をアップグレードしたら `kubectl completion zsh > /opt/homebrew/share/zsh/site-functions/_kubectl` で再生成する。
