#!/usr/bin/env bash

# Dependencies
# - ORG env variable: root for searching .org files
# - grep

###########
# helpers #
###########

orgscript_grep() {
    local REGEX="(?s)#\+begin_src\b[ a-z:]+\bbash\b[ a-z:]+:script +${NAME}\b[^\n]*\n.*?#\+end_src"
    grep --include=*.org --exclude-dir=.git -Pzoirh "$REGEX" "$ORG" |
        cut -z -d '' -f 1 | # exctract first script
        tr '\0' '\n'        # replace final null with newline
}

# UNUSED
orgscript_rg() { # ripgrep alternative to orgscript_grep
    local REGEX="(?s)#\+begin_src (bash +:script +${1}\b.*?)#\+end_src"
    rg -UINioP -r '$1' --multiline-dotall --color=never -g '*.org' "$REGEX" "$2"
}

############
# commands #
############

# output script content to stdout, including org block markers (#+begin_src .., #+end_src)
orgscript_get() {
    local NAME="${1}"
    [[ -z "$NAME" ]] && echo '!! orgscript: script name not given' && return 1
    orgscript_grep "$NAME" "$ORG"
}
orgscript_run() {
    orgscript_get "$1" | bash -si
}


# list all org scripts
orgscript_list() {
    grep --include=*.org --exclude-dir=.git -Pnoir '#\+begin_src\b.+\bbash\b.+:script +\K\w+\b' "$ORG" |
        awk -F: '{print $3 "\t" $1 ":" $2 }' |
        {
            if [[ dumb = "$TERM" ]]; then
                echo 'org scripts:'
                while read line path num; do echo "  - $line, defined in $path:$num"; done
            else
                fzf | cut -f 1 | orgscript_run "$(cat -)"
            fi
        }
}

########
# main #
########

CMD="$1"
shift
case "$CMD" in
    help ) cat <<-EOF
	orgscript - Execute scripts from source blocks of your org files.

	Usage: orgscript COMMAND

	Available commands:
	  help                     Print this help message
	  list, ls                 List available scripts
	  show                     Show source code for a script
	  <script name>            Execute script with name
	EOF
      ;;
    '' | ls | list ) orgscript_list ;;
    show ) orgscript_get "$1" ;;
    * ) orgscript_get "$CMD" | bash -s -- "$@" ;;
esac
