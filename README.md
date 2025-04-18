# sima_be

Backend for SIMA

## Quick Start

### 1. Clone the repo

```bash
git clone https://github.com/adrianparvino/sima_be.git
```

### 2. Install dependencies

```bash
opam switch create . 5.2.0 -y --deps-only

opam switch

opam install --deps-only .

npm ci
```

### 3. Run the app
```bash
npx wrangler dev
```

## Deploy
```bash
npx wrangler deploy
```
