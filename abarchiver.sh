#!/bin/bash -e

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

## -------------------------------------------------------------
## This script archives audiobooks to compressed ogg/opus files.
## It accepts Audible (.aax) files, as well as generic audio files
## (mp3, m4b, wav, etc). It preserves embedded chapter metadata
## from single files, or generates it based on file breaks.
##
##
##
## Note: These variables are useful.
## Define them in ~/.config/.abarchiver.rc or on the command line
## (command line options override config file)
##    KEY='AUDIBLE KEY'
##    DEST='Default destination' (defaults to $HOME)
##    POCKETSPHINX='Pocket Sphinx executable'
##    POCKETSPHINX_POSTPROCESS='pipe pocket sphinx output'
##                             (Defaults to 'python ./pocketsphinx_filter.py')
##    HMM='Hidden Markov Model'
##    LM='Language Model'
## -------------------------------------------------------------

declare -a cleanup_items

cleanup() {
    # Cleans up temporary files, etc.
    # Add commands to be executed at termination via add_cleanup function
    (>&2 echo '')
    (>&2 echo 'Exiting cleanly')
    for i in "${cleanup_items[@]}"
    do
        eval $i
    done
    exit
}

add_cleanup() {
    # Add a command to the cleanup process
    local n=${#cleanup_items[*]}
    cleanup_items[$n]="$*"
    if [[ $n -eq 0 ]]; then
        trap cleanup SIGHUP SIGINT SIGTERM EXIT
    fi
}

executable() {
    # Print the executable name
    name=$(basename $0)
    if [[ $(type -P $name) ]]; then
        cmd="$(command -v $name 2>/dev/null)"
        if [ "$(readlink -f "$cmd")" == "$(readlink -f "$0")" ]; then
            echo -n $(basename $cmd)
        else
            echo -n $0
        fi
    else
        echo -n $0
    fi
}

shorthelp() {
    echo "Usage: $(executable) [ OPTIONS ] input_file(s)"
}

helpmsg() {
    echo $(executable)
    echo ''
    echo 'NAME'
    echo '    abarchiver -- Archive audio books from Audible or elsewhere'
    echo ''
    echo 'SYNOPSIS'
    echo -n '    '; shorthelp
    echo ''
    echo 'OPTIONS'
    echo '    --no-encode       Do not produce encoded audiobook.'
    echo '    --no-cover        Do not download cover image.'
    echo '    --no-transcript   Do not transcribe audiobook.'
    echo '    --key,-k KEY      Audible key.'
    echo '    --sphinx EXE      PocketSphinx executable.'
    echo '    --sphinx-pp CMD   Pocketsphinx output filter.'
    echo '    --hmm HMM         Hidden Markov Model.'
    echo '    --lm LM           Language Model.'
    echo ''
    echo 'EXAMPLES'
    echo "    $(executable) AudioBookUnabridged.aax"
    echo "    $(executable) --no-transcript AudioBook1_librivox.m4b"
}

ffmetadata() {
    # print ffmetadata
    ffmpeg -i "$1" -f ffmetadata - 2>/dev/null
}

get_tag_val() {
    # Prints just the metadata tag value
    ffprobe -v quiet -show_format "$1" | grep "^TAG:$2=" | head -n1 | sed 's/.*=//'
}

get_tag() {
    # Prints metadata tag as "key=value" pair
    if [ "$(get_tag_val "$1" "$2")" ]; then
        echo "$2=$(get_tag_val "$1" "$2")"
    else
        printf ""
    fi
}

destination() {
    # Prints default output directory
    # Usage: dest "author" "title"
    echo "$DEST/$1 - $2" | sed 's/:/-/' | sed -e "s/[^ 'A-Za-z0-9._-()]/_/g"
}

timestamp() {
    # Prints timestamp as HH:MM:SS.SSS
    # Usage: timestamp $TIME $TIMEBASE
    HRS=$(python -c "print int(float($1)*$2/3600)")
    MIN=$(python -c "print int(((float($1)*$2)%3600)/60)")
    SEC=$(python -c "print (float($1)*$2)%60")
    printf "%02d:%02d:%0.3f\n" "$HRS" "$MIN" "$SEC"
}

transcribe() {
    if [ ! "$POCKETSPHINX" ]; then echo "You need to choose a pocketsphinx executable if you want to make a transcript."; exit 1; fi
    if [ ! "$HMM" ]; then echo "You need to define a hidden markov model if you want to make a transcript."; exit 1; fi
    if [ ! "$LM" ]; then echo "You need to define a language model if you want to make a transcript."; exit 1; fi
    $POCKETSPHINX -infile "$1" -time yes -hmm "$HMM" -lm "$LM" | $POCKETSPHINX_POSTPROCESS
}

# Config
DEST=$HOME
POCKETSPHINX_POSTPROCESS="python $(dirname $(readlink -f $0))/pocketsphinx_filter.py"
if [ -f "$HOME/.config/.abarchiver.rc" ]; then
    source ~/.config/.abarchiver.rc
fi


# Parse arguments
while [ ! -f "$1" ]; do
    case $1 in
        '--no-transcript' )
            no_transcript='TRUE' ;;
        '--no-cover' )
            no_cover='TRUE' ;;
        '--no-encode' )
            no_encode='TRUE' ;;
        '--key'|'-k' )
            KEY="$2"; shift ;;
        '--sphinx' )
            POCKETSPHINX="$2"; shift ;;
        '--sphinx-pp' )
            POCKETSPHINX_POSTPROCESS="$2"; shift ;;
        '--hmm' )
            HMM="$2"; shift ;;
        '--lm' )
            LM="$2"; shift ;;
        '-h'|'--help' )
            helpmsg; exit 0 ;;
        '' )
            shorthelp
            echo ''
            echo 'Error: No input file provided'
            exit 1
            ;;
        * )
            echo "Option: $1 not recognized"
            exit 1
            ;;
    esac
    shift
