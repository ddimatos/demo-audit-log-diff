#!/bin/sh

ENV_SOURCE_FILE="../.env"
export SEP_LINE="-------------------------------------------------------------------------------"

# ---------------------------------------------------------------------
# Place your secrets in a '.env' file in project root for auto sourcing
# ---------------------------------------------------------------------

if [ -f "$ENV_SOURCE_FILE" ]; then
  echo "[INFO] Sourcing $ENV_SOURCE_FILE."
  source "$ENV_SOURCE_FILE"
else
  echo "[WARN] There is no environment file $ENV_SOURCE_FILE, please be\
  sure to configure script variables'USER' and 'HOST' in this script."
fi

# ---------------------------------------------------------------------
# Export environment variables
# ---------------------------------------------------------------------
export USER=${MY_USER:="ibmuser"}
export HOST=${MY_HOST:="hostname"}
export SRC_DATA_SET_NAME="audit.current.seq"
export COMPARE_DATA_SET_NAME="audit.previous.seq"
export EMPTY_DATA_SET_NAME="audit.all.seq"
export TMP_FILE=/tmp/tmp.txt

# ---------------------------------------------------------------------
# Copy local file content to UNIX System Services files
# ---------------------------------------------------------------------
echo "[INFO] Copying data to z/OS."
tail -n +3 ../files/${SRC_DATA_SET_NAME} > ${TMP_FILE}
scp -O ${TMP_FILE} ${USER}@${HOST}:/tmp/${SRC_DATA_SET_NAME}
rm -rf ${TMP_FILE}
tail -n +3 ../files/${COMPARE_DATA_SET_NAME} > ${TMP_FILE}
scp -O ${TMP_FILE} ${USER}@${HOST}:/tmp/${COMPARE_DATA_SET_NAME}
rm -rf ${TMP_FILE}

# ---------------------------------------------------------------------
# Copy a templated ssh '.profile' to be used by the script
# ---------------------------------------------------------------------
echo "[INFO] Copying profile to UNIX System Services."
scp -O ../files/profile ${USER}@${HOST}:/.profile

# ---------------------------------------------------------------------
# Create and populated z/OS datasets
# ---------------------------------------------------------------------
echo "[INFO] Create and populate z/OS datasets."
SSH_OUTPUT=$(ssh -q ${USER}@${HOST} ". ./.profile; \
# Remove any pre-existing datasets
drm -f ${SRC_DATA_SET_NAME} > /dev/null 2>&1; \
if [ \$? -eq 0 ]; then echo "[INFO] drm -f ${SRC_DATA_SET_NAME} executed successfully."; else echo "[ERROR] drm -f ${SRC_DATA_SET_NAME} failed."; fi; \

# Remove any pre-existing datasets
drm -f ${COMPARE_DATA_SET_NAME}> /dev/null 2>&1; \
if [ \$? -eq 0 ]; then echo "[INFO] drm -f ${COMPARE_DATA_SET_NAME} executed successfully."; else echo "[ERROR] drm -f ${COMPARE_DATA_SET_NAME} failed."; fi; \

# Remove any pre-existing datasets
drm -f ${EMPTY_DATA_SET_NAME}> /dev/null 2>&1; \
if [ \$? -eq 0 ]; then echo "[INFO] drm -f ${EMPTY_DATA_SET_NAME} executed successfully."; else echo "[ERROR] drm -f ${EMPTY_DATA_SET_NAME} failed."; fi; \

# Create empty sequential dataset
dtouch -tseq ${SRC_DATA_SET_NAME}; \
if [ \$? -eq 0 ]; then echo "[INFO] dtouch -tseq ${SRC_DATA_SET_NAME} executed successfully."; else echo "[ERROR] dtouch -tseq ${SRC_DATA_SET_NAME} failed."; fi; \

# Create empty sequential dataset
dtouch -tseq ${COMPARE_DATA_SET_NAME}; \
if [ \$? -eq 0 ]; then echo "[INFO] dtouch -tseq ${COMPARE_DATA_SET_NAME} executed successfully."; else echo "[ERROR] dtouch -tseq ${COMPARE_DATA_SET_NAME} failed."; fi; \

# Create empty sequential dataset
dtouch -tseq ${EMPTY_DATA_SET_NAME}; \
if [ \$? -eq 0 ]; then echo "[INFO] dtouch -tseq ${EMPTY_DATA_SET_NAME} executed successfully."; else echo "[ERROR] dtouch -tseq ${EMPTY_DATA_SET_NAME} failed."; fi; \

# Copy text source into dataset
dcp /tmp/${SRC_DATA_SET_NAME} ${SRC_DATA_SET_NAME}; \
if [ \$? -eq 0 ]; then echo "[INFO] dcp /tmp/${SRC_DATA_SET_NAME} ${SRC_DATA_SET_NAME} executed successfully."; else echo "[ERROR] dcp /tmp/${SRC_DATA_SET_NAME} ${SRC_DATA_SET_NAME} failed."; fi; \

# Copy text source into dataset
dcp /tmp/${COMPARE_DATA_SET_NAME} ${COMPARE_DATA_SET_NAME}; \
if [ \$? -eq 0 ]; then echo "[INFO] dcp /tmp/${COMPARE_DATA_SET_NAME} ${COMPARE_DATA_SET_NAME} executed successfully."; else echo "[ERROR] dcp /tmp/${COMPARE_DATA_SET_NAME} ${COMPARE_DATA_SET_NAME} failed."; fi; \

# Clean up text files
rm -rf /tmp/${SRC_DATA_SET_NAME} /tmp/${COMPARE_DATA_SET_NAME};")

echo "[INFO] Results ${SSH_OUTPUT}"
