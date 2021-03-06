# Source nix stuff on systems other than NixOS
if [ -f /etc/profile.d/nix.sh ]; then
  . /etc/profile.d/nix.sh
fi

# Deactivate tty flow control (e.g. suspending with ctlr-s and resuming with ctrl-q)
stty -ixon

# https://github.com/NixOS/nixpkgs/issues/30121
setopt prompt_sp

# pdflatex breaks its error output by default (WTF)
export max_print_line=1000

# because otherwise tmux starts in bash (?!).
# tmux's default-shell doesn't work because we don't have zsh's path
export SHELL=$(which zsh)
export PATH=$HOME/.stack/bin:$HOME/.cabal/bin:/opt/ghc/bin:/opt/cabal/bin:$PATH
export MANPATH=/nix/var/nix/profiles/default/share/man:$HOME/.nix-profile/share/man:$MANPATH

bindkey -v
bindkey '^R' history-incremental-search-backward
bindkey '^P' history-beginning-search-backward
bindkey '^N' history-beginning-search-forward

# Make Ctrl+arrow, Pos1, End, Del, Ins work

# create a zkbd compatible hash;
# to add other keys to this hash, see: man 5 terminfo
typeset -g -A key

key[Home]="$terminfo[khome]"
key[End]="$terminfo[kend]"
key[Insert]="$terminfo[kich1]"
key[Backspace]="$terminfo[kbs]"
key[Delete]="$terminfo[kdch1]"
key[Up]="$terminfo[kcuu1]"
key[Down]="$terminfo[kcud1]"
key[Left]="$terminfo[kcub1]"
key[Right]="$terminfo[kcuf1]"
key[PageUp]="$terminfo[kpp]"
key[PageDown]="$terminfo[knp]"

# setup key accordingly
[[ -n "$key[Home]"      ]] && bindkey -- "$key[Home]"      beginning-of-line
[[ -n "$key[End]"       ]] && bindkey -- "$key[End]"       end-of-line
[[ -n "$key[Insert]"    ]] && bindkey -- "$key[Insert]"    overwrite-mode
[[ -n "$key[Backspace]" ]] && bindkey -- "$key[Backspace]" backward-delete-char
[[ -n "$key[Delete]"    ]] && bindkey -- "$key[Delete]"    delete-char
[[ -n "$key[Up]"        ]] && bindkey -- "$key[Up]"        up-line-or-history
[[ -n "$key[Down]"      ]] && bindkey -- "$key[Down]"      down-line-or-history
[[ -n "$key[Left]"      ]] && bindkey -- "$key[Left]"      backward-char
[[ -n "$key[Right]"     ]] && bindkey -- "$key[Right]"     forward-char

# These still aren't bound and not present in $terminfo
bindkey "^[[1;5D" backward-word # Ctrl-Left
bindkey "^[[1;5C" forward-word  # Ctrl-Right

# Finally, make sure the terminal is in application mode when zle is
# active. Only then are the values from $terminfo valid.
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
  function zle-line-init () {
    echoti smkx
  }
  function zle-line-finish () {
    echoti rmkx
  }
  zle -N zle-line-init
  zle -N zle-line-finish
fi

function test_exec() {
  command -v $1 > /dev/null
}

# Rebuild config and launch tmux if not already in some mux session,
# before setting any aliases
if [ "x$USE_TMUX" = "xyes" ] && test_exec tmux && [[ ! $TERM =~ screen-256colors && -z $TMUX ]]; then
  home-manager switch
  # -u (only applicable to tmux, not to new-session): Force UTF-8
  # -s root: Name the new session "root"
  # -n main: Name the initial window "main"
  # -c $(pwd): Set the initial directory to the pwd of the current zsh session
  tmux -u new-session -s root -n main -c $(pwd)
  # -u (only applicable to tmux, not to attach-session): Force UTF-8
  # -t root: attach to the root session
  # -d: detach other clients.
  tmux -u attach-session -d -t root
fi

# An alias for quietly forking to background:
alias -g zzz='>/dev/null 2>&1 &!'
# We need -g (and thus use it here), otherwise it won't expand in postfix position

# Making and changing into a directory:
function mkcd() {
  mkdir -p $@;
  cd $@;
}

# An alias for a quiet xdg-open
function o() {
  xdg-open $@ zzz
}

# Returns the nix store path of the given executable by stripping of the bin/blah suffix
function nix-which() {
  echo "$(dirname $(dirname $(readlink -f $(which $1))))"
}

# Not FuZzy, but EXact
alias exf=fzf --exact

# Use fzf to find a file
function efd() {
  f=$(exf --query $1)
  ret=$?
  if (( $ret != 0 )); then
    return $ret
  fi
  $EDITOR $f
}

function cpfd() {
  f=$(exf --query $1)
  ret=$?
  if (( $ret != 0 )); then
    return $ret
  fi
  cp $f $2
}

# Prepare a new testcase and open it in $EDITOR
function ntc() {
cat << EOF > $1
-- {-# OPTIONS_GHC -Wincomplete-patterns -fforce-recomp #-}
-- {-# OPTIONS_GHC -O2 -fforce-recomp #-}
-- {-# LANGUAGE PatternSynonyms #-}
-- {-# LANGUAGE BangPatterns #-}
-- {-# LANGUAGE MagicHash, UnboxedTuples #-}
module Lib where

EOF
$EDITOR $1
}

function ncpus() {
  grep -c ^processor /proc/cpuinfo
}

# $1: search regex
# $2: replacement
# $3: where
function rg-sed() {
  rg --files-with-matches $1 $3 | xargs sed -i "s/$1/$2/g"
}

function is_git_dir() {
  git -C $1 rev-parse --is-inside-work-tree > /dev/null 2>&1
}

# See which git branch is checked out in each of the current sub-dirs.
function lsg() {
  function modified_indicator() {
    if git -C $1 diff --no-ext-diff --quiet --exit-code; then
      echo "✓"
    else
      echo "✗"
    fi
  }
  for d in $(\ls -d */); do
    if is_git_dir $d; then
      printf "%s\t%s\t%s\n" $d $(modified_indicator $d) $(git -C $d branch --show-current)
    fi
  done | column -t -s $'\t'
}

function lsghc() {
  function modified_indicator() {
    if git -C $1 diff --no-ext-diff --quiet --exit-code; then
      echo "✓"
    else
      echo "✗"
    fi
  }
  for d in $(\ls -d */); do
    if is_git_dir $d && [ $(git -C $d remote get-url origin) = "https://gitlab.haskell.org/ghc/ghc.git" ]; then
      printf "%s\t%s\t%s\n" $d $(modified_indicator $d) $(git -C $d branch --show-current)
    fi
  done | column -t -s $'\t'
}