done

#Setup decoders
if [ ! $no_encode ] || [ ! $no_transcribe ]; then
    # Are we decrypting an Audible file?
    if [ "${1##*.}" == "aax" ]; then
        if [ ! "$KEY" ]; then echo "You ned to define a KEY for your Audible book"; exit 1; fi
        FFMPEG="ffmpeg -activation_bytes $KEY"
    else
        FFMPEG="ffmpeg"
    fi

    # Are we concatenating files?
    if [ "$2" ]; then
        concatfiles=$(mktemp)
        add_cleanup rm -f $concatfiles
        for infile in "$@"
        do
            # escape single quotes in file names
            escaped_name="$(echo "$PWD/$infile" | sed 's/\x27/\x27\\\x27\x27/g')"
            echo "file '$escaped_name'" >> $concatfiles
        done

        FFMPEG="$FFMPEG -f concat -safe 0"
        input="$concatfiles"
    else
        input="$1"
    fi
fi

# METADATA
if [ ! $no_encode ]; then
    # If encoding, build complete metadata
    metadata=$(mktemp)
    add_cleanup rm -f $metadata
    author=$(get_tag_val "$1" 'artist')
    title=$(get_tag_val "$1" 'album')
    echo ";FFMETADATA1" >> $metadata
    echo "title=$title" >> $metadata
    echo "album=$title" >> $metadata
    echo "artist=$author" >> $metadata
    echo "album_artist=$author" >> $metadata
    get_tag "$1" "comment" >> $metadata
    get_tag "$1" "date" >> $metadata
    get_tag "$1" "genre" >> $metadata
    # Handle chapters
    if [ ! "$2" ] && [ $(ffmetadata "$1" | grep '^\[CHAPTER\]' | wc -l) -gt 0 ]; then
        # Single file, has chapters.
        TIMEBASE="NULL"
        CHNO=1
        ffmetadata "$1" \
            | grep -e "^title" -e "^START" -e "TIMEBASE" \
            | tail -n+2 \
            | while read line
        do
            CHTAG=$(printf 'CHAPTER%02d' "$CHNO")
            if [[ $line == TIMEBASE* ]]; then
                TIMEBASE=$(echo $line | sed 's/.*=//')
            elif [[ $line == START* ]]; then
                if [ "$TIMEBASE" == "NULL" ]; then echo "TIMEBASE not initialized."; exit 0; fi
                START=$(echo $line | sed 's/START=//')
                echo "${CHTAG}=$(timestamp $START $TIMEBASE)" >> $metadata
            else
                echo "${CHTAG}NAME=$(echo $line | sed 's/title=//')" >> $metadata
                CHNO=$((CHNO+1))
            fi
        done
    elif [ -f "$2" ]; then
        # If concatenating multiple files, assume each one is a chapter.
        # Use their filenames as chapter titles.
        START=0
        CHNO=1
        for var in "$@"
        do
            CHTAG=$(printf 'CHAPTER%02d' "$CHNO")
            echo "${CHTAG}=$(timestamp $START 1)" >> $metadata
            bn=$(basename "$var")
            echo "${CHTAG}NAME=${bn%.*}" >> $metadata
            duration=$(ffprobe -i "$var" -show_entries format=duration -v quiet -of csv="p=0")
            START=$(python -c "print $START+$duration")
            CHNO=$((CHNO+1))
        done
    fi

    # Ask user to manually verify metadata
    moveon='N'
    while [ "$moveon" == 'N' ]; do
        if [ ! $no_encode ]; then
            clear
            echo "---------------------------"
            cat $metadata
            echo "---------------------------"
            echo -n 'Edit this metadata? [y/N] '
            read editmetadata
            case $editmetadata in
                'Y'|'y'|[yY][eE][sS] )
                    edit $metadata
                    ;;
                * )
                    moveon='Y'
                    ;;
            esac
        else
            moveon='Y'
        fi
    done
