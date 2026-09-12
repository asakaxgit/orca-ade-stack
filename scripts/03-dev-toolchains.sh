#!/usr/bin/env bash
# nodenv + Node, rbenv + Ruby, direnv hooks; optional Claude/Cursor CLIs.
set -euo pipefail
NODE_VER="${NODE_VER:-22.18.0}"
RUBY_VER="${RUBY_VER:-3.3.4}"
INSTALL_AGENT_CLIS="${INSTALL_AGENT_CLIS:-1}"

install -d -o orca -g orca /home/orca/.local/bin

sudo -u orca -H env NODE_VER="$NODE_VER" RUBY_VER="$RUBY_VER" bash <<'EOSU'
set -euo pipefail
cd "$HOME"
export PATH="$HOME/.nodenv/bin:$HOME/.rbenv/bin:$HOME/.local/bin:$PATH"

if [[ ! -d .nodenv ]]; then
  git clone https://github.com/nodenv/nodenv.git .nodenv
  mkdir -p .nodenv/plugins
  git clone https://github.com/nodenv/node-build.git .nodenv/plugins/node-build
fi
eval "$(nodenv init -)"
nodenv install -s "$NODE_VER"
nodenv global "$NODE_VER"
corepack enable || true

if [[ ! -d .rbenv ]]; then
  git clone https://github.com/rbenv/rbenv.git .rbenv
  mkdir -p .rbenv/plugins
  git clone https://github.com/rbenv/ruby-build.git .rbenv/plugins/ruby-build
fi
eval "$(rbenv init -)"
rbenv install -s "$RUBY_VER"
rbenv global "$RUBY_VER"

if ! grep -q 'nodenv init' .bashrc 2>/dev/null; then
  {
    echo '# nodenv / rbenv / direnv (orca-ade-stack)'
    echo 'export PATH="$HOME/.nodenv/bin:$HOME/.rbenv/bin:$HOME/.local/bin:$PATH"'
    echo 'eval "$(nodenv init -)"'
    echo 'eval "$(rbenv init -)"'
    echo 'eval "$(direnv hook bash)"'
    echo
    cat .bashrc 2>/dev/null || true
  } > .bashrc.new && mv .bashrc.new .bashrc
fi

node -v
ruby -v
EOSU

if [[ "$INSTALL_AGENT_CLIS" == "1" ]]; then
  sudo -u orca -H bash -lc '
    set -e
    export PATH="$HOME/.nodenv/bin:$HOME/.local/bin:$PATH"
    eval "$(nodenv init -)"
    curl -fsSL https://claude.ai/install.sh | bash || true
    curl -fsSL https://cursor.com/install | bash || true
    command -v claude; command -v agent || command -v cursor-agent || true
  ' || true
fi

echo "Toolchains ready. Do interactive logins in Orca. Secrets → templates/local.envrc.example"
