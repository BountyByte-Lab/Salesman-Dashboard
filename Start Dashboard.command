#!/bin/bash
cd "$(dirname "$0")"
PORT=8743

if ! lsof -ti tcp:$PORT >/dev/null 2>&1; then
  python3 -m http.server "$PORT" --bind 127.0.0.1 >/tmp/salesman_dashboard_server.log 2>&1 &
  disown
  sleep 1
fi

open "http://127.0.0.1:$PORT/salesman_dashboard.html"
