# abarchive
Organize audiobooks
 
This script archives audiobooks to compressed ogg/opus files. It accepts Audible (.aax) files,
as well as generic audio files (mp3, m4b, wav, etc). It preserves embedded chapter metadata
from single files, or generates it based on file breaks.

It has the ability to de-DRM Audible books if you have your user's "activation bytes".
I should point out here that I am not encouraging copyright infringement; this functionality
is intended to provide a means of compressing, and archiving audiobooks only. I think it
is important to have choice when it comes to how you listen to audiobooks and DRM infringes
on that ability.

It can also transcribe audiobooks to plain text files with Pocket Sphinx speech to text engine.
This is useful for finding your place in an audiobook if you lost your bookmark. The speech recognition
is mediocre at best, but it does enable you to do crude searches through your audio files with
embedded ~1 minute timestamps.

**Note:** These variables are useful.
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
