# INSTALL CADDY
See: https://caddyserver.com/docs/install#debian-ubuntu-raspbian
sudo systemctl reload caddy

# INSTALL CODER
curl -L https://coder.com/install.sh | sh

# RUN CODER
## NOTES
* Device Flow login breaks read organization permissions (never read)
* OAuth read:org permission can be granted by owner during first login

```
export CODER_ACCESS_URL=https://coder.FIXME.com

export CODER_OAUTH2_GITHUB_CLIENT_ID=FIXME
export CODER_OAUTH2_GITHUB_CLIENT_SECRET=FIXME

export CODER_OAUTH2_GITHUB_ALLOW_SIGNUPS=true
export CODER_OAUTH2_GITHUB_ALLOWED_ORGS="FIXME"
export CODER_OAUTH2_GITHUB_ALLOW_EVERYONE=false
export CODER_OAUTH2_GITHUB_DEVICE_FLOW=false
export CODER_OAUTH2_GITHUB_DEFAULT_PROVIDER_ENABLE=false

coder server --address 127.0.0.1:3000
```

# UNINSTALL CODER
sudo rm -f /usr/bin/coder
sudo rm -f /etc/coder.d/coder.env
rm -rf ~/.config/coderv2
rm -rf ~/.cache/coder

# TEST MEMBERSHIP
curl \
  -H "Authorization: Bearer FIXME" \
  -H "Accept: application/vnd.github+json" \
  'https://api.github.com/user/memberships/orgs?per_page=100&state=active'

