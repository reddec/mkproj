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
  cat "$1" | envsubst > "$(dirname "$1")/$filename"
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

  if [ ! -d "$ROOT/$NAME" ]; then
    __error "Unknown template: $1"
    exit 1
  fi
  PROJECT="$2"
  if [ "1$2" == "1" ]; then
    read -p "Project name: " PROJECT
  fi

  if [ "1$PROJECT" == "1" ]; then
    __error "No project name specified"
    exit 1
  fi

  mkdir -p "$PROJECT"
  cd "$PROJECT"

  info "Coping files..."
  cp -r "$ROOT/$NAME"/* ./

  info "Processing templates"
  export -f __mktemplate
  find . -name '*.template' -exec bash -c '__mktemplate "$0"' {} \;

  info "Processing CGI templates"
  export -f __mkcgi
  find . -name '*.cgi' -exec bash -c '__mkcgi "$0"' {} \;

  if [ -x "post-init" ]; then
    info "Executing post-init scripts"
    ./post-init
    rm -rf post-init
  fi

  success "Project initialized from template $NAME!"
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
  "help" | "-h" | "--help" )
  echo "Operate directory templates"
  echo "commands:"
  echo "    ls                                       List available templates"
  if hash tree 2>/dev/null; then
    echo "    content  <template_name>                 Print content of template"
  fi
  echo "    rm       [template_name...]              Remove template"
  echo "    export   <template_name>                 Export content of template to current dir"
  echo "    init     <template_name> [project name]  Initialize directory from template"
  echo "    save     [template_name]                 Save current directory as template"
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
