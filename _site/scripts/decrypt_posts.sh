#!/usr/bin/env bash

set -uo pipefail

ENCRYPTED_DIR=".encrypted"
POSTS_DIR="_posts"

if [[ -z "${POST_DECRYPT_PASSPHRASE:-}" ]]; then
  echo "ERROR: POST_DECRYPT_PASSPHRASE environment variable not set."
  exit 1
fi

echo "Starting decryption process..."
echo "Encrypted directory: $ENCRYPTED_DIR"
echo "Output directory: $POSTS_DIR"

mkdir -p "$POSTS_DIR"

shopt -s nullglob
file_count=0
error_count=0
skip_count=0

for enc_file in "$ENCRYPTED_DIR"/*.enc; do
  base_name=$(basename "$enc_file" .enc)
  out_file="$POSTS_DIR/$base_name"

  # If output file exists and is newer than encrypted, warn and skip
  if [[ -e "$out_file" && "$out_file" -nt "$enc_file" ]]; then
    echo "  ⚠ Skipping: $out_file is newer than $enc_file (local changes present)"
    echo "    → You must re-encrypt it before decrypting again."
    ((skip_count++))
    continue
  fi

  echo "Decrypting: $enc_file -> $out_file"

  if openssl enc -aes-256-cbc -pbkdf2 -d \
      -in "$enc_file" \
      -out "$out_file" \
      -pass env:POST_DECRYPT_PASSPHRASE 2>/dev/null; then
    echo "  ✓ Successfully decrypted"
    ((file_count++))
  else
    echo "  ✗ Failed to decrypt: $enc_file"
    rm -f "$out_file"
    ((error_count++))
  fi
done

echo ""
echo "Decryption complete."
echo "  Files decrypted: $file_count"
echo "  Files failed:    $error_count"
echo "  Files skipped:   $skip_count"
