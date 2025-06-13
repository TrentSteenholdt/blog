#!/usr/bin/env bash

set -euo pipefail

ENCRYPTED_DIR=".encrypted"
POSTS_DIR="_posts"

if [[ -z "${POST_DECRYPT_PASSPHRASE:-}" ]]; then
  echo "ERROR: POST_DECRYPT_PASSPHRASE environment variable not set."
  exit 1
fi

mkdir -p "$ENCRYPTED_DIR"

for post_file in "$POSTS_DIR"/*.md; do
  [[ -e "$post_file" ]] || continue

  base_name=$(basename "$post_file")
  enc_file="$ENCRYPTED_DIR/$base_name.enc"

  echo "Encrypting: $post_file -> $enc_file"

  openssl enc -aes-256-cbc -pbkdf2 -salt \
    -in "$post_file" \
    -out "$enc_file" \
    -pass env:POST_DECRYPT_PASSPHRASE
done

echo "Encryption complete."
