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
#INCLUDE_FILE_PATTERN='\.js$'

DIRECTORY=$1
PROCESS_MAX=$2

if [ "${DIRECTORY}" = "" ]; then
	echo -e "\nUsage: $0 <typo3_src directory> [<max number of files to process>]\n"
	exit 1
fi

if [ ! -d "${DIRECTORY}" ]; then
	echo -e "\nDirectory \"${DIRECTORY}\" does not exist\n"
	exit 1
fi

TEMP=$(echo "${PROCESS_MAX}" | egrep '^[0-9]{1,}$')
if [ "${TEMP}" = "" ]; then
	PROCESS_MAX=100
fi

if [ -d "/tmp/typo3headers" ] ; then
	find "/tmp/typo3headers" -type f -exec rm {} \;
else
	mkdir "/tmp/typo3headers"
fi

if [ -e "copyright.ignored" ]; then
	rm "copyright.ignored"
fi

COUNTER=0
PROCESSED=0
SKIPPED=0
ALREADY_PROCESSED=0
UNIQUE_HEADERS=0

DIRECTORY=$(echo "${DIRECTORY}" | sed 's/\/$//g')
TIME_START=$(date +"%s")
touch "copyright.exclude"

#echo ; echo "Maximum number of files to process: ${PROCESS_MAX}" ; echo
echo ; echo "Scanning directory..."

# for .php files:
FILELIST=$(find "${DIRECTORY}" -path "${DIRECTORY}/.git" -path "${DIRECTORY}/contrib" -prune -o -type f -print | egrep "${INCLUDE_FILE_PATTERN}")

# for .js files:
#FILELIST=$(find "${DIRECTORY}" -path "${DIRECTORY}/typo3/contrib" -prune -o -type f -print | egrep "${INCLUDE_FILE_PATTERN}")

TOTAL_FILES=$(echo "${FILELIST}" | wc --line)

tput cuu1
echo "Scanning directory......: ${TOTAL_FILES} files found"

echo -e "\n\n\n\n\n"

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

			let START_LINENUMBER=${START_LINENUMBER}
			let END_LINENUMBER=${END_LINENUMBER}
			let TOTAL_LINES=${TOTAL_LINES}+1

			# determine MD5 hash of path/filename
			FILENAME_MD5=$(echo "${FILE}" | md5sum | cut -f 1 -d ' ')

			EXCLUDE_FROM_PROCESS="false"
			TEMP=$(cat "copyright.exclude" | grep "${FILENAME_MD5}")
			if [ ! "${TEMP}" = "" ]; then
				EXCLUDE_FROM_PROCESS="true"
			fi

			# extract header
			OLD_HEADER=$(cat "${FILE}" | sed -n "${START_LINENUMBER},${END_LINENUMBER}p")
			OLD_HEADER_MD5=$(echo "${OLD_HEADER}" | md5sum | cut -f 1 -d ' ')
			if [ ! -e "/tmp/typo3headers/${OLD_HEADER_MD5}" ] ; then
				echo "${OLD_HEADER}" > "/tmp/typo3headers/${OLD_HEADER_MD5}"
				let UNIQUE_HEADERS=UNIQUE_HEADERS+1
			fi

			if [ "${OLD_HEADER_MD5}" = "fbe60edac6cc33f523fb4ecffa055cb4" -o "${EXCLUDE_FROM_PROCESS}" = "true" ]; then
				# file already shows new header or is excluded from process
				echo "[A] ${FILE}" >> "copyright.ignored"
				let SKIPPED=${SKIPPED}+1
				let ALREADY_PROCESSED=${ALREADY_PROCESSED}+1
			else
				# first part
				let LINENUMBER=${START_LINENUMBER}-1
				cat "${FILE}" | head -${LINENUMBER} > "${FILE}.copyright"

				# second part (copyright header)
				cat "copyright-php-files.txt" >> "${FILE}.copyright"

				# third part (rest of the file)
				let LINENUMBER=${END_LINENUMBER}+1
				cat "${FILE}" | sed -n "${LINENUMBER},${TOTAL_LINES}p" >> "${FILE}.copyright"

				mv "${FILE}.copyright" "${FILE}"

				echo "${FILENAME_MD5}" >> "copyright.exclude"

				let PROCESSED=${PROCESSED}+1
			fi
		else
			# unable to determine start/end line numbers
			echo "[L] ${FILE}" >> "copyright.ignored"
			let SKIPPED=${SKIPPED}+1
		fi
	else
		# something suspecious with the current header (maybe no header exists?)
		echo "[H] ${FILE}" >> "copyright.ignored"
		let SKIPPED=${SKIPPED}+1
	fi

	let TIME_ELAPSED=$(date +"%s")-${TIME_START}

	tput cuu1 ; tput cuu1 ; tput cuu1 ; tput cuu1 ; tput cuu1 ; tput cuu1
	echo "Files checked...........: ${COUNTER} of ${TOTAL_FILES}"
	echo "Files processed.........: ${PROCESSED} of ${PROCESS_MAX}"
	echo "Files skipped...........: ${SKIPPED}"
	echo "Files already processed.: ${ALREADY_PROCESSED}"
	echo "Unique headers found....: ${UNIQUE_HEADERS}"
	echo "Time elapsed (seconds)..: ${TIME_ELAPSED}"

	if [ ${PROCESSED} -ge ${PROCESS_MAX} ]; then
		echo
		echo "Maximum allowed number of files to process reached/exceeded."
		break
	fi

done

echo

exit 0
