#!/bin/bash
nohup bash -c 'while true; do touch /workspaces/test-client/.keepalive; sleep 240; done' >/dev/null 2>&1 &

# Start or run Firefox container
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

# Disable stuck key repeats
docker exec firefox bash -c "export DISPLAY=:1; xset -r 2>/dev/null || (export DISPLAY=:0; xset -r)" 2>/dev/null

# Patch Selkies web interface for auto-settings
docker exec -u 0 firefox bash -c '
  for html in $(find /usr/share/selkies -name "index.html" 2>/dev/null); do
    if ! grep -q "auto-speed-patch" "$html"; then
      sed -i "s|</head>|<script id=\"auto-speed-patch\">window.addEventListener(\"load\",()=>{setTimeout(()=>{try{localStorage.setItem(\"use_css_cursors\",\"true\");localStorage.setItem(\"hidpi\",\"false\");localStorage.setItem(\"use_paint_overs\",\"false\");localStorage.setItem(\"anti_aliasing\",\"false\");localStorage.setItem(\"crf\",\"28\");}catch(e){}},500);});</script></head>|g" "$html"
    fi
  done
' 2>/dev/null

# Install color emojis if missing
docker exec -u 0 firefox bash -c '
  if ! fc-list : family | grep -qi "emoji"; then
    command -v apt-get >/dev/null 2>&1 && apt-get update && apt-get install -y fonts-noto-color-emoji && fc-cache -f
  fi
' 2>/dev/null

echo "Firefox is running."
