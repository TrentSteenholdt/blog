# Cortana Design Blog

All posts submitted and approved in this repository show up on our blog at <https://blog.cortanadesign.com.au/>

## Encrypted Jekyll Posts

This repository uses OpenSSL encryption to protect sensitive content in selected posts. Encrypted files are stored separately from the main content directory to prevent plaintext sensitive information from being committed to version control.

### Directory Structure

The encryption system organizes files across several key directories:

- `.encrypted/` — Contains encrypted `.md.enc` files that store the protected content
- `_posts/` — Contains decrypted Markdown files ready for Jekyll to process during build
- `scripts/decrypt_posts.sh` — Automation script for decrypting encrypted posts
- `scripts/encrypt_posts.sh` — Optional utility script for re-encrypting modified files

**Important:** All `.md` files in the `_posts/` directory are excluded from version control via `.gitignore` to prevent accidental commits of decrypted sensitive content.

### Decrypting Posts for Local Development or CI/CD

To work with encrypted posts, you must provide the encryption passphrase through an environment variable. This approach ensures the passphrase can be securely managed in both local development environments and automated deployment pipelines.

#### Decryption Process

Follow these steps to decrypt posts for local development:

```bash
# Set the decryption passphrase as an environment variable
# In production environments, store this as a secure secret
export POST_DECRYPT_PASSPHRASE='your-secure-passphrase'

# Execute the decryption script to process all encrypted files
bash scripts/decrypt_posts.sh
```

The decryption script will process all `.md.enc` files in the `.encrypted/` directory and output the corresponding `.md` files to the `_posts/` directory, making them available for Jekyll to build.
