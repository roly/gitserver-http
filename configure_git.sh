#!/bin/bash

# Initializes the git cgi scripts
# for git http-backend through fcgiwrap.

set -o errexit

readonly GIT_PROJECT_ROOT="/var/lib/git"
readonly GIT_INITIAL_ROOT="/var/lib/initial"
readonly GIT_HTTP_EXPORT_ALL="true"
readonly GIT_USER="nginx"
readonly GIT_GROUP="nginx"

readonly FCGIPROGRAM="/usr/bin/fcgiwrap"
readonly USERID="nginx"
readonly SOCKUSERID="$USERID"
readonly FCGISOCKET="/var/run/fcgiwrap.socket"

main() {
  mkdir -p $GIT_PROJECT_ROOT

  # Checks if $GIT_INITIAL_ROOT has files
  if [[ $(ls -A ${GIT_INITIAL_ROOT}) ]]; then
    initialize_initial_repositories
  fi
  initialize_services
}

initialize_services() {
  #set permissions as we expect them to be
  chown -R $GIT_USER:$GIT_GROUP $GIT_PROJECT_ROOT
  chmod -R 775 $GIT_PROJECT_ROOT

  /usr/bin/spawn-fcgi \
    -s $FCGISOCKET \
    -F 4 \
    -u $USERID \
    -g $USERID \
    -U $USERID \
    -G $GIT_GROUP -- \
    "$FCGIPROGRAM"

   #remove nginx default config file so only our git-http config is used
   rm /etc/nginx/conf.d/default.conf
}

initialize_initial_repositories() {
  cd $GIT_INITIAL_ROOT
  for dir in $(find . -name "*" -type d -maxdepth 1 -mindepth 1); do
    echo "Initializing repository $dir"
    init_and_commit $dir
  done
}

init_and_commit() {
  local dir=$1
  local tmp_dir=$(mktemp -d)

  cp -r $dir/* $tmp_dir
  pushd . >/dev/null
  cd $tmp_dir

  if [[ -d "./.git" ]]; then
    rm -rf ./.git
  fi

  git init &>/dev/null
  git add --all . &>/dev/null
  git commit -m "first commit" &>/dev/null
  git clone --bare $tmp_dir $GIT_PROJECT_ROOT/${dir}.git &>/dev/null

  popd >/dev/null
}

main "$@"
