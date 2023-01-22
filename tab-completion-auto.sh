#!/bin/bash
# [Bash Tab-Completion Automation]
#  This script provides an example how to build a tab completion
#  from a set of user-defined functions automatically.
#  Each function must be defined with a naming pattern to reach
#  to the root function or reach to the target sub-function.
#  The root function is a function that the tab completion begins
#  In this sample script, 'myapp' is the root function for all others.
#  All the sub-functions must start with "__" prefix string
#  and concatenate their ancestor's names using "-" similarly to a path.
#
# [Usage]
#  In order to use the script, please grep and replace all 'myapp' to your function.
#  And then update the sub-functions and their function body.
#

__myapp() { ## help description A
    echo A $*
}

__myapp-secondB() { ## help description A-B
    echo A-B $*
}

__myapp-secondC() { ## help description A-C
    echo A-C $*
}

__myapp-secondD() {
    echo A-D $*
}

__myapp-secondB-thirdX() { ## help description A-B-X
    echo A-B-X $*
}

__myapp-secondB-thirdY() {
    echo A-B-Y $*
}

__myapp-secondC-thirdX() {
    echo A-C-X $*
}

__myapp-secondC-thirdY() {
    echo A-C-Y $*
}

__myapp-secondC-thirdZ() {
    echo A-C-Z $*
}

__myapp-help() {
    # < $__myapp_src grep "^__[A-Za-z0-9\-_]\(\)" | sort | sed 's/__//g; s/() {/|/g' | awk 'BEGIN {FS = "|"}; {printf "\033[36m%-30s\033[0m %s\n", $1, $2}'
    local FUNCS=$(< $__myapp_src grep "^__[A-Za-z0-9\-_]\(\)" | sort | sed 's/() {.*//g; s/__//g')
    for entry in $FUNCS; do
        IFS='-' read -r -a array <<< "$entry"
        echo ${array[@]} $(< $__myapp_src grep "^__"${entry}"()" | sed 's/.*{//') | \
        awk 'BEGIN {FS = "##"}; {printf "\033[36m%-30s\033[0m %s\n", $1, $2}'
    done
}

myapp() {
    local fname="__${FUNCNAME[0]}"
    local _matchargs=$*
    local _matchfname=$fname
    while (($#)); do
        fname="$fname $1"
        fname=${fname//" "/"-"}
        shift
        if [[ $(type -t ${fname}) == function ]]; then
            _matchfname=$fname
            _matchargs=$*
        fi
    done
    # echo matched fname $_matchfname
    # echo matched args $_matchargs
    $_matchfname $_matchargs
}

# Macs have bash3 for which the bash-completion package doesn't include
# _init_completion. This is a minimal version of that function.
__myapp_init_completion()
{
    COMPREPLY=()
    _get_comp_words_by_ref "$@" cur prev words cword
}

__myapp_complete() {
    local CUR FULLNAME FUNCNAMES

    COMPREPLY=()

    # Call _init_completion from the bash-completion package
    # to prepare the arguments properly
    if declare -F _init_completion >/dev/null 2>&1; then
        _init_completion -n "=:" || return
    else
       __myapp_init_completion -n "=:" || return
    fi

    # Find functions and split into words for COMPREPLY
    FULLNAME=${COMP_LINE//" "/"-"}
    FUNCNAMES=$(< $__myapp_src grep "^__$FULLNAME" | sort | sed 's/() {.*//g' | sed 's/__//g')
    COMPREPLY=()
    WORDS=""
    for fname in $FUNCNAMES; do
        IFS='-' read -r -a farray <<< "$fname"
        WORDS="$WORDS ${farray[$COMP_CWORD]}"
    done
    # Match function name parts with current word(part)
    CUR=${COMP_WORDS[COMP_CWORD]}
    declare -la compreply
    compreply=($(compgen -W "$WORDS" -- $CUR))

    # XXX: 9 is initial tab, double-tab is '?' mode or #63
    if [ $COMP_TYPE -eq 9 ]; then
      test ${#compreply} -ne 1 ||
        COMPREPLY=( "${compreply[@]}" )

    elif [ $COMP_TYPE -eq 63 ]; then
      printf "\n *** Enter a command or option: %s\n" "${COMP_LINE[@]}"
      for word in "${compreply[@]}"
      do
        # XXX: not sure why matches are lower-case? no mention of case in GNU
        # html manual
        helpdescr=$(grep -iPo "\\b$word *\\(\\)[{ ]*#+ +\K.+$" "$__myapp_src") &&
          COMPREPLY+=( "$word  ($helpdescr)" ) ||
          COMPREPLY+=( "$word" )
      done
      #test ${#compreply} -ne 1 ||
      #  COMPREPLY=( "${compreply[@]}" )
    fi

    return 0
}

__myapp_src="${PWD}/${BASH_SOURCE[0]#${PWD}/}"

if [[ $(type -t compopt) = "builtin" ]]; then
    complete -o default -F __myapp_complete myapp
else
    complete -o default -o nospace -F __myapp_complete myapp
fi

#
