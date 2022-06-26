# Workon

Workon is my personal bash script for launching projects. It's existed in my
work flow in some form or another for several years. I've finally decided to
"clean" it up a little and move it to its own repo just in case anyone else out
there finds it useful.

## Description

Workon is a utility script that enables the loading of project specific bash
profiles. This allows the user to avoid repeating themselves every time they
open a new terminal to work on a specific project. It also provides a nice
place to define bash functions for workflow, such as build scripts, test
scripts, and run scripts.

## Installation

Installation is as simple as placing the `.config/workon` directory in your
home directory and adding the following to your `.bashrc` file:
```
export WORKON_DIR="$HOME/.config/workon"
source $WORKON_DIR/workon.sh

# Optional, will add key bindings for workon commands
source $WORKON_DIR/commands.sh
```

### Installing with stow
This project's directory structure allows for installation using
[stow](https://github.com/aspiers/stow), which is an invaluable program I use
for managing my dot files. If you have an existing dot files directory managed
with stow, it is easy to incorporate workon. Example:
```
mkdir -p ~/.dotfiles
git clone https://github.com/ggolish/workon.git ~/.dotfiles/workon
cd .dotfiles
stow workon
```
I manage my dot files in a git repository, and I have added workon as a
submodule to that repository. I've also created another directory in my dot
files directory to store and manage my workon profiles, which allows me to
version control them without committing them to this repository. Here is the
basic structure of my dot files directory:
```
/home/ggolish/.dotfiles/
├── .git
├── workon
│   ├── .config
│   │   └── workon
│   │       ├── commands.sh
│   │       ├── defaults
│   │       ├── .gitignore
│   │       ├── utils
│   │       └── workon.sh
│   ├── .git
│   ├── README.md
│   └── .stow-local-ignore
└── workon-profiles
    └── .config
        └── workon
            └── profiles
```

### Dependencies
The only major dependency is [fzf](https://github.com/junegunn/fzf), which is a
command line fuzzy finder. It is used to prompt the user when choosing a
profile. Another important dependency is [tmux](https://github.com/tmux/tmux).
Without it, you will not be able to use what I find to be the best feature of
workon, launching profiles in tmux sessions. The utilities also have their own
dependencies should you choose to use them in your profiles.

## Usage

The basic workflow for workon is:
    1. Create a profile, if necessary.
    2. Edit the profile, if necessary.
    3. Load the profile, either in the current shell session or in a tmux
       session.
    4. Clean the session, if necessary.

### Creating a profile

A profile is simply a bash script that defines some basic environment variables
and bash functions that workon uses to load the profile. It is also the place
where the user can add their own bash definitions specific to that project. To
create a new profile:
```
workon -n <profile-name>
```
This command will create a new general profile, which will need to be edited
before it does anything useful when launched.

### Editing a profile
Workon will open the profile for editing using the `$EDITOR` environment
variable. To edit a profile:
```
workon -e [profile-name]
```
If the profile name is omitted, workon will prompt for a profile using fzf. For
details about editing profiles, see [Documentation](#Documentation).

### Loading a profile

A profile can be loaded in one of two ways: in the current shell, or in a tmux
session. To load a profile in the current shell:
```
workon [profile-name]
```
Using tmux allows for having multiple projects open at the same time without
having to manage a bunch of windows, and is my preferred method of running
workon. To load a profile in a new (or existing) tmux session:
```
workon -t [profile-name]
```

### Cleaning a profile
Workon can completely clean up after itself and return your shell to the state
it was in before you ran workon. This is most useful if you load a session in
the current shell, and not so much if you launch in tmux. To clean a profile:
```
workon -c
```

## Documentation

### Profile structure

A profile has three sections:
1. The first section is the global scope of the profile, where only workon
   environment variables should be declared.
2. The second section is the scope of the `__profile_launch` function. This
   is where you should define your project specific environment, including
   variables and functions. Defining them outside this scope could lead
   to issues with variables like `$BR`, as some utilities modify the
   workon environment variables between when the profile is sourced and
   when the initialization function is run.
3. The last section is the scope of the `__profile_clean` function. This is
   where you may add any clean up code for your profile, as this function
   is used during clean up. For instance, you can use `unset` to remove
   definitions for environment variables or functions you defined in
   `__profile_init`.

### Workon environment variables

#### Required

- `$BR` => This is the only necessary environment variable needed for a
  workon profile. It indicates the home directory of the project, and it
  will be switched to automatically when the profile is launched. It is
  also used by the utilities in various ways. It is best to set this to an
  absolute path rather than a relative one. The directory will be created
  if it does not exist.

#### Git utility

Workon can automatically fetch or create a git repository for you, or help
manage work trees. To add this functionality, you can define the following
environment variables in section 1:

- `$WORKON_GIT_REMOTE` → Set to the remote URI of the repository. If set,
  workon will prompt the user to either attempt to clone the repository or
  create a new one if `$BR` does not exist.
- `$WORKON_GIT_ROOT` → Useful when the desired `$BR` is a subdirectory of
  a git repository. This variable can be set to the absolute path of the
  git repository, and `$BR` should then be set to the relative path of the
  desired directory from within the git repository. This would allow for
  the git repo to be pulled if necessary, or for a work tree to be chosen,
  before `$BR` is modified to have the desired absolute path.
- `$WORKON_GIT_WORKTREES=1` → Enable work tree selection mode. This
  feature assumes that the `$BR` or `$WORKON_GIT_ROOT` points to a
  directory with the following structure:
  ```
  repo-name
    - mainbranch => the actual repository with main branch checked out
    - worktree1 => a work tree of repo-name, all worktrees stored at
      this level.
    .
    .
    .
  ```
  If this is enabled when pulling a repository this structure will be made
  automatically. The user will be prompted to choose a work tree when
  launching the profile. `$BR` will be modified to include the proper work
  tree path.

#### Pyenv utility

Workon can automatically load and create python environments using
[pyenv](https://github.com/pyenv/pyenv). In order to use this utility you need
to have both pyenv and
[pyenv-virtualenv](https://github.com/pyenv/pyenv-virtualenv) installed and
configured properly.

- `$WORKON_PYENV_VIRTUALENV` → The name of the desired python virtual
  environment to load. If it does not exist, it will be created.
- `$WORKON_PYENV_VERSION` → The python version to be used with the virtual
  environment. Only used if the virtual environment must be created. Workon
  does not check the version of an existing python virtual environment.

### Aliases

Workon will automatically set the following aliases:

- `,` → Changes directory to `$BR`
- `,,` → Changes directory to `$WORKON_GIT_ROOT` if it is set.

### Key bindings

Key bindings can be sourced via `.config/workon/commands.sh` if desired. The
following key bindings will be defined:

- `<Alt-w-w>` → Inputs `workon`.
- `<Alt-w-t>` → Inputs `workon -t`.
- `<Alt-w-e>` → Inputs `workon -e`.
- `<Alt-w-c>` → Inputs `workon -c`.

### Example profile
The following is an example profile one might make for completing [advent of
code](https://adventofcode.com/) in rust.
```
BR="$HOME/rust/advent"

function __profile_launch {
    function start_problem {
        (( $# != 1 )) && echo "$0 <problem-number>" && return
        $BROWSER https://adventofcode.com/2021/day/$1 &> /dev/null & disown
        $EDITOR -p $(printf "$BR/src/problem_%02d.rs $BR/src/bin/problem_%02d.rs" $1 $1)
    }

    function test {
        cargo test --lib
    }

    function build {
        cargo build --release
    }

    function run_problem {
        (( $# != 1 )) && echo "$0 <problem-number> [args...]" && return
        problem="$1"
        shift
        "$BR/target/release/problem_$problem" $@
    }
}

function __profile_clean {
    unset start_problem
    unset test
    unset build
    unset run_problem
}
```
Having a profile like this greatly reduces the repetitive nature of a project
like this. Workon is of course useful in real world scenarios as well. I use it
in my day-to-day routine as a software engineer working in a very large
codebase, and it serves not only as a way to cut down on repetitive tasks, but
as documentation for how to do build and run the various projects in our
codebase.
