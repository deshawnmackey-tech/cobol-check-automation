#!/bin/bash
# mainframe_operations.sh
# Runs on the mainframe USS environment.
# Sets up environment, makes files executable, and runs COBOL Check for each program.

set -e

# Validate required environment variable
if [[ -z "$ZOWE_USERNAME" ]]; then
  echo "ERROR: ZOWE_USERNAME must be set."
  exit 1
fi

# Set up environment
export JAVA_HOME=/usr/lpp/java/J8.0_64
export PATH=$PATH:$JAVA_HOME/bin
export PATH=$PATH:/usr/lpp/zowe/cli/node/bin

# Check Java availability
echo "Checking Java..."
java -version

# Change to the cobolcheck directory
COBOLCHECK_DIR="/z/$(echo $ZOWE_USERNAME | tr '[:upper:]' '[:lower:]')/cobolcheck"
cd "$COBOLCHECK_DIR"
echo "Changed to $(pwd)"
ls -al

# Make scripts executable
chmod +x scripts/linux_gnucobol_run_tests
echo "Made linux_gnucobol_run_tests executable"

# Function to run COBOL Check for a single program
run_cobolcheck() {
  local program=$1
  echo "--------------------------------------------"
  echo "Running COBOL Check for $program..."

  java -jar CobolCheck.jar -p "$program" || echo "COBOL Check encountered issues for $program"

  if [ -f "testruns/CC##99.CBL" ]; then
    if cp "testruns/CC##99.CBL" "//'${ZOWE_USERNAME}.CBL($program)'"; then
      echo "Copied test program to ${ZOWE_USERNAME}.CBL($program)"
    else
      echo "WARNING: Failed to copy test program to ${ZOWE_USERNAME}.CBL($program)"
    fi
  else
    echo "WARNING: testruns/CC##99.CBL not found for $program"
  fi

  if [ -f "${program}.JCL" ]; then
    if cp "${program}.JCL" "//'${ZOWE_USERNAME}.JCL($program)'"; then
      echo "Copied ${program}.JCL to ${ZOWE_USERNAME}.JCL($program)"
    else
      echo "WARNING: Failed to copy ${program}.JCL to ${ZOWE_USERNAME}.JCL($program)"
    fi
  else
    echo "NOTE: ${program}.JCL not found — skipping JCL copy"
  fi
}

# Run COBOL Check for each program
for program in NUMBERS ALPHA EMPPAY DEPTPAY; do
  run_cobolcheck "$program"
done

echo "============================================"
echo "Mainframe operations completed."
