#!/bin/bash
set -e

# W3J Patch v3 (fixed) — tini already PID 1 via ENTRYPOINT, no double-tini
# ulimit caps prevent zombie spiral if tini misses orphans from Composio
ulimit -Su 2048 2>/dev/null || ulimit -u 2048 2>/dev/null || true
ulimit -n 65536 2>/dev/null || true

chown -R openclaw:openclaw /data
chmod 700 /data

if [ ! -d /data/.linuxbrew ]; then
  cp -a /home/linuxbrew/.linuxbrew /data/.linuxbrew
fi

ln -sfn /data/.linuxbrew /home/linuxbrew/.linuxbrew

# Inline Google Chat appPrincipal patch
node -e "
const fs=require('fs'),p='/data/.openclaw/openclaw.json',P='103907017982793847579';
try{const c=JSON.parse(fs.readFileSync(p,'utf8'));if(c.channels&&c.channels.googlechat){if(c.channels.googlechat.appPrincipal===P){console.log('[gcp] ok');}else{c.channels.googlechat.appPrincipal=P;fs.writeFileSync(p,JSON.stringify(c,null,2),'utf8');console.log('[gcp] patched');}}else{console.log('[gcp] not configured yet');}}catch(e){console.log('[gcp] config not found, skipping');}
" 2>/dev/null || true

# gosu drops to openclaw user. tini is already PID 1 (from Dockerfile ENTRYPOINT).
exec gosu openclaw node src/server.js
