VENV_BASE="${HOME}/.bin/.python-envs"

function getToolVirtualEnv()
	{
	local TOOL_NAME="${1}"
	echo "${VENV_BASE}/${TOOL_NAME}"
	}

function validateVirtualEnvPath()
	{
	local -i returnValue=0
	local VENV_PATH="${1}"
	# make sure the venv path is under the base venv path
	if [ "${VENV_PATH:0:${#VENV_BASE}}" == "${VENV_BASE}" ]; then
		# make sure it is *not* the base venv path
		if [ "${VENV_PATH}" != "${VENV_BASE}" ]; then
			let -i returnValue=0
		else
			let -i returnValue=1
		fi
	else
		let -i returnValue=2
	fi

	return ${returnValue}
	}

function createToolVirtualEnv()
	{
	local -i returnValue=0
	local VENV_PATH="${1}"
	local VENV_REBUILD="${2}"

	validateVirtualEnvPath "${VENV_PATH}"
	let -i result=$?
	if [ ${result} -ne 0 ]; then
		echo "Virtual Environment Path (${VENV_PATH}) is invalid - ${result}"
		let -i returnValue=1
	else
		# allow the venv to be rebuild
		if [ "${VENV_REBUILD}" == "yes" ]; then
			# make sure the directory exists
			if [ -d "${VENV_PATH}" ]; then
				echo "Cleaning Virtual Environment: ${VENV_PATH}"
				rm -Rf "${VENV_PATH}"
				let -i returnValue=$?
			fi
		fi

		if [ ! -d "${VENV_PATH}" ]; then
			echo "Creating the Virtual Env"
			virtualenv "${VENV_PATH}"
			let -i returnValue=2
		fi
	fi

	return ${returnValue}
	}

function activateToolVirtualEnv()
	{
	local VENV_PATH="${1}"
	local VENV_ACTIVATION_PATH="${VENV_PATH}/bin/activate"
	source "${VENV_ACTIVATION_PATH}"
	}

function installPackages()
	{
	local PACKAGES_TO_INSTALL="$*"
	pip install "${PACKAGES_TO_INSTALL}"
	return $?
	}
