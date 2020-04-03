#!/usr/local/bin/bash

function getResult()
    {
    local user_prompt="${2}"
    local is_password="${3}"
    local result
    if [ "${is_password}" == "yes" ]; then
        builtin read -s -p "${user_prompt}" result
        echo
    else
        builtin read -p "${user_prompt}" result
    fi
    eval ${1}=\$result
    }

function getUnprotectedResult()
    {
    local unprotected_result
    eval echo "\$${1}"
    getResult unprotected_result "${2}" "no"
    eval ${1}=\$unprotected_result
    }

function getProtectedResult()
    {
    local protected_result
    getResult protected_result "${2}" "yes"
    eval ${1}=\$protected_result
    }

CREDENTIALED_SERVICE_NAME=""
CREDENTIALED_ACCOUNT_NAME=""
CREDENTIALED_ACCOUNT_PASSWORD=""

getUnprotectedResult CREDENTIALED_SERVICE_NAME "Service Name: "
getUnprotectedResult CREDENTIALED_ACCOUNT_NAME "Account Name: "
getProtectedResult CREDENTIALED_ACCOUNT_PASSWORD "Password: "

security add-generic-password -U -a "${CREDENTIALED_ACCOUNT_NAME}" -s "${CREDENTIALED_SERVICE_NAME}" -w "${CREDENTIALED_ACCOUNT_PASSWORD}"

# NOTE: credentials can be retrieved with: security find-generic-password -gw -a ${CREDENTIALED_ACCOUNT_NAME} -s "${CREDENTIALED_SERVICE_NAME}"
# NOTE: `-g` shows the password; `-w` shows *only* the password; they can be combined as `-gw`
