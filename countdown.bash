#!/usr/bin/env bash

# pass a date like "Dec 12 2022" or "Dec 12 2022 04:00:00"

CLEAR="\e[39m"
RED="\e[31m"
YELLOW="\e[33m"
LIGHTYELLOW="\e[93m"
WHITE="\e[97m"
GREEN="\e[32m"
LIGHTGREEN="\e[92m"
CYAN="\e[36m"

final_command(){
    # change these commands to whatever you want the script to do when it's done
    clear
    echo ""
    print_center "${CYAN}Target has passed!${CLEAR}"
    echo ""
    echo ""

    # beep
    tput bel
}

check_terminal_size(){
    if [[ "$LINES $COLUMNS" != "$PREVL $PREVC" ]]; then
        clear
        echo ""
        countdown
    fi
    PREVL=$LINES
    PREVC=$COLUMNS
}

clear_line(){
    printf "\\r"
    tput el
}

print_center(){
    local x
    local y
    text="$*"
    if [[ "$lastlen" -ne "${#text}" ]]; then
        # clear current line
        clear_line
    fi
    x=$(( ($(tput cols) - ${#text}) / 2))
    echo -ne "\E[6n";read -sdR y; y=$(echo -ne "${y#*[}" | cut -d';' -f1)
    echo -ne "\033[${y};${x}f$*"
    lastlen="${#text}"
}

set_color(){
    _secondsleft=$1
    pctleft=$(( (  ${_secondsleft} * 100 ) / ( ${_origseconds} ) ))

    if [[ "$pctleft" -le 25 ]]; then
        #red
        COLOR="$RED"
        return
    elif [[ "$pctleft" -le 50 ]]; then
        #orange
        COLOR="$YELLOW"
        return
    elif [[ "$pctleft" -le 75 ]]; then
        # yellow
        COLOR="$LIGHTGREEN"
        return
    fi
    # default is white
    COLOR="$WHITE"
}

countdown(){
    local today

    today=$(date +%s)

    if [[ "$target" -lt "$today" ]]; then
        if [[ "x${ONESHOT}" == "x1" ]]; then
            echo "Target has passed"
            exit 0
        fi
        final_command
		# ------------------------------------------------------
        # leave this command so the script exits when it is done
		exit 0
    fi

    totalseconds=$(( $target - $today ))

    set_color $totalseconds

    days=$(( $totalseconds / 86400 ))

    hours=$(( ($totalseconds - ( $days * 86400 )) / 3600 ))

    minutes=$(( ( $totalseconds - ( $days * 86400 ) - ( $hours * 3600 ) ) / 60 ))

    seconds=$(( ( $totalseconds - ( $days * 86400 ) - ( $hours * 3600 ) - ( $minutes * 60 ) ) ))

    daystr=""
    if [[ "$days" -eq 1 ]]; then
        daystr="[1 day] "
    elif [[ "$days" -gt 0 ]]; then
        daystr="[${days} days] "
    fi

    if [[ "x${ONESHOT}" == "x1" ]]; then
        if [[ "x${NOSECONDS}" == "x1" ]]; then
            printf -v line "%s%s%02dh:%02dm%s" "$COLOR" "$daystr" "$hours" "$minutes" "$CLEAR"
        else 
            printf -v line "%s%s%02dh:%02dm:%02d%s" "$COLOR" "$daystr" "$hours" "$minutes" "$seconds" "$CLEAR"
        fi

        echo -ne "$line"
        exit 0
    else
        if [[ "x${NOSECONDS}" == "x1" ]]; then
            printf -v line "%s%s%02dh:%02dm (%02d%%) \\r" "$COLOR" "$daystr" "$hours" "$minutes" "$CLEAR" "$pctleft"
        else
            printf -v line "%s%s%02dh:%02dm:%02d%s (%02d%%) \\r" "$COLOR" "$daystr" "$hours" "$minutes" "$seconds" "$CLEAR" "$pctleft"
        fi

        print_center "$line"
    fi
}

usage(){
    echo "Countdown script - counts down to a specified date" >&2
    echo "" >&2
    echo "Usage: $0 [-o] [-n] [-h] -d <date>" >&2
    echo "" >&2
    echo "-d <date>   date to count down to"
    echo "-n          no seconds in countdown display"
    echo "-o          one-shot mode - print countdown once and then exit" >&2
    echo "-h          this help menu" >&2
    echo "" >&2
}

while getopts 'onhd:' opts; do
    # get cmdline options

    case $opts in
        d) TARGETDATE="${OPTARG}" ;;
        o) ONESHOT=1 ;;
        n) NOSECONDS=1 ;;
        h) usage; exit 2 ;;
    esac
done

if [[ -z "${TARGETDATE}" ]]; then
    echo "No date specified with -d <date>" >&2
    echo "" >&2
    usage
    exit 2
fi

target=$(date --date "$TARGETDATE" +%s)
_start=$(date +%s)

_origseconds=$(( ${target} - ${_start} ))

trap 'check_terminal_size' WINCH

if [[ "x$ONESHOT" == "x1" ]]; then
    # one-shot mode, only display once and then exit
    # useful for running in i3bar, for example
    countdown
    exit 0
fi

# regular, "watch" mode if oneshot isn't specified
clear
echo ""
while true; do
    countdown
    sleep 0.5
    sleep 0.5
done
