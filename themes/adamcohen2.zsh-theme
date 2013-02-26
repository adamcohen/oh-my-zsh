###
# See if we can use colors.
autoload colors zsh/terminfo
if [[ "$terminfo[colors]" -ge 8 ]]; then
    colors
fi
for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE GREY; do
    eval PR_BOLD_$color='%{$terminfo[bold]$fg[${(L)color}]%}'
    eval PR_$color='%{$terminfo[sgr0]$fg[${(L)color}]%}'
    (( count = $count + 1 ))
done
PR_NO_COLOUR="%{$terminfo[sgr0]%}"

################################################################

# kcbanner's zshrc file v0.1, based on:
# jdong's zshrc file v0.2.1 and
# mako's zshrc file, v0.1

setopt ALL_EXPORT

# Set/unset  shell options
setopt   notify globdots correct pushdtohome cdablevars autolist
setopt   correctall recexact longlistjobs nohup incappendhistory sharehistory
setopt   histignoredups pushdsilent menucomplete
setopt   autopushd pushdminus extendedglob 
unsetopt bgnice autoparamslash

PAGER='less'
TERM="xterm-256color"

LC_ALL='en_US.UTF-8'
LANG='en_US.UTF-8'
LC_CTYPE=C

unsetopt ALL_EXPORT
alias yaourt="color='' yaourt"
alias man='LC_ALL=C LANG=C man'

alias =clear
autoload -U compinit
compinit

bindkey "^r" history-incremental-search-backward
bindkey '^I' complete-word # complete on tab, leave expansion to _expand

################################################################

# vcs_info init
autoload -Uz vcs_info
 
zstyle ':vcs_info:*' stagedstr '%F{28}●'
zstyle ':vcs_info:*' unstagedstr '%F{11}●'
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b%F{1}:%F{11}%r'
zstyle ':vcs_info:*' enable git svn

# function precmd() {
    # export PROMPT="%{$GREY%}%n@%m%{$BLACK%}:%{$GREEN%}%~%{$YELLOW%}$(parse_git_branch)%{$BLACK%}%# "
# }

function precmd {

    local TERMWIDTH
    (( TERMWIDTH = ${COLUMNS} - 1 ))


    if [[ -z $(git ls-files --other --exclude-standard 2> /dev/null) ]] {
        zstyle ':vcs_info:*' formats "$PR_BOLD_YELLOW%b%c%u"
    } else {
        zstyle ':vcs_info:*' formats "$PR_BOLD_YELLOW%b%c%u$PR_RED●"
    }
    vcs_info
    if [ -z $vcs_info_msg_0_ ]; then
        vcs_info_msg_0_="$PR_BOLD_YELLOW%D{%a,%b %d}"
    fi
 

    ###
    # Truncate the path if it's too long.
    
    PR_FILLBAR=""
    PR_PWDLEN=""
    
    local promptsize=${#${(%):---(%n@%m)---()--}}
    local pwdsize=${#${(%):-%~}}
    
    if [[ "$promptsize + $pwdsize" -gt $TERMWIDTH ]]; then
        ((PR_PWDLEN=$TERMWIDTH - $promptsize))
    else
        PR_FILLBAR="\${(l.(($TERMWIDTH - ($promptsize + $pwdsize)))..${PR_HBAR}.)}"
    fi
}


setopt extended_glob
preexec () {
    if [[ "$TERM" == "screen" ]]; then
        local CMD=${1[(wr)^(*=*|sudo|-*)]}
        echo -n "\ek$CMD\e\\"
    fi
}

setprompt () {
    ###
    # Need this so the prompt will work.
    setopt prompt_subst

    ###
    # See if we can use extended characters to look nicer.
    typeset -A altchar
    set -A altchar ${(s..)terminfo[acsc]}
    PR_SET_CHARSET="%{$terminfo[enacs]%}"
    PR_SHIFT_IN="%{$terminfo[smacs]%}"
    PR_SHIFT_OUT="%{$terminfo[rmacs]%}"
    # PR_HBAR=${altchar[q]:--}
    PR_HBAR=' '
    PR_ULCORNER=${altchar[l]:--}
    PR_LLCORNER=${altchar[m]:--}
    PR_LRCORNER=${altchar[j]:--}
    PR_URCORNER=${altchar[k]:--}

    
    ###
    # Decide if we need to set titlebar text.
    case $TERM in
    xterm*)
        PR_TITLEBAR=$'%{\e]0;%(!.-=*[ROOT]*=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\a%}'
        ;;
    screen)
        PR_TITLEBAR=$'%{\e_screen \005 (\005t) | %(!.-=[ROOT]=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\e\\%}'
        ;;
    *)
        PR_TITLEBAR=''
        ;;
    esac
    
    
    ###
    # Decide whether to set a screen title
    if [[ "$TERM" == "screen" ]]; then
        PR_STITLE=$'%{\ekzsh\e\\%}'
    else
        PR_STITLE=''
    fi
    
    ###
    # Finally, the prompt.

    PROMPT='
$PR_SET_CHARSET$PR_STITLE${(e)PR_TITLEBAR}\
$PR_BOLD_GREY$PR_SHIFT_IN$PR_ULCORNER$PR_HBAR$PR_SHIFT_OUT(\
$PR_BOLD_MAGENTA%$PR_PWDLEN<...<%~%<<\
$PR_BOLD_GREY)$PR_SHIFT_IN$PR_HBAR$PR_BOLD_GREY$PR_HBAR${(e)PR_FILLBAR}$PR_HBAR$PR_SHIFT_OUT(\
$PR_BOLD_GREEN%(!.%SROOT%s.%n)@%m\
$PR_BOLD_GREY)$PR_SHIFT_IN$PR_HBAR$PR_BOLD_GREY$PR_URCORNER$PR_SHIFT_OUT\

$PR_BOLD_GREY$PR_SHIFT_IN$PR_LLCORNER$PR_HBAR$PR_SHIFT_OUT(\
%(?..$PR_RED%?$PR_BOLD_GREY:)\
$PR_BOLD_YELLOW%D{%H:%M}\
$PR_BLUE:%(!.$PR_RED.$PR_WHITE)%#$PR_BOLD_GREY)$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
$PR_BOLD_GREY$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
$PR_NO_COLOUR '

    RPROMPT=' $PR_BOLD_GREY$PR_SHIFT_IN$PR_HBAR$PR_HBAR$PR_SHIFT_OUT\
(${vcs_info_msg_0_}$PR_BOLD_GREY)$PR_SHIFT_IN$PR_HBAR$PR_BOLD_GREY$PR_LRCORNER$PR_SHIFT_OUT$PR_NO_COLOUR'

    PS2='$PR_BOLD_GREY$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
$PR_BLUE$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT(\
$PR_GREEN%_$PR_BLUE)$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
$PR_BOLD_GREY$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT$PR_NO_COLOUR '
}

setprompt
