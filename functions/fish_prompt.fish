# Set these options in your config.fish (if you want to :])
#
#     set -g theme_display_user yes
#     set -g theme_hostname never
#     set -g theme_hostname always
#     set -g default_user your_normal_user

#
# Segments functions
#
set -g current_bg NONE
set -g segment_separator \uE0B0

function __prompt_segment -d "Function to draw a segment"
  set -l bg
  set -l fg
  if [ -n "$argv[1]" ]
    set bg $argv[1]
  else
    set bg normal
  end
  if [ -n "$argv[2]" ]
    set fg $argv[2]
  else
    set fg normal
  end
  if [ "$current_bg" != 'NONE' -a "$argv[1]" != "$current_bg" ]
    set_color -b $bg
    set_color $current_bg
    echo -n "$segment_separator "
    set_color -b $bg
    set_color $fg
  else
    set_color -b $bg
    set_color $fg
    echo -n " "
  end
  set current_bg $argv[1]
  if [ -n "$argv[3]" ]
    echo -n -s $argv[3] " "
  end
end

function __prompt_finish -d "Close open segments"
  if [ -n $current_bg ]
    set_color -b normal
    set_color $current_bg
    echo -n "$segment_separator "
  end
  set_color normal
  set -g current_bg NONE
end


#
# Components
#
function __prompt_virtual_env -d "Display Python virtual environment"
  if test "$VIRTUAL_ENV"
    set env (basename $VIRTUAL_ENV)
    __prompt_segment white black "🐍 $env"
  end
end


function __prompt_user -d "Display current user if different from $default_user"
  set -l BG 444444
  set -l FG BCBCBC

  if [ "$theme_display_user" = "yes" ]
    if [ "$USER" != "$default_user" -o -n "$SSH_CLIENT" ]
      set USER (whoami)
      __prompt_hostname
      if [ $HOSTNAME_PROMPT ]
        set USER_PROMPT $USER@$HOSTNAME_PROMPT
      else
        set USER_PROMPT $USER
      end
      __prompt_segment $BG $FG $USER_PROMPT
    end
  else
    __prompt_hostname
    if [ $HOSTNAME_PROMPT ]
      __prompt_segment $BG $FG $HOSTNAME_PROMPT
    end
  end
end

function __prompt_hostname -d "Set current hostname to prompt variable $HOSTNAME_PROMPT if connected via SSH"
  set -g HOSTNAME_PROMPT ""
  if [ "$theme_hostname" = "always" -o \( "$theme_hostname" != "never" -a -n "$SSH_CLIENT" \) ]
    set -g HOSTNAME_PROMPT (hostname)
  end
end


function __prompt_dir -d "Display the current directory"
  __prompt_segment 1C1C1C FFFFFF (prompt_pwd)
end


function __prompt_hg -d "Display mercurial state"
  set -l branch
  set -l state
  if command hg id >/dev/null 2>&1
    if command hg prompt >/dev/null 2>&1
      set branch (command hg prompt "{branch}")
      set state (command hg prompt "{status}")
      set branch_symbol \uE0A0
      if [ "$state" = "!" ]
        __prompt_segment red white "$branch_symbol $branch ±"
      else if [ "$state" = "?" ]
          __prompt_segment yellow black "$branch_symbol $branch ±"
        else
          __prompt_segment green black "$branch_symbol $branch"
      end
    end
  end
end

function __prompt_git_operation_branch_detached_bare -d 'prompt_git helper, returns the current Git operation, branchdetached, and bare repo'
   # This function is passed the full repo_info array
    set -l git_dir $argv[1]
    set -l inside_gitdir $argv[2]
    set -l bare_repo $argv[3]
    set -q argv[5]
    and set -l sha $argv[5]

    set -l branch
    set -l operation
    set -l detached false
    set -l bare
    set -l step
    set -l total

    if test -d $git_dir/rebase-merge
        set branch (cat $git_dir/rebase-merge/head-name 2>/dev/null)
        set step (cat $git_dir/rebase-merge/msgnum 2>/dev/null)
        set total (cat $git_dir/rebase-merge/end 2>/dev/null)
        if test -f $git_dir/rebase-merge/interactive
            set operation "|REBASE-i"
        else
            set operation "|REBASE-m"
        end
    else
        if test -d $git_dir/rebase-apply
            set step (cat $git_dir/rebase-apply/next 2>/dev/null)
            set total (cat $git_dir/rebase-apply/last 2>/dev/null)
            if test -f $git_dir/rebase-apply/rebasing
                set branch (cat $git_dir/rebase-apply/head-name 2>/dev/null)
                set operation "|REBASE"
            else if test -f $git_dir/rebase-apply/applying
                set operation "|AM"
            else
                set operation "|AM/REBASE"
            end
        else if test -f $git_dir/MERGE_HEAD
            set operation "|MERGING"
        else if test -f $git_dir/CHERRY_PICK_HEAD
            set operation "|CHERRY-PICKING"
        else if test -f $git_dir/REVERT_HEAD
            set operation "|REVERTING"
        else if test -f $git_dir/BISECT_LOG
            set operation "|BISECTING"
        end
    end

    if test -n "$step" -a -n "$total"
        set operation "$operation $step/$total"
    end

    if test -z "$branch"
        if not set branch (command git symbolic-ref HEAD 2>/dev/null)
            set detached true
            set branch (switch "$__fish_git_prompt_describe_style"
                                                case contains
                                                        command git describe --contains HEAD
                                                case branch
                                                        command git describe --contains --all HEAD
                                                case describe
                                                        command git describe HEAD
                                                case default '*'
                                                        command git describe --tags --exact-match HEAD
                                                end 2>/dev/null)
            if test $status -ne 0
                # Shorten the sha ourselves to 8 characters - this should be good for most repositories,
                # and even for large ones it should be good for most commits
                # No need for an ellipsis.
                if set -q sha
                    set branch (string shorten -m8 -c "" -- $sha)
                else
                    set branch unknown
                end
            end
            set branch "($branch)"
        end
    end

    if test true = $inside_gitdir
        if test true = $bare_repo
            set bare "BARE:"
        else
            # Let user know they're inside the git dir of a non-bare repo
            set branch "GIT_DIR!"
        end
    end

    echo $operation
    echo $branch
    echo $detached
    echo $bare
