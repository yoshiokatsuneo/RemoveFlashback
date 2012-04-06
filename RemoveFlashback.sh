#!/bin/sh
#
# RemoveFlashback.sh
#   -- Flashback virus removal tool --
#    by Yoshioka Tsuneo
# Ref:
#   F-Secure Weblog - Mac Flashback Infections
#   http://www.f-secure.com/weblog/archives/00002345.html
#

timestamp=`date '+%Y%m%d-%H%M%S'`
infected=0
tmpfilename_base=/tmp/RemoveFlashback.$$

safari_plist_base="/Applications/Safari.app/Contents/Info"
# safari_plist_base="`pwd`/test-Info"
macosx_environment_plist="${HOME}/.MacOSX/environment"
# macosx_environment_plist="${HOME}/work/RemoveFlashback/test-environment"

check_libraries()
{
	plist_base="$1"
	libraries="$2"

	infected=1
	grep -a -o '__ldpath__[ -~]*' "${libraries}" | while read line; do
		ldpath=${line/#__ldpath__/}
		if [ -f "$ldpath" ];then
			echo "Possible infected file: ${ldpath} . If this is malware, please remove manually."
			# rm -i "${ldpath}"
		fi
	done
}
check_safari_plist(){
	local plist_base=$1

	if ! [ -e "${plist_base}.plist" ]; then return 0; fi
	if ! defaults read "${plist_base}" LSEnvironment > "${tmpfilename_base}.plist" 2>/dev/null ]; then
		return 0
	fi
	libraries=$(defaults read "${tmpfilename_base}" "DYLD_INSERT_LIBRARIES")
	if [ $? -eq 0 ]; then
		check_libraries "${plist_base}" "$libraries"
	fi
	echo "Found LSEnvironmemt in ${plist_base}.plist LSEnvironment. Removing..."
	sudo cp -p "${plist_base}.plist" "${plist_base}.plist.${timestamp}"
	sudo defaults delete "${plist_base}" LSEnvironment
	sudo chmod 644 "${plist_base}.plist"
}

check_macosx_environment_plist()
{
	local plist_base=$1

	if ! [ -e "${plist_base}.plist" ]; then return 0; fi
	libraries=$(defaults read "${plist_base}" "DYLD_INSERT_LIBRARIES" 2>/dev/null)
	if [ "$?" -ne "0" ]; then
		return 0
	fi
	check_libraries "${plist_base}" "$libraries"
	echo "Found DYLD_INSERT_LIBRARIES in ${plist_base}.plist. Removing..."
	cp -p "${plist_base}.plist" "${plist_base}.plist.${timestamp}"
	defaults delete "${plist_base}" DYLD_INSERT_LIBRARIES
}

check_safari_plist "${safari_plist_base}"
check_macosx_environment_plist "${macosx_environment_plist}"

if [ -f "${tmpfilename_base}.plist" ]; then
	rm "${tmpfilename_base}.plist"
fi


if [ "`launchctl getenv DYLD_INSERT_LIBRARIES`" != "" ]; then
	infected=1
	echo "Found DYLD_INSERT_LIBRARIES in launchctl environment. Removing..."
	launchctl unsetenv DYLD_INSERT_LIBRARIES
fi

if [ "$infected" -eq "0" ];then
	echo "No Flashback virus found. This Mac looks clean."
fi
exit $infected


