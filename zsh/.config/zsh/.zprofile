case "$(uname -s)" in
  Darwin)
    [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
    ;;
  Linux)
    [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]] && \
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    ;;
esac
