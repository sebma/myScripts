#!/usr/bin/env ksh

ytgetRestrictedFilenamesHD () 
{ 
    youtube_dl=$(which youtube-dl)
    youtubeURLPrefix=https://www.youtube.com/watch?v=
    dailymotionURLPrefix=https://www.dailymotion.com/video/
    format="mp4"
    for url in "$@"
    do
        if echo $url | \egrep -vq "www"; then
            if $youtube_dl -e $youtubeURLPrefix$url > /dev/null 2>&1; then
                url=$youtubeURLPrefix$url
            else
                if $youtube_dl -e $dailymotionURLPrefix$url > /dev/null 2>&1; then
                    url=$dailymotionURLPrefix$url
                fi
            fi
        fi
        if echo $url | \egrep -q "youtube|tv2vie"; then
            format=22
        else
            if echo $url | grep --color=auto -q dailymotion; then
                format=hd
            fi
        fi
        echo "=> url = $url"
        echo
        fileName=$($youtube_dl -f $format --get-filename "$url" --restrict-filenames || $youtube_dl --get-filename "$url" --restrict-filenames)
        echo "=> fileName= <$fileName>"
        echo
        if [ -f "$fileName" ] && [ ! -w "$fileName" ]; then
            echo "$greenOnBlue=> The file $fileName is already downloaded, skipping ...$normal" 1>&2
            echo
            continue
        fi
        $youtube_dl --embed-thumbnail -f $format "$url" --restrict-filenames || $youtube_dl --embed-thumbnail "$url" --restrict-filenames || continue
        mp4tags -m "$url" "$fileName"
        chmod -w "$fileName"
        echo
        mp4info "$fileName"
        echo
    done
    \rm -v *.description
    sync
}

ytgetRestrictedFilenamesHD $@
