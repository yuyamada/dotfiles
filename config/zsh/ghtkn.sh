if command -v ghtkn >/dev/null 2>&1; then
  gh() {
    ghtkn exec -e GH_TOKEN:readonly -- gh "$@"
  }

  gh-write() {
    ghtkn exec -e GH_TOKEN:readwrite -- gh "$@"
  }

  gh-login() {
    command gh auth login --scopes "repo,read:org,workflow,project" "$@"
  }

  gh-personal() {
    command gh "$@"
  }
fi
