#!/usr/bin/env bash
export PATH="/home/user/.nvm/versions/node/v22.23.2/bin:/usr/local/bin:/usr/bin:/bin"
export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token 2>/dev/null)"
exec /home/user/.nvm/versions/node/v22.23.2/bin/npx -y @modelcontextprotocol/server-github
