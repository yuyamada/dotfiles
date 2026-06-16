if command -v ghtkn >/dev/null 2>&1; then
  gh() {
    local _device_flow=false
    [ -t 0 ] && _device_flow=true
    local _token
    if ! _token=$(GHTKN_ENABLE_DEVICE_FLOW="$_device_flow" ghtkn get nikkei-ghtkn-readonly 2>/dev/null); then
      echo "ghtkn: no cached token (run gh interactively to authenticate)" >&2
      return 1
    fi
    env GH_TOKEN="$_token" command gh "$@"
  }

  gh-write() {
    command gh "$@"
  }

  gh-login() {
    command gh auth login --scopes "repo,read:org,workflow,project" "$@"
  }
fi
