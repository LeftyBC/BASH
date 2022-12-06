#!/usr/bin/env bash

# pass a date like "Dec 12 2022" or "Dec 12 2022 04:00:00"
target=$(date --date "$*" +%s)
_start=$(date +%s)

_origseconds=$(( ${target} - ${_start} ))

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
    if [[ "$days" -gt 0 ]]; then
        daystr="[${days} days] "
    fi

    printf -v line "%s%s%02dh:%02dm:%02d%s (%02d%%) \\r" "$COLOR" "$daystr" "$hours" "$minutes" "$seconds" "$CLEAR" "$pctleft"

	print_center "$line"
}

trap 'check_terminal_size' WINCH

clear
echo ""
while true; do
    countdown
    for i in {1..9}; do sleep 0.1; done
done
