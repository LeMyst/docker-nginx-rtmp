#!/usr/bin/env sh
set -eu

# Build list like "$VAR1 $VAR2 ..." for envsubst
VARS=$(env | sed -e 's/=.*//' -e 's/^/$/g' | xargs || true)

if [ -n "$VARS" ]; then
  envsubst "$VARS" < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
else
  cp /etc/nginx/nginx.conf.template /etc/nginx/nginx.conf
fi

# If container given args (including CMD), run them; otherwise run nginx in foreground
if [ "$#" -gt 0 ]; then
  exec "$@"
else
  exec nginx -g 'daemon off;'
fi