end

function __prompt_git -d "Display the current git state"
  set -l ref
  set -l repo_info (command git rev-parse --git-dir --is-inside-git-dir --is-bare-repository --is-inside-work-tree HEAD 2>/dev/null)
  test -n "$repo_info"
  or return

  set -l git_dir $repo_info[1]
  set -l inside_gitdir $repo_info[2]
  set -l bare_repo $repo_info[3]
  set -l inside_worktree $repo_info[4]
  set -q repo_info[5]
  and set -l sha $repo_info[5]
  
  set -l obdb (__prompt_git_operation_branch_detached_bare $repo_info)
  set -l op $obdb[1] # current operation
  set -l branch $obdb[2] # current branch
  set -l detached $obdb[3]
  set -l bare_repo $obdb[4] # bare repository

  set -l op_in_progress true
  test -n "$op"; or set op_in_progress false

  if test true = $inside_worktree
    if test true = $detached
      set branch_symbol "➦"
    else
      set branch_symbol \uE0A0
      set branch (string replace refs/heads/ '' -- $branch)
    end

    set -l PROMPT_BRANCH
    set -l dirty (command git status --porcelain --ignore-submodules=dirty 2> /dev/null)

    if test -z "$dirty"
      set BG green
      set PROMPT_BRANCH "$branch_symbol $branch"
    else
      set BG yellow
      set dirty ''

      if test true = $bare_repo
        # The repo is empty
        set target '4b825dc642cb6eb9a060e54bf8d69288fbee4904'
      else
        # The repo is not empty
        set target 'HEAD'

        # Check for unstaged change only when the repo is not empty
        set -l unstaged 0
        git diff --no-ext-diff --ignore-submodules=dirty --quiet --exit-code; or set unstaged 1
        if [ $unstaged = 1 ]; set dirty $dirty'●'; end
      end

      # Check for staged change
      set -l staged 0
      git diff-index --cached --quiet --exit-code --ignore-submodules=dirty $target; or set staged 1
      if [ $staged = 1 ]; set dirty $dirty'✚'; end

      if test false = "$dirty"
        set PROMPT_BRANCH "$branch_symbol $branch"
      else
        set PROMPT_BRANCH "$branch_symbol $branch $dirty"
      end
    end

    __prompt_segment $BG black $PROMPT_BRANCH 
    if test true = "$op_in_progress"
      set -l PROMPT_OP (string replace '|' "" -- $op)
      __prompt_segment yellow black $PROMPT_OP
    end
  end
end


function __prompt_svn -d "Display the current svn state"
  set -l ref
  if command svn ls . >/dev/null 2>&1
    set branch (svn_get_branch)
    set branch_symbol \uE0A0
    set revision (svn_get_revision)
    __prompt_segment green black "$branch_symbol $branch:$revision"
  end
end

function svn_get_branch -d "get the current branch name"
  svn info 2> /dev/null | awk -F/ \
      '/^URL:/ { \
        for (i=0; i<=NF; i++) { \
          if ($i == "branches" || $i == "tags" ) { \
            print $(i+1); \
            break;\
          }; \
          if ($i == "trunk") { print $i; break; } \
        } \
      }'
end

function svn_get_revision -d "get the current revision number"
  svn info 2> /dev/null | sed -n 's/Revision:\ //p'
end


function __prompt_status -d "the symbols for a non zero exit status, root and background jobs"
    if [ $RETVAL -ne 0 ]
      __prompt_segment black red "$RETVAL"
    end

    # if superuser (uid == 0)
    set -l uid (id -u $USER)
    if [ $uid -eq 0 ]
      __prompt_segment black yellow "☣️"
    end

    # Jobs display
    if [ (jobs -l | wc -l) -gt 0 ]
      __prompt_segment black cyan "⚙"
    end
end

function __prompt_opam_switch -d "Display active opam's installation"
  if test "$OPAM_SWITCH_PREFIX"
    set env (basename $OPAM_SWITCH_PREFIX)
    __prompt_segment white black "🐫 $env"
  end
end

#
# Prompt
#
function fish_prompt
  set -g RETVAL $status
  __prompt_status
  __prompt_opam_switch
  __prompt_virtual_env
  __prompt_user
  __prompt_dir
  type -q hg;  and __prompt_hg
  type -q git; and __prompt_git
  type -q svn; and __prompt_svn
  __prompt_finish
end
