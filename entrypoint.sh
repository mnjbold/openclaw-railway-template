#!/bin/bash
# W3J Patch v3 — zombie prevention (no set -e, manual error handling)
echo '[w3j] === entrypoint START ==='

# Zombie prevention: hard cap on user procs
ulimit -Su 2048 2>/dev/null && echo '[w3j] ulimit set' || echo '[w3j] ulimit skipped'
ulimit -n 65536 2>/dev/null || true

echo '[w3j] chowning /data...'
chown -R openclaw:openclaw /data && echo '[w3j] /data ok' || echo '[w3j] /data chown failed (ok if already correct)'
chmod 700 /data || true

echo '[w3j] checking linuxbrew...'
if [ ! -d /data/.linuxbrew ]; then
  echo '[w3j] copying linuxbrew to /data...'
  cp -a /home/linuxbrew/.linuxbrew /data/.linuxbrew && echo '[w3j] copy done' || echo '[w3j] copy failed'
fi

# Remove image-baked dir only if it's a real directory (not already a symlink)
if [ -d /home/linuxbrew/.linuxbrew ] && [ ! -L /home/linuxbrew/.linuxbrew ]; then
  echo '[w3j] removing image-baked linuxbrew dir...'
  find /home/linuxbrew/.linuxbrew -maxdepth 0 -type d -exec rm -rf {} + 2>/dev/null || true
fi
ln -sfn /data/.linuxbrew /home/linuxbrew/.linuxbrew 2>/dev/null || true
echo '[w3j] linuxbrew symlinked'

# Inline Google Chat appPrincipal patch
node -e "const fs=require('fs'),p='/data/.openclaw/openclaw.json',P='103907017982793847579';try{const c=JSON.parse(fs.readFileSync(p,'utf8'));if(c.channels&&c.channels.googlechat){if(c.channels.googlechat.appPrincipal===P){console.log('[gcp] ok');}else{c.channels.googlechat.appPrincipal=P;fs.writeFileSync(p,JSON.stringify(c,null,2),'utf8');console.log('[gcp] patched');}}else{console.log('[gcp] not configured yet');}}catch(e){console.log('[gcp] config not found, skipping');}" 2>/dev/null || true

echo '[w3j] launching openclaw via gosu...'
exec gosu openclaw node src/server.js
