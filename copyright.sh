#!/bin/bash
# ------------------------------------------------------------------------------
# TYPO3 Copyright Headers
#
# @author: Michael Schams <schams.net>
# @link: https://github.com/schams-net/typo3-copyright-header
# ------------------------------------------------------------------------------

# The following command generates a list of all file extensions (e.g. php, js, pcx, tig, jpg, etc.)
# find typo3_src-git -path typo3_src-git/.git -prune -o -printf "%f\n" | grep "\." | sed 's/^.*\(\..*\)$/\1/g' | sort | uniq
#
# The current version of the script only supports *.php files:
INCLUDE_FILE_PATTERN='\.php$'

DIRECTORY=$1

if [ "${DIRECTORY}" = "" ]; then
	echo -e "\nUsage: $0 <typo3_src directory>\n"
	exit 1
fi

if [ ! -d "${DIRECTORY}" ]; then
	echo -e "\nDirectory \"${DIRECTORY}\" does not exist\n"
	exit 1
fi

if [ -e "copyright.ignored" ]; then
	rm "copyright.ignored"
fi

COUNTER=0
PROCESSED=0
SKIPPED=0

DIRECTORY=$(echo "${DIRECTORY}" | sed 's/\/$//g')

TIME_START=$(date +"%s")

echo ; echo "Scanning directory..."
FILELIST=$(find "${DIRECTORY}" -path "${DIRECTORY}/.git" -path "${DIRECTORY}/contrib" -prune -o -type f -print | egrep "${INCLUDE_FILE_PATTERN}")

TOTAL_FILES=$(echo "${FILELIST}" | wc --line)

tput cuu1
echo "Scanning directory......: ${TOTAL_FILES} files found"

echo -e "\n\n\n"

declare -i START_LINENUMBER
declare -i END_LINENUMBER

IFS=$'\n'
for FILE in $(echo "${FILELIST}") ; do

	let COUNTER=COUNTER+1

	# extract file extension (everything after the last dot in the file name)
	EXTENSION=$(echo "${FILE}" | sed 's/^.*\.\(.*\)$/\1/g')

	# Investigate the first 42 lines
	# Why fourty-two? Well, it does not matter: we could also investigate the first 23 lines ;-)
	# But a standard TYPO3 PHP file contains the copyright header between line 2 and 26.
	HEADER=$(cat "${FILE}" | head -42)

	# header lines must at least contain the words "copyright" and "typo3"
	TEMP=$(echo "${HEADER}" | grep --ignore-case --max-count=1 "copyright")","$(echo "${HEADER}" | grep --ignore-case --max-count=1 "typo3")
	TEMP=$(echo "${TEMP}" | egrep -v '^,|,$')
	if [ ! "${TEMP}" = "" ] ; then

		TOTAL_LINES=$(cat "${FILE}" | wc --line)
		START_LINENUMBER=$(echo "${HEADER}" | grep --line-number --max-count=1 "/\*" | cut -d : -f 1)
		END_LINENUMBER=$(echo "${HEADER}" | grep --line-number --max-count=1 "\*/" | cut -d : -f 1)

		if [ ! "${START_LINENUMBER}" = "" -a ! "${END_LINENUMBER}" = "" -a ${START_LINENUMBER} -gt 0 -a ${END_LINENUMBER} -gt 0 -a ${END_LINENUMBER} -lt ${TOTAL_LINES} ]; then

			let START_LINENUMBER=${START_LINENUMBER}-1
			let END_LINENUMBER=${END_LINENUMBER}+1

			cat "${FILE}" | head -${START_LINENUMBER} > "${FILE}.copyright"
			cat "copyright-php-files.txt" >> "${FILE}.copyright"
			cat "${FILE}" | sed -n "${END_LINENUMBER},${TOTAL_LINES}p" >> "${FILE}.copyright"
			mv "${FILE}.copyright" "${FILE}"

			let PROCESSED=${PROCESSED}+1
		else
			echo "[L] ${FILE}" >> "copyright.ignored"
			let SKIPPED=${SKIPPED}+1
		fi
	else
		echo "[H] ${FILE}" >> "copyright.ignored"
		let SKIPPED=${SKIPPED}+1
	fi

	let TIME_ELAPSED=$(date +"%s")-${TIME_START}

	tput cuu1 ; tput cuu1 ; tput cuu1 ; tput cuu1
	echo "Files checked...........: ${COUNTER} of ${TOTAL_FILES}"
	echo "Files processed.........: ${PROCESSED}"
	echo "Files skipped...........: ${SKIPPED}"
	echo "Time elapsed (seconds)..: ${TIME_ELAPSED}"
done

echo

exit 0

