if command -v ghtkn >/dev/null 2>&1; then
  gh() {
    env GH_TOKEN=$(ghtkn get nikkei-ghtkn-readonly) command gh "$@"
  }

  gh-write() {
    command gh "$@"
  }
fi
