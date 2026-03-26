#!/usr/bin/env bash

###
# some colorized echo helpers
# @author Thomas Letsch Groch
###

# Colors
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"

function ok() {
    echo -e "$COL_GREEN[ok]$COL_RESET "$1
}

function bot() {
    echo -e "\n$COL_GREEN \[._.]/$COL_RESET - "$1
}

function running() {
    echo -en "\n$COL_BLUE ⇒ $1$COL_RESET\n"
}

function action() {
    echo -en "\n$COL_CYAN ⇒ $1$COL_RESET\n"
}

function warn() {
    echo -e "$COL_YELLOW[warning] $1 $COL_RESET"
}

function error() {
    echo -e "$COL_RED[error]\n ⇒ $1 $COL_RESET"
}
