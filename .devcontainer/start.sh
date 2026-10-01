#!/bin/bash
nohup bash -c 'while true; do touch /workspaces/test-client/.keepalive; sleep 240; done' >/dev/null 2>&1 &

docker rm -f chromium 2>/dev/null

if ! docker start firefox 2>/dev/null; then
  docker run -d \
    --name=firefox \
    -e PUID=1000 \
    -e PGID=1000 \
    -e TZ=Etc/UTC \
    -e SELKIES_USE_CSS_SCALING=true \
    -e SELKIES_USE_CPU=true \
    -e SELKIES_CRF=28 \
    -e SELKIES_VIDEO_FPS=60 \
    -e FIREFOX_CLI="https://discord.com/app https://www.instagram.com https://www.tiktok.com" \
    -p 3000:3000 \
    -p 3001:3001 \
    -v firefox_data:/config \
    --security-opt seccomp=unconfined \
    --shm-size="2gb" \
    --restart unless-stopped \
    lscr.io/linuxserver/firefox:latest
fi

sleep 2

# Fix permissions on /config
docker exec -u 0 firefox bash -c "chown -R 1000:1000 /config && chmod -R 777 /config" 2>/dev/null

# Disable stuck key repeats
docker exec firefox bash -c "export DISPLAY=:1; xset -r 2>/dev/null || (export DISPLAY=:0; xset -r)" 2>/dev/null

# Disable broken portal file picker (prevents image upload crashes)
docker exec -u 0 firefox bash -c '
  mkdir -p /usr/lib/firefox/defaults/pref /etc/firefox
  cat << "PREF" > /usr/lib/firefox/defaults/pref/filepicker-fix.js
pref("widget.use-xdg-desktop-portal.file-picker", 0);
pref("widget.use-xdg-desktop-portal.mime-handler", 0);
PREF
  cp /usr/lib/firefox/defaults/pref/filepicker-fix.js /etc/firefox/syspref.js 2>/dev/null
' 2>/dev/null

# Install color emojis if missing
docker exec -u 0 firefox bash -c '
  if ! fc-list : family | grep -qi "emoji"; then
    command -v apt-get >/dev/null 2>&1 && apt-get update && apt-get install -y fonts-noto-color-emoji && fc-cache -f
  fi
' 2>/dev/null
