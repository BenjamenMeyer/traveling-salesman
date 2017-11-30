REBUILD_VENV=""

GLOBAL_ARG_OPTION=""
UNPARSED_ARGS=""
for GLOBAL_SCRIPT_ARG in ${@}
do
	if [ -z "${GLOBAL_ARG_OPTION}" ]; then
		# process based on the arg being parsed
		case "${GLOBAL_SCRIPT_ARG}" in
			"--rebuild")
				REBUILD_VENV="yes"
				;;
			"-r")
				REBUILD_VENV="yes"
				;;
			*)
				if [ -z "${UNPARSED_ARGS}" ]; then
					UNPARSED_ARGS="${GLOBAL_SCRIPT_ARG}"
				else
					UNPARSED_ARGS="${UNPARSED_ARGS} ${GLOBAL_SCRIPT_ARG}"
				fi
				;;
		esac
	else
		# lookup based on the saved arg option
		# and apply the GLOBAL_SCRIPT_ARG as a value to that option
		case "${GLOBAL_ARG_OPTION}" in
			*)
				if [ -z "${UNPARSED_ARG}" ]; then
					UNPARSED_ARGS="${GLOBAL_SCRIPT_ARG}"
				else
					UNPARSED_ARGS="${UNPARSED_ARGS} ${GLOBAL_SCRIPT_ARG}"
				fi
				GLOBAL_ARG_OPTION=""
				;;
		esac
	fi
done
