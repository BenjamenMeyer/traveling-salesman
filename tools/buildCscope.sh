#!/bin/bash

# ouptut directory for the scope database(s)
CSCOPE_OUTPUT_DIR=".cscope"

# Get the number of items in a file
function getCount()
  {
  echo `wc -l ${1} | tr -s ' ' ';' | cut -f 1 -d ';'`
  }

# Retrieve the last name in a given path (directory or file)
function getLastDirectory()
  {
  IFS='/'
  local RETURN_DIRECTORY=''
  for DIR in ${1}
  do
    RETURN_DIRECTORY="${DIR}"
  done
  echo "${RETURN_DIRECTORY}"
  }

# Retrieve the name of this program without any leading parent directories
PROGRAM_NAME=`getLastDirectory ${0}`

# Determine our temporary directory for file storage
MY_TMP_DIR=".${PROGRAM_NAME}-tmp"
if [ "${PROGRAM_NAME:0:2}" == "./" ]; then
  MY_TMP_DIR=".${PROGRAM_NAME:2}-tmp"
elif [ "${PROGRAM_NAME:0:3}" == "../" ]; then
  MY_TMP_DIR=".${PROGRAM_NAME:3}-tmp"
fi

# If the temporary directory doesn't exist, create it
if [ -d ${MY_TMP_DIR} ]; then
  rm -Rf ${MY_TMP_DIR}
fi
mkdir ${MY_TMP_DIR}

# Where are we?
PWD=`pwd`

# Normal C++ file extensions
FILES_CPP=`tempfile --directory=${MY_TMP_DIR}`;   find -type f -name "*.cpp" -printf "${PWD}/%h/%f\n" > "${FILES_CPP}"
FILES_HPP=`tempfile --directory=${MY_TMP_DIR}`;   find -type f -name "*.hpp" -printf "${PWD}/%h/%f\n" > "${FILES_HPP}"
FILES_CXX=`tempfile --directory=${MY_TMP_DIR}`;   find -type f -name "*.cxx" -printf "${PWD}/%h/%f\n" > "${FILES_CXX}"
FILES_HXX=`tempfile --directory=${MY_TMP_DIR}`;   find -type f -name "*.hxx" -printf "${PWD}/%h/%f\n" > "${FILES_HXX}"
# C file extensions
FILES_C=`tempfile --directory=${MY_TMP_DIR}`;     find -type f -name "*.c" -printf "${PWD}/%h/%f\n" > "${FILES_C}"
FILES_H=`tempfile --directory=${MY_TMP_DIR}`;     find -type f -name "*.h" -printf "${PWD}/%h/%f\n" > "${FILES_H}"

# Combine them all together
FILES=`tempfile`
cat ${FILES_CPP} > ${FILES}
cat ${FILES_HPP} >> ${FILES}
cat ${FILES_CXX} >> ${FILES}
cat ${FILES_HXX} >> ${FILES}
cat ${FILES_C} >> ${FILES}
cat ${FILES_H} >> ${FILES}

# Count each one
counter_all=`getCount ${FILES}`
counter_cpp=`getCount ${FILES_CPP}`
counter_cxx=`getCount ${FILES_CXX}`
counter_hpp=`getCount ${FILES_HPP}`
counter_hxx=`getCount ${FILES_HXX}`
counter_c=`getCount ${FILES_C}`
counter_h=`getCount ${FILES_H}`

# Get the parent directory
parentdir=`getLastDirectory ${PWD}`

# Output the counts
echo
echo "Count: ${counter_all}"
echo "  CPP: ${counter_cpp}"
echo "  HPP: ${counter_hpp}"
echo "  CXX: ${counter_cxx}"
echo "  HXX: ${counter_hxx}"
echo "    C: ${counter_c}"
echo "    H: ${counter_h}"
echo

# Build the CScope Database only if CScope is easily accessible
CSCOPE=`which cscope`
if [ -n "${CSCOPE}" ]; then
  
  # If the CScope Output directory doens't exist, create it
  if [ ! -d "${CSCOPE_OUTPUT_DIR}" ]; then 
    mkdir "${CSCOPE_OUTPUT_DIR}"
  fi

  # CScope Database file name under the output directory
  CSCOPE_OUTPUT_FILE="${parentdir}.out"
  
  # If the database (and its related parts) exist, remove it
  if [ -d "${CSCOPE_OUTPUT_DIR}" ]; then
    pushd "${CSCOPE_OUTPUT_DIR}" &> /dev/null
      rm "${CSCOPE_OUTPUT_FILE}"
      rm "${CSCOPE_OUTPUT_FILE}.po"
      rm "${CSCOPE_OUTPUT_FILE}.in"
    popd &> /dev/null
  fi

  # Fully qualified database name
  CSCOPE_OUTPUT_FQ_FILE="${CSCOPE_OUTPUT_DIR}/${CSCOPE_OUTPUT_FILE}"
  if [ "${CSCOPE_OUTPUT_FQ_FILE:0:1}" != "/" ]; then
    CSCOPE_OUTPUT_FQ_FILE="${PWD}/${CSCOPE_OUTPUT_DIR}/${CSCOPE_OUTPUT_FILE}"
  fi
  
  # Build the CScope Indexes
  cscope -bRq -f ${CSCOPE_OUTPUT_FQ_FILE} ${FILES}
  if [ $? == 0 ]; then
    # Tell the user how they can utilize the generated database
    echo
    echo "You can now do:"
    echo
    echo "  export CSCOPE_DB=${CSCOPE_OUTPUT_FQ_FILE}"
    echo
  fi
fi

# Cleanup
rm -Rf ${MY_TMP_DIR}
