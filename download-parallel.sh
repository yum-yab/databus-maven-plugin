 #! /bin/bash

set -euo pipefail

# TODO better cli


process_link_cmd=$(cat <<'EOF'

    # extract the first field, ommitting the backslash
    url=$(echo "{}" | perl -ne '{ print $1 if /^([^ ]+?)\\/ }')
    sinkpath=$(echo "{}" | awk '{ print $2 }')

    curl --fail --silent --show-error $url \
	| lbzcat \
	| rapper -i ntriples - http://baseuri 2> /dev/null \
	| lbzip2 > $sinkpath
EOF
)

collect_links_and_sinks() {

    for dataid in $*; do 
	    # get dowload paths for dataid
	    links=`rapper -i turtle -o ntriples $dataid 2> /dev/null \
	    | grep "<http://www.w3.org/ns/dcat#downloadURL>" \
	    | cut -d" " -f3 \
	    | sed "s/[<>]//g"`

        for url in $links; do
       		filename=${url##*/}
		    version=${url%/*} 
		    artifactId=${version%/*}
		    version=${version##*/} 
		    artifactId=${artifactId##*/} # echo $artifactId $version


            echo "$url" "$artifactId/$version/$filename"
        done
    done
}

echo "||$process_link_cmd||"

collect_links_and_sinks $* | parallel "$process_link_cmd"
