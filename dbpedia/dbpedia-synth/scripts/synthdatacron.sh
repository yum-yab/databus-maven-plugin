#! /bin/bash

#load the variables
source /home/denis/data/synth-test/databus-maven-plugin/dbpedia/dbpedia-synth/scripts/dsconfig
#Method to get the latest version of the synth-diffs
getlatestversion() {
	genericSynthVersion=$(ls /media/bigone/25TB/www/downloads.dbpedia.org/tmpdev/dbpedia-synth/generic-synth/* | grep '^[0-9]\{4\}.[0-9]\{2\}.[0-9]\{2\}$' | sort -u  | tail -1)
	
	mappingsSynthVersion=$(ls /media/bigone/25TB/www/downloads.dbpedia.org/tmpdev/dbpedia-synth/mappings-synth/* | grep '^[0-9]\{4\}.[0-9]\{2\}.[0-9]\{2\}$' | sort -u  | tail -1)
}

# Method to create a diretory if it isnt there already
scd () {
	if ! [ -d $1 ]
	then
		mkdir $1
	fi
}

# downloads the files and saves them under the version defined in dsconfig.xml in the originalDir
downloadFiles() {

	# Generate dir structure and download the synth and original data
	if [ -d $targetdir ]
	then
		scd $targetdir/mappings-synth
		echo "Started mappings-download"
		for artifact in "${mappingsArtifacts[@]}" ; do
			scd $targetdir/mappings-synth/$artifact
			scd $targetdir/mappings-synth/$artifact/$mappingsSynthVersion/
			for cv in "${contentVariants[@]}" ; do
				
				echo "Downloading mappings-synth file ${artifact}_${cv}.ttl.bz2 .... "
				curl "${synthURL}/mappings-synth/${artifact}/${mappingsSynthVersion}/${artifact}_${cv}.ttl.bz2" -o $targetdir/mappings-synth/$artifact/$mappingsSynthVersion/${artifact}_${cv}.ttl.bz2
			
			done
		done
		echo "Starting generic download"
		scd $targetdir/generic-synth
		for artifact in "${genericArtifacts[@]}"; do
			scd $targetdir/generic-synth/$artifact
			scd $targetdir/generic-synth/$artifact/$genericSynthVersion
			for cv in "${contentVariants[@]}" ; do
				echo "Downloading generic-synth file ${artifact}_${cv}.ttl.bz2 ...."
				curl "${synthURL}/generic-synth/${artifact}/${genericSynthVersion}/${artifact}_${cv}.ttl.bz2" -o $targetdir/generic-synth/$artifact/$genericSynthVersion/${artifact}_${cv}.ttl.bz2
			done
		
		done
	else 
		echo "${targetdir} is not a directory"
	fi

}

# rapandsort srcDir e.g mappings-synth
rapandsort() {
	${scriptdir}/rapandsort_mod.sh $1 $targetdir	
}

# runDiff target srcDir orgVersion synthVersion
runDiff() {
	${scriptdir}/diffscript_mod.sh	-v $1 -d $2 $3 $4 $5  
}

startdir=$PWD
date=$(date +%Y.%m.%d)

#get the latest synth release versions
getlatestversion

#check if the last release of synth data was on a different day

if [ $date == $mappingsSynthVersion ] || [ $date == $genericSynthVersion ]
then
	echo "There was already a release today"
	exit 1
fi

downloadFiles

#running rapandsort on the synth files
echo "Started running rapandsort on mappings ..."
for artifact in "${mappingsArtifacts[@]}"; do
	echo "rapandsorting synth-version of ${artifact}..."
	rapandsort $targetdir/mappings-synth/$artifact/$mappingsSynthVersion
done

echo "Started running rapandsort on generic ..."
for artifact in "${genericArtifacts[@]}"; do
	echo "rapandsorting synth-version of ${artifact}..."
	rapandsort $targetdir/generic-synth/$artifact/$genericSynthVersion
done

#generating the new synth-data
echo "Generating Synth Data for mappings..."
$scriptdir/synthdatagen $targetdir/mappings-synth $mappingsSynthVersion $date

echo "Generating Synth Data for generic..."
$scriptdir/synthdatagen $targetdir/generic-synth $genericSynthVersion $date



#make the diff directory

scd $targetdir/dbpedia-diff-synth 

echo  "Starting running the diffs ..."
runDiff $date $targetdir/dbpedia-diff-synth $targetdir/mappings-synth $mappingsSynthVersion $date
runDiff $date $targetdir/dbpedia-diff-synth $targetdir/generic-synth $genericSynthVersion $date


#compressing the synth-data
echo "Compressing mappings-synth ..."
pbzip2 $targetdir/mappings-synth/*/$date/*.ttl
pbzip2 $targetdir/mappings-synth/*/$mappingsSynthVersion/*.ttl
echo "Compressing generic-synth ..."
pbzip2 $targetdir/generic-synth/*/$date/*.ttl
pbzip2 $targetdir/generic-synth/*/$genericSynthVersion/*.ttl

#Compressing the diffs
pbzip2 $targetdir/dbpedia-diff-synth/*/$date/*

#change to actual diff version and release the diff
cd $targetdir/dbpedia-diff-synth 
mvn versions:set -DnewVersion=${date}
#release
mvn deploy
cd $startdir

#releasing the freshly generated synth-data and the sorted older one
#release of mappings data
cd $targetdir/mappings-synth
#rereleasing the older synth version rappered and sorted
mvn versions:set -DnewVersion=${mappingsSynthVersion}
mvn deploy
#new synth version release
mvn versions:set -DnewVersion=${date}
mvn deploy
#reelase of generic data
cd $targetdir/generic-synth
mvn versions:set -DnewVersion=${genericSynthVersion}
mvn deploy
mvn versions:set -DnewVersion=${date}
mvn deploy
cd $startdir

