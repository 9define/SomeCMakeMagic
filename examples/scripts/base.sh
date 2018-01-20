#!/bin/bash

operate_on_all_examples() {
	# determine if find needs to look at the parent directory
	PREFIX=./
	if [[ "${PWD##*/}" == "scripts" ]]; then
		PREFIX=../
	fi

	# operate on all examples per the given criteria
	for ex_dir in `find $PREFIX -maxdepth 1 ! -path $PREFIX ! -path $PREFIX"scripts" -type d`; do
		ex_dir_name=`basename $ex_dir`
		# w=$([[ $1 = "build" ]] && echo "Building" || echo "Cleaning" ) # determine what message to give
		w=`case "$1" in
			"build")
				echo "Building"
				;;
			"clean")
				echo "Cleaning"
				;;
			"test")
				echo "Testing"
				;;
		esac`
		printf "%s \'$ex_dir_name\'...\n" $w
		SCRIPT_PREFIX=./scripts
		if [[ $PREFIX == "../" ]]; then
			SCRIPT_PREFIX=./
		fi
		$SCRIPT_PREFIX/$1-example $ex_dir_name
		if [[ "$1" == "test" ]]; then
			if [ $? == 0 ]; then
				echo "Test passed for example '$ex_dir_name'"
			fi
			$SCRIPT_PREFIX/clean-example $ex_dir_name
		fi
	done
}
