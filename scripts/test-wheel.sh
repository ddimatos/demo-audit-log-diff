#!/bin/sh

SETUP_SOURCE_FILE="setup.sh"
ENV_SOURCE_FILE="../.env"
export SEP_LINE_NL="\n-------------------------------------------------------------------------------\n"

# ---------------------------------------------------------------------
# Sourcing the setup file to setup and teardown the demo script
# ---------------------------------------------------------------------

setup() {
if [ -f "$SETUP_SOURCE_FILE" ]; then
  echo "${SEP_LINE_NL}[INFO] Sourcing $SETUP_SOURCE_FILE${SEP_LINE_NL}"
  source "$SETUP_SOURCE_FILE"
else
  echo ""
  echo "${SEP_LINE_NL}[WARN] The setup file $SETUP_SOURCE_FILE must exist and be run."
  exit
fi
}

source_env() {
if [ -f "$ENV_SOURCE_FILE" ]; then
  echo "${SEP_LINE_NL}[INFO] Sourcing $ENV_SOURCE_FILE${SEP_LINE_NL}"
  source "$ENV_SOURCE_FILE"
else
  echo "${SEP_LINE_NL}[WARN] There is no environment file $ENV_SOURCE_FILE,
  please be sure to configure script variables'USER', 'HOST' and \
  'MY_ANSIBLE_LIBRARY' in this script${SEP_LINE_NL}"
fi
}

# ---------------------------------------------------------------------
# Export environment variables
# ---------------------------------------------------------------------
source_env
export USER=${MY_USER:="ibmuser"}
export HOST=${MY_HOST:="hostname"}
export DCONCAT="wheel-import-test.py"

# ---------------------------------------------------------------------
# Copy local file content to UNIX System Services files
# ---------------------------------------------------------------------
echo "Copying python source file dconcat.py to USS"
scp -O ../python/${DCONCAT} ${USER}@${HOST}:/tmp/${DCONCAT}

# ---------------------------------------------------------------------
# Running dconcat
# ---------------------------------------------------------------------
#setup
echo
echo "${SEP_LINE_NL}Perform 'dconcat' with wheel demo using datatsets:${SEP_LINE_NL}"


SSH_OUTPUT=$(ssh -q ${USER}@${HOST} ". ./.profile; \
cd /tmp; \
chtag -tc IBM-1047 /tmp/${DCONCAT}; \
chmod 755 /tmp/${DCONCAT}; \
python3 /tmp/${DCONCAT}; \
rm -rf /tmp/*")
#echo "${SEP_LINE_NL}[INFO] Results${SEP_LINE_NL}"
echo "${SSH_OUTPUT}"