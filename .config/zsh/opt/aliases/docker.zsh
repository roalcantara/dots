# ALIASES
# http://zsh.sourceforge.net/Intro/intro_8.html

# The base command for the Docker CLI
# https://docs.docker.com/engine/reference/commandline/docker/

# IMAGES {{
  # https://docs.docker.com/engine/reference/commandline/image/
  alias dki='docker image' # Manage images
  alias dkil='docker image ls' # list images
  alias dkb='docker docker build --no-cache .' # build an image from a Dockerfile
  drmi() { docker images | sed 1d | fzf -q "$1" --no-sort -m --tac | awk '{ print $3 }' | xargs -r docker rmi } # # Select a docker image or images to remove
  # alias dkir='docker images | sed 1d | fzf -q "$1" --no-sort -u --tac | awk "{ print $3 }" | xargs -r docker run --name {} --no-cache -it' # select and run image
  # alias dkir!='docker image prune' # prune unused image(s)
# }}

# CONTAINERS {{
  # Manage containers
  # https://docs.docker.com/engine/reference/commandline/container/
  da() { local cid; cid=$(docker ps -a | sed 1d | fzf -1 -q "$1" | awk '{print $1}'); [ -n "$cid" ] && docker start "$cid" && docker attach "$cid" } # select a docker container to start and attach to
  ds() { local cid; cid=$(docker ps | sed 1d | fzf -q "$1" | awk '{print $1}'); [ -n "$cid" ] && docker stop "$cid" } # select a running docker container to stop
  drm() { docker ps -a | sed 1d | fzf -q "$1" --no-sort -m --tac | awk '{ print $1 }' | xargs -r docker rm } # select a docker container to remove
# }}

# COMPOSE {{
  # https://docs.docker.com/engine/reference/commandline/compose/
  alias dkc='docker-compose' # Manage docker compose
  alias dcl='docker-compose ps' # see what is currently running
  alias dcr='docker-compose run' # run one-off commands for your services. ex: to see what environment variables are available to the web service: dcr web env
  alias dcu='docker-compose up' # build and run the app from your project directory
  alias dcu!='docker-compose up -d' # build and run the services in the background (for “detached” mode)
  alias dcs='docker-compose stop' # stop the service - if started with docker-compose up -d
  alias dcD='docker-compose down' # remove the containers entirely
  alias dcD!='docker-compose down --volumes' # remove the containers entirely and also data volume
# }}

# HELPERS {{
  # Supports syntax highlighting for a large number of programming and markup languages
  # https://github.com/sharkdp/bat
  alias dbat='docker run -it --rm -e BAT_THEME -e BAT_STYLE -e BAT_TABS -v "$(pwd):/myapp" danlynn/bat'

  # Simplified docker based markdown linter
  # https://github.com/mmphego/my-dockerfiles/markdownlint
  alias dmlint='docker run --rm -it -v "$(pwd):/app" mmphego/markdownlint'

  # Simplified docker based latexmk
  # https://github.com/mmphego/my-dockerfiles/latex-full
  alias dmklatex='docker run --rm -i -v "$PWD":/data --user="$(id -u):$(id -g)" mmphego/latex:ubuntu'

  # Haskell Dockerfile Linter
  # https://github.com/hadolint/hadolint
  alias dlint-linter='docker run --rm -i hadolint/hadolint < '
# }}
