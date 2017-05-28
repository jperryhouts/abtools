# abarchive
Organize audiobooks
 
This script archives audiobooks to compressed ogg/opus files. It accepts Audible (.aax) files,
as well as generic audio files (mp3, m4b, wav, etc). By default it will concatenate input files
into one output. It preserves embedded chapter metadata from single files, or generates chapter
metadata based on file breaks if multiple input files are given.

It has the ability to de-DRM Audible books if you have your user's "activation bytes".
I should point out here that I am not encouraging copyright infringement; this functionality
is intended to provide a means of compressing, and archiving audiobooks only. I think it
is important to have choice when it comes to how you listen to audiobooks and DRM infringes
on that ability.

It can also transcribe audiobooks to plain text files with CMU's PocketSphinx speech-to-text engine.
This is useful for finding your place in an audiobook if you lost your bookmark. The speech recognition
is mediocre at best, but it does enable you to do crude searches through your audio files with
embedded ~1 minute timestamps.

# Usage
```
    abarchiver

    NAME
        abarchiver -- Archive audio books from Audible or elsewhere

    SYNOPSIS
        Usage: abarchiver [ OPTIONS ] input_file(s)

    OPTIONS
        --no-encode       Do not produce encoded audiobook.
        --no-cover        Do not download cover image.
        --no-transcript   Do not transcribe audiobook.
        --key,-k KEY      Audible key
        --sphinx exe      PocketSphinx executable
        --hmm HMM         Hidden Markov Model
        --lm LM           Language Model

    EXAMPLES
        abarchiver AudioBookUnabridged.aax
        abarchiver --no-transcript AudioBook1_librivox.m4b
        abarchiver ./book-chapter*.mp3
```

# Configuration
The script works out of the box, but these variables are useful.
Define them in `~/.config/.abarchiver.rc` or on the command line
(command line options override config file):
```
    KEY='AUDIBLE KEY ("Actvation bytes")'
    DEST='Default output directory' (defaults to $HOME)
    POCKETSPHINX='PocketSphinx executable'
    POCKETSPHINX_POSTPROCESS='pipe pocketsphinx output'
                (Defaults to 'python ./pocketsphinx_filter.py')
    HMM='Hidden Markov Model'
    LM='Language Model'
```

# Example
<pre>
$ <b>wget https://archive.org/download/walden_librivox/WaldenPart1_librivox.m4b</b>
$ <b>abarchiver.sh WaldenPart1_librivox.m4b</b>
---------------------------
;FFMETADATA1
title=Walden
album=Walden
artist=thoreau_henry_david
album_artist=thoreau_henry_david
genre=Audiobook
CHAPTER01=00:00:0.000
CHAPTER01NAME=walden_c01 part 1
CHAPTER02=00:30:16.008
CHAPTER02NAME=walden_c01 part 2
CHAPTER03=01:08:52.003
CHAPTER03NAME=walden_c01 part 3
CHAPTER04=02:07:50.020
CHAPTER04NAME=walden_c01 part 4
CHAPTER05=02:54:16.017
CHAPTER05NAME=walden_c01 part 5
CHAPTER06=03:17:42.020
CHAPTER06NAME=walden_c02 part 1
CHAPTER07=03:45:1.019
CHAPTER07NAME=walden_c02 part 2
CHAPTER08=04:10:51.022
CHAPTER08NAME=walden_c03
CHAPTER09=04:46:45.006
CHAPTER09NAME=walden_c04
CHAPTER10=05:37:9.007
CHAPTER10NAME=walden_c05
CHAPTER11=06:09:7.004
CHAPTER11NAME=walden_c06
CHAPTER12=06:42:33.003
CHAPTER12NAME=walden_c07
---------------------------
Edit this metadata? [y/N] <b>Y [ENTER]</b>

<b>[EDIT METADATA AS A FILE]</b>

---------------------------
;FFMETADATA1
title=Walden
album=Walden
artist=Henry David Thoreau
album_artist=Henry David Thoreau
genre=Audiobook
CHAPTER01=00:00:0.000
CHAPTER01NAME=Chapter 01 Part 1
CHAPTER02=00:30:16.008
CHAPTER02NAME=Chapter 01 Part 2
CHAPTER03=01:08:52.003
CHAPTER03NAME=Chapter 01 Part 3
CHAPTER04=02:07:50.020
CHAPTER04NAME=Chapter 01 Part 4
CHAPTER05=02:54:16.017
CHAPTER05NAME=Chapter 01 Part 5
CHAPTER06=03:17:42.020
CHAPTER06NAME=Chapter 02 Part 1
CHAPTER07=03:45:1.019
CHAPTER07NAME=Chapter 02 Part 2
CHAPTER08=04:10:51.022
CHAPTER08NAME=Chapter 03
CHAPTER09=04:46:45.006
CHAPTER09NAME=Chapter 04
CHAPTER10=05:37:9.007
CHAPTER10NAME=Chapter 05
CHAPTER11=06:09:7.004
CHAPTER11NAME=Chapter 06
CHAPTER12=06:42:33.003
CHAPTER12NAME=Chapter 07
---------------------------
Edit this metadata? [y/N] <b>N [ENTER]</b>

Outputs:
/home/user/Audiobooks/Henry David Thoreau - Walden/Walden.ogg
/home/user/Audiobooks/Henry David Thoreau - Walden/cover.jpg
/home/user/Audiobooks/Henry David Thoreau - Walden/transcript.txt

Modify outputs ("No" will initiate processing) [y/N] <b>N [ENTER]</b>

Cover URL: <b>http://archive.org/download/walden_librivox/Walden_1105.jpg</b>

... diagnostics ...
</pre>
