#! /bin/bash

########################Config############################

# Paths to the pom-Directories of the groupIds
groupIds=("/home/denis/Workspace/job/synth-datadump/complete-dump/mappings-synth" "/home/denis/Workspace/job/synth-datadump/complete-dump/generic-synth")


##########################################################

startdir=$PWD


generateSynthData() {
pomdir=$1
source_version=$2
release_date=$3
./synthdatagen $pomdir $source_version $release_date
}

releaseGroup() {
pomdir=$1
release_date=$2

cd $pomdir
mvn versions:set -DnewVersion=$release_date
mvn deploy
cd $startdir

}

date=$(date +%Y.%m.%d)

for groupId in "${groupIds[@]}"; do
	# source_version is the oldest version
	source_version=$(ls ${groupId}/* | grep '^[0-9]\{4\}.[0-9]\{2\}.[0-9]\{2\}$' | sort -u | head -1)
	echo "Generating Synth-Data for ${groupId} with base-version $source_version."
	generateSynthData $groupId $source_version $date
	#releaseGroup $groupId $date
done