fi

# Verify output locations:
author=$(get_tag_val "$1" 'artist')
title=$(get_tag_val "$1" 'album')
dest="$(destination "$author" "$title" |  sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
base="$(echo $title |  sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

moveon='N'
while [ "$moveon" == 'N' ]; do
    echo ''
    echo 'Outputs:'
    if [ ! $no_encode ]; then echo "$dest/$base.ogg"; fi
    if [ ! $no_cover ]; then echo "$dest/cover.jpg"; fi
    if [ ! $no_transcript ]; then echo "$dest/transcript.txt"; fi
    echo ''
    echo -n 'Modify outputs ("No" will initiate processing) [y/N] '
    read yesno
    case $yesno in
        'y'|'Y'|[yY][eE][sS] )
            echo -n "Enter directory name [$dest]: "
            read tmpdest
            if [ "$tmpdest" ]; then dest="$tmpdest"; fi
            if [ ! $no_encode ]; then
                echo -n "Enter Basename [$base]: "
                read tmpbase
                if [ "$tmpbase" ]; then base="$tmpbase"; fi
            fi
            ;;
        * )
            moveon='Y'
            ;;
    esac
done

## BEGIN PROCESSING

mkdir -p "$dest"

# Download cover
if [ ! $no_cover ]; then
    if ls "$dest"/cover* 1> /dev/null 2>&1; then
        echo "Cover already exists. Skipping."
    else
        echo -n "Cover URL: "
        read coverurl
        coverext=${coverurl##*.}
        curl "$coverurl" > "$dest/cover.$coverext"
    fi
fi


# Encode
if [ ! $no_encode ]; then
    echo "Compressing to ogg/opus"
    $FFMPEG -i "$input" -i "$metadata" -map_metadata 1 -vn -c:a libopus -b:a 24k -ac 1 "$dest/$base.ogg"
fi

# Transcribe:
if [ ! $no_transcript ]; then
    if [ -f "$dest/transcript.txt" ]; then
        echo "Skipping transcription. Destination file is newer than source."
    else
        echo "Transcribing."
        tmpwav=$(mktemp --suffix='.wav')
        add_cleanup rm -f $tmpwav
        $FFMPEG -i "$input" -vn -ar 16k -ac 1 -y $tmpwav
        transcribe $tmpwav > "$dest/transcript.txt"
    fi
fi

