#!/usr/bin/env bash
# Get secret from Vaultwarden
# Usage: get-secret.sh "Item Name" [field]
# Fields: password (default), username, notes, uri

ITEM_NAME="$1"
FIELD="${2:-password}"

BW_SESSION=$(cat ~/.config/pai-private/.bw_session 2>/dev/null)

if [ -z "$BW_SESSION" ]; then
  echo "Error: No Vaultwarden session. Run: bw unlock" >&2
  exit 1
fi

case "$FIELD" in
  password)
    BW_SESSION="$BW_SESSION" bw get item "$ITEM_NAME" 2>/dev/null | jq -r '.login.password // empty'
    ;;
  username)
    BW_SESSION="$BW_SESSION" bw get item "$ITEM_NAME" 2>/dev/null | jq -r '.login.username // empty'
    ;;
  notes)
    BW_SESSION="$BW_SESSION" bw get item "$ITEM_NAME" 2>/dev/null | jq -r '.notes // empty'
    ;;
  uri)
    BW_SESSION="$BW_SESSION" bw get item "$ITEM_NAME" 2>/dev/null | jq -r '.login.uris[0].uri // empty'
    ;;
  *)
    echo "Unknown field: $FIELD" >&2
    exit 1
    ;;
esac
