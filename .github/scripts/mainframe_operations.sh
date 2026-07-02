#!/bin/sh
# mainframe_operations.sh
# Runs on the mainframe USS environment.

if [ -z "$ZOWE_USERNAME" ]; then
  echo "ERROR: ZOWE_USERNAME must be set."
  exit 1
fi

export JAVA_HOME=/usr/lpp/java/J8.0_64
export PATH=$PATH:$JAVA_HOME/bin

echo "Checking Java..."
java -version

COBOLCHECK_DIR="/z/$(echo $ZOWE_USERNAME | tr '[:upper:]' '[:lower:]')/cobolcheck"
cd "$COBOLCHECK_DIR"
echo "Changed to $(pwd)"
ls -al

# Make all scripts executable
chmod +x scripts/linux_gnucobol_run_tests
chmod +x scripts/zos_run_tests
echo "Made scripts executable"

run_cobolcheck() {
  program=$1
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
    echo "NOTE: ${program}.JCL not found - skipping JCL copy"
  fi
}

for program in NUMBERS ALPHA; do
  run_cobolcheck "$program"
done

echo "============================================"
echo "Mainframe operations completed."
