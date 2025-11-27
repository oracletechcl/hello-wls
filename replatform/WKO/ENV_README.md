# Environment Configuration

This directory uses `.env` files to store sensitive credentials that are automatically loaded by the scripts.

## Setup

1. **Copy the example file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` with your credentials:**
   - `OCIR_USERNAME`: Your OCI username in format `<tenancy-namespace>/<identity-provider>/<username>`
   - `OCIR_AUTH_TOKEN`: Your OCI auth token (generate in OCI Console)

3. **The scripts will automatically load these credentials** when executed.

## Security

- The `.env` file is in `.gitignore` and will not be committed to the repository
- Never commit credentials to version control
- Store your `.env` file securely

## How to Generate OCI Auth Token

1. Log into OCI Console
2. Click your profile icon → User Settings
3. Under Resources, click "Auth Tokens"
4. Click "Generate Token"
5. Copy the token immediately (you won't see it again!)
6. Paste it into your `.env` file

## Current Configuration

The `.env` file in this directory contains credentials for:
- **OCIR Registry**: scl.ocir.io
- **Namespace**: idi1o0a010nx
- **Repository**: dalquint-docker-images
