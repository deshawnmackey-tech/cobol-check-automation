#!/bin/bash
# zowe_operations.sh
# Sets up mainframe environment and uploads COBOL Check files via Zowe CLI.

set -e  # Exit immediately on any error

# Validate required environment variables
if [[ -z "$ZOWE_USERNAME" || -z "$ZOWE_PASSWORD" || -z "$ZOWE_HOST" || -z "$ZOWE_PORT" ]]; then
  echo "ERROR: ZOWE_USERNAME, ZOWE_PASSWORD, ZOWE_HOST, and ZOWE_PORT must be set."
  exit 1
fi

echo "Configuring Zowe connection to $ZOWE_HOST:$ZOWE_PORT..."

# Write zowe.config.json directly — avoids keychain/libsecret entirely
cat > zowe.config.json << ZOWE_CONFIG
{
  "\$schema": "./node_modules/@zowe/cli/schemas/zowe-v2-config.json",
  "profiles": {
    "base": {
      "type": "base",
      "properties": {
        "host": "$ZOWE_HOST",
        "port": $ZOWE_PORT,
        "user": "$ZOWE_USERNAME",
        "password": "$ZOWE_PASSWORD",
        "rejectUnauthorized": ${ZOWE_REJECT_UNAUTHORIZED:-false}
      }
    }
  },
  "defaults": {
    "base": "base"
  },
  "autoStore": false
}
ZOWE_CONFIG

echo "Zowe config written."

# Convert username to lowercase for USS path
LOWERCASE_USERNAME=$(echo "$ZOWE_USERNAME" | tr '[:upper:]' '[:lower:]')
REMOTE_DIR="/z/$LOWERCASE_USERNAME/cobolcheck"

# Check if directory exists, create if it doesn't
if ! zowe zos-files list uss-files "$REMOTE_DIR" &>/dev/null; then
  echo "Directory does not exist. Creating: $REMOTE_DIR"
  zowe zos-files create uss-directory "$REMOTE_DIR"
else
  echo "Directory already exists: $REMOTE_DIR"
fi

# Upload COBOL source files
echo "Uploading COBOL source files..."
zowe zos-files upload dir-to-uss "./src" "$REMOTE_DIR/src" --recursive

# Upload COBOL Check JAR (binary)
echo "Uploading CobolCheck JAR..."
zowe zos-files upload file-to-uss "./CobolCheck.jar" "$REMOTE_DIR/CobolCheck.jar" --binary

# Upload run scripts
echo "Uploading run scripts..."
zowe zos-files upload dir-to-uss "./scripts" "$REMOTE_DIR/scripts" --recursive

# Upload config
echo "Uploading config..."
zowe zos-files upload file-to-uss "./config.properties" "$REMOTE_DIR/config.properties"

# Verify upload
echo "Verifying upload:"
zowe zos-files list uss-files "$REMOTE_DIR"

echo "Done."
