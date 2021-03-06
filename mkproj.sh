#!/bin/bash
set -e -o pipefail
ROOT="$HOME/.dir-templates"
VERSION="1.0.0"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

function __error {
  echo -e "${RED}${@:1}${NC}"
}

function success {
  echo -e "${GREEN}${@:1}${NC}"
}

function info {
  echo -e "${YELLOW}${@:1}${NC}"
}

function save {
  # Save current dir as template
  DEF_TEMPLATE="$(basename "`pwd`")"
  NAME="$1"
  if [ "1$1" == "1" ]; then
    NAME="$DEF_TEMPLATE"
  fi
  rm -rf "$ROOT/$NAME"
  mkdir -p "$ROOT/$NAME"
  for file in ./; do
    cp -r "$file" "$ROOT/$NAME/"
  done
  success "Saved as $NAME!"
}

function __mktemplate {
  filename=$(basename "$1")
  extension="${filename##*.}"
  filename="${filename%.*}"
  cat "$1" | DOLLAR='$'  envsubst > "$(dirname "$1")/$filename"
  rm -f "$1"
}

function __mkcgi {
  filename=$(basename "$1")
  extension="${filename##*.}"
  filename="${filename%.*}"
  bash "$1" | envsubst > "$(dirname "$1")/$filename"
  rm -f "$1"
}


function init {
  # Initialize template
  #
  # Executed: post-init
  # Processed as substituion: .template
  # Processed as cgi script (output saved as file): .cgi

  if [ "1$1" == "1" ]; then
    __error "No template name specified"
    exit 1
  fi
  NAME="$1"


  read -p "Project name: " PROJECT

  if [ "1$PROJECT" == "1" ]; then
    __error "No project name specified"
    exit 1
  fi
  mkdir -p "$PROJECT"
  cd "$PROJECT"
  export -f __mktemplate
  export -f __mkcgi
  export PROJECT

  for NAME in "${@:1}"; do
    if [ ! -d "$ROOT/$NAME" ]; then
      __error "Unknown template: $NAME"
      continue
    fi

    info "Apply $NAME"

    info "Coping files..."
    cp -r "$ROOT/$NAME"/* ./
    info "Processing templates"
    find . -name '*.template' -exec bash -c '__mktemplate "$0"' {} \;
    info "Processing CGI templates"
    find . -name '*.cgi' -exec bash -c '__mkcgi "$0"' {} \;

    if [ -x "post-init" ]; then
      info "Executing post-init scripts"
      ./post-init
      rm -rf post-init
    fi

    success "Template $NAME done"
  done
  success "Project $PROJECT initialized"
}

function show_content {
  if [ "1$1" == "1" ]; then
    __error "No template name specified"
    exit 1
  fi
  NAME="$1"

  if [ ! -d "$ROOT/$NAME" ]; then
    __error "Unknown template: $1"
    exit 1
  fi
  cd "$ROOT/$NAME"
  tree
}

function remove_template {
  for NAME in "${@:1}"; do
    rm -rf  "$ROOT/$NAME"
    success "Template $NAME removed"
  done
}

function list {
  for sample in "$ROOT"/*; do
      if [ -d "$sample" ]; then
        echo "$(basename "$sample")"
      fi
  done
}

function install_myself {
  if [ "$(id -u)" != "0" ]; then
   __error "This command must be run as root"
   exit 1
  fi
  cp "$1" "/usr/bin/mkproj"
  chmod +x "/usr/bin/mkproj"
  success "Installed: now you can execute just by \"mkproj\" command"
}

function backup {
  if [ "1$1" == "1" ]; then
    __error "No target archive name specified"
    exit 1
  fi
  tar -C "$ROOT" -zcf "$1" .
  success "Backup created into $1"
}

function restore {
  if [ "1$1" == "1" ]; then
    __error "No source archive name specified"
    exit 1
  fi
  tar -C "$ROOT" -xf "$1" .
  success "Backup restored from $1"
}

function export_template {
  # Just copy content of template without processing
  if [ "1$1" == "1" ]; then
    __error "No template name specified"
    exit 1
  fi
  NAME="$1"

  if [ ! -d "$ROOT/$NAME" ]; then
    __error "Unknown template: $1"
    exit 1
  fi

  info "Coping files..."
  cp -r "$ROOT/$NAME"/* ./
  success "Content of $NAME exported"
}

function pull_repository {
  if [ ! -d "$ROOT/.git" ]; then
    __error "$ROOT must be initialized git repo"
    exit 1
  fi

  cd "$ROOT"
  git pull
}

function push_repository {
  if [ ! -d "$ROOT/.git" ]; then
    __error "$ROOT must be initialized git repo"
    exit 1
  fi
  cd "$ROOT"
  git push
}

case "$1" in
  "init" )
  init "${@:2}"
  ;;
  "save" )
  save "${@:2}"
  ;;
  "ls" )
  list
  ;;
  "install" )
  install_myself "$0"
  ;;
  "content" )
    show_content "$2"
  ;;
  "export" )
    export_template "$2"
  ;;
  "rm" )
    remove_template "${@:2}"
  ;;
  "backup" )
    backup "${@:2}"
  ;;
  "restore" )
    restore "${@:2}"
  ;;
  "pull" )
    pull_repository
  ;;
  "push" )
    push_repository
  ;;
  "help" | "-h" | "--help" )
  echo "Operate directory templates"
  echo "commands:"
  echo "    ls                                       List available templates"
  if hash tree 2>/dev/null; then
    echo "    content  <template_name>                 Print content of template"
  fi
  echo "    rm       [template_name...]              Remove template"
  echo "    export   <template_name>                 Export content of template to current dir"
  echo "    init     <template_name...>              Initialize directory and apply templates"
  echo "    save     [template_name]                 Save current directory as template"
  echo "    backup   <archive name>                  Compress all templates to tar.gz"
  echo "    restore  <archive name>                  Unpack all templates from tar.gz"
  if [ -d "$ROOT/.git" ]; then
    echo "    pull                                     Pull templates from remote repo"
    echo "    push                                     Push templates to remote repo"
  fi
  echo "    help                                     Show this help"
  echo "    install                                  Install this script to /usr/bin/mkproj"
  ;;
  "version" | "-v" )
  echo "$VERSION Author: Baryshnikov Alexander <dev@baryshnikov.net>"
  ;;
  * )
  __error "${RED} Unknown command $1"
  exit 1
  ;;
esac
