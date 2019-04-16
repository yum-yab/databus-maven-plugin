#! /bin/bash

diff2Files() {
# Syntax: diff2Files [oldFile] [newFile] [target](optional)
if [ -f $1 ] && [ -f $2 ]
then
	starttime=$(date +%s)
	filename="${2##*/}"
	unzipname="${filename%.*}"
	noendname="${unzipname%.*}"
	artifact="${noendname%%_*}"
	cv="${noendname#*_}"
	rawname="${artifact}-diff_${cv}"
	
	if [ -z $3 ]
	then
		target="${2%/*}"
	else
		target="$3"
	fi
	
	#loop for dynamic pipes	
	number=1
	while : 
	do
		if [ -p ${target}/oldfilePipe${number} ] || [ -p ${target}/newfilePipe${number} ]
		then
			number=$(($number + 1))
		else
			mkfifo ${target}/oldfilePipe${number} 	
			mkfifo ${target}/newfilePipe${number}
			break 
		fi
	done
	
	echo "Working on file ${1##*/} and ${2##*/}"
	
	LC_ALL=C sort -u -T $target $1 > ${target}/oldfilePipe${number} &
	LC_ALL=C sort -u -T $target $2 > ${target}/newfilePipe${number} &

	#touch file because with no adds _adds.ttl wont be created
	touch ${target}/${rawname}_adds.ttl


	comm -3 ${target}/oldfilePipe${number} ${target}/newfilePipe${number} | awk '/^[\t]/ {print substr($0,2)>"'${target}/${rawname}'_adds.ttl";next} 1' > ${target}/${rawname}_deletes.ttl
	python3 ~/difftest/QuitDiff/bin/quit-diff --diffFormat=eccrev . ${target}/${rawname}_deletes.ttl 1 2 ${target}/${rawname}_adds.ttl > ${target}/${rawname}_eccrev.trig #read parsed files

	endtime=$(date +%s)
	time=$(($endtime - $starttime))

	rm ${target}/oldfilePipe${number}
	rm ${target}/newfilePipe${number}  
	#rm ${target}/${rawname}_adds.ttl
	#rm ${target}/${rawname}_deletes.ttl

	echo "Process finished. Time needed:"
	echo "- whole process: ${time} seconds"

fi
	
}

# Syntax: diffscript (Optional: -d targetdir) -v diff-version [dir] [oldVersion(date/dirName)] [newVersion(date/dirname)]

while test $# -gt 0; do
        case "$1" in
                -h|--help)
                        echo "There is no help"
			exit 0
			;;
                -v|--version)
			shift
                        diffversion=$1
			shift
			;;
                -d)
               		shift
			if [ -d $1 ]
			then
				targetdir="$1"
				shift
			else
				echo "Target directory does not exist."
				exit 1
			fi
                     	;;
		*)
			break	
			;;
        esac
done

if [ $diffversion ]
then
	date=$diffversion
else
	exit
fi

for dir in $1/* ; do
	if [ -d $dir ]
	then
		if [ -d "$targetdir" ]
		then
			artifact=$(basename $dir)
			mkdir "${targetdir}/${artifact}-diff"
			mkdir "${targetdir}/${artifact}-diff/${date}"
		fi
		if [ -d $dir/$2/ ] && [ -d $dir/$3/ ]
		then 
			for file in $dir/$2/*.ttl ; do
				filename=$(basename $file)
				newfile=$dir/$3/$filename
				fulltarget="${targetdir}/${artifact}-diff/${date}"
		
				if [ -f $newfile ]
				then
					if [ -d "$targetdir" ]
					then
					diff2Files $file $newfile $fulltarget 
					else
					diff2Files $file $newfile  
					fi
				
				fi

			done
	
		fi
	fi
done
