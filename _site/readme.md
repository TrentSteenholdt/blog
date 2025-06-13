# Cortana Design Blog

All posts submitted and approved in this repository show up on our blog at <https://blog.cortanadesign.com.au/>

## 🔐 Encrypted Jekyll Posts

This repo uses OpenSSL to keep selected `_posts` content encrypted in `.encrypted/` so sensitive Markdown isn’t committed to version control in plaintext.

### 📁 Folder Structure

- `.encrypted/` — Contains encrypted `.md.enc` files.
- `_posts/` — Decrypted output, ready for `jekyll build`.
- `scripts/decrypt_posts.sh` — Script to decrypt encrypted posts.
- `scripts/encrypt_posts.sh` — (Optional) Script to re-encrypt edited files.

> _posts is gitignored.

---

### 🔓 Decrypting Posts (Locally or in CI/CD)

You’ll need to provide the encryption passphrase via an environment variable.

#### 🔧 Step-by-step

```bash
# 1. Export the passphrase (or use in CI/CD secret)
export POST_DECRYPT_PASSPHRASE='your-secure-passphrase'

# 2. Run the decryption script
bash scripts/decrypt_posts.sh
