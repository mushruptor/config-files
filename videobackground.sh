#!/bin/env bash

stream () 
{
    # --brightness -10
    xwinwrap -ov -fs -- mpv $1 -wid WID --cache-default 2147483647 --no-audio &
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do

key=$1
case $key in
    -p|--previous)
    PREV=true
    shift # past argument
    ;;
    -n|--next)
    NEXT=true
    shift # past argument
    ;;
    -t|--toggle)
    TOGGLE=true
    shift # past argument
    ;;
    --default)
    DEFAULT=YES
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

echo PREV            = "${PREV}"
echo NEXT            = "${NEXT}"
echo TOGGLE          = "${TOGGLE}"
if [[ -n $1 ]]; then
    echo "$1"
fi

FILENAME="$1"
STRING=$(head -n 1 "$FILENAME")

if [ "$TOGGLE" == true ]
then
    echo TOGGLE MODE
    # closes all mpv instances or loads stream directly over url, overrules all other commands
    if [ ! -z "$(xdotool search --class mpv)" ]
    then
        killall mpv
    else
        if [ -z "$1" ]
        then 
	        STREAM=$stream1  
        else
            SEARCHSTRING="STATE"
            echo STRING = "${STRING}"
            STATE=$(cut -d " " -f 2 <<< "$STRING")
            echo STATE = "${STATE}"
            STREAM=$(sed "$(( STATE + 1 ))q;d" "$FILENAME")
            echo STREAM = "${STREAM}"
        fi
        stream $STREAM
    fi    
else
    # argument now is a path not a stream url!
    if [[ "$STRING" = *"STATE"* ]]
    then
        SEARCHSTRING="STATE "
        STATE=$(cut -d " " -f 2 <<< "$STRING")
        NUMOFLINES=$(wc -l < "$FILENAME")
        if [ "$PREV" == true ]
        then
            STATE="$((STATE - 1))"
        fi
        if [ "$NEXT" == true ]
        then
            STATE="$((STATE + 1))"
        fi
        if [[ "$STATE" -le 0 ]]
        then
            STATE=$((NUMOFLINES - 1))
        elif [[ "$STATE" -ge "$NUMOFLINES" ]]
        then 
            STATE=1
        fi
        sed -i "1s/.*/STATE $STATE/" "$FILENAME"
    else
        STATE=1
        sed "1i STATE 1" "$FILENAME" 
    fi
    STREAM=$(sed "$((STATE + 1))q;d" "$FILENAME")
    echo STREAM = "${STREAM}"
    killall mpv
    stream $STREAM
fi
