#!/bin/zsh

set -e

buildTool() {
	clang -fmodules -I $SOURCES/Utils -Wno-unused-getter-return-value -Wno-objc-missing-super-calls $SOURCES/Tools/$1.m -o $OUTDIR/$1
}

main() {
	POSITIONAL_ARGS=()

	while [[ $# -gt 0 ]]; do
	case $1 in 
		-o|--outDir)
		OUTDIR="$2"
		shift # Increment key index
		shift # Increment value index
		;;
		-s|--sources)
		SOURCES="$2"
		shift # Increment key index
		shift # Increment value index
		;;
		-f|--force)
		FORCE="y"
		shift # Increment key index
		;;
		*)
		# Save the rest as positional arguments
		POSITIONAL_ARGS+=("$1")
		shift # past argument
		;;
	esac
	done

	if [[ -z "$OUTDIR" ]]; then
		OUTDIR="${0:a:h}/Build"
		echo "No output directory specified. Defaulting to \"$OUTDIR\"..."
	fi

	if [[ -z "$SOURCES" ]]; then
		SOURCES="${0:a:h}/Tools"
		echo "No sources directory specified. Defaulting to \"$SOURCES\"..."
	fi

	if [[ -d $OUTDIR || $FORCE == "y" ]]; then
		if [[ $FORCE == "y" ]]; then
			answer="y"
		else
			read "answer?\"$OUTDIR\" already exists. Do you want to delete it and rebuild? (y/n): "
		fi
		if [[ $answer == "y" ]]; then
			rm -rf $OUTDIR
			mkdir $OUTDIR
		fi
	else
		mkdir $OUTDIR
	fi

	# Build the binary tools
	buildTool Stubber
	buildTool StubberObjcHelper
	buildTool Renamer
	buildTool Binpatcher
	# Copy the utility headers
	cp -Rc $SOURCES/Utils $OUTDIR/Utils
	# Copy the utility scripts
	cp -Rc $SOURCES/Gadgets $OUTDIR
}

main "$@"