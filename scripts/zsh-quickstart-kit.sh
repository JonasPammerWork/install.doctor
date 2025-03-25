#!/bin/bash

# @description This function logs with style using Gum if it is installed, otherwise it uses `echo`. It is also capable of leveraging Glow to render markdown.
#     When Glow is not installed, it uses `cat`. The following sub-commands are available:
#
#     | Sub-Command | Description                                                                                         |
#     |-------------|-----------------------------------------------------------------------------------------------------|
#     | `error`     | Logs a bright red error message                                                                     |
#     | `info`      | Logs a regular informational message                                                                |
#     | `md`        | Tries to render the specified file using `glow` if it is installed and uses `cat` as a fallback     |
#     | `prompt`    | Alternative that logs a message intended to describe an upcoming user input prompt                  |
#     | `star`      | Alternative that logs a message that starts with a star icon                                        |
#     | `start`     | Same as `success`                                                                                   |
#     | `success`   | Logs a success message that starts with green checkmark                                             |
#     | `warn`      | Logs a bright yellow warning message                                                                |
logg() {
  TYPE="$1"
  MSG="$2"
  if [ "$TYPE" == 'error' ]; then
    if command -v gum > /dev/null; then
        gum style --border="thick" "$(gum style --foreground="#ff0000" "✖") $(gum style --bold --background="#ff0000" --foreground="#ffffff"  " ERROR ") $(gum style --bold "$MSG")"
    else
        echo "ERROR: $MSG"
    fi
  elif [ "$TYPE" == 'info' ]; then
    if command -v gum > /dev/null; then
        gum style " $(gum style --foreground="#00ffff" "○") $(gum style --faint "$MSG")"
    else
        echo "INFO: $MSG"
    fi
  elif [ "$TYPE" == 'md' ]; then
    if command -v glow > /dev/null; then
        glow "$MSG"
    else
        cat "$MSG"
    fi
  elif [ "$TYPE" == 'prompt' ]; then
    if command -v gum > /dev/null; then
        gum style " $(gum style --foreground="#00008b" "▶") $(gum style --bold "$MSG")"
    else
        echo "PROMPT: $MSG"
    fi
  elif [ "$TYPE" == 'star' ]; then
    if command -v gum > /dev/null; then
        gum style " $(gum style --foreground="#d1d100" "◆") $(gum style --bold "$MSG")"
    else
        echo "STAR: $MSG"
    fi
  elif [ "$TYPE" == 'start' ]; then
    if command -v gum > /dev/null; then
        gum style " $(gum style --foreground="#00ff00" "▶") $(gum style --bold "$MSG")"
    else
        echo "START: $MSG"
    fi
  elif [ "$TYPE" == 'success' ]; then
    if command -v gum > /dev/null; then
        gum style " $(gum style --foreground="#00ff00" "✔") $(gum style --bold "$MSG")"
    else
        echo "SUCCESS: $MSG"
    fi
  elif [ "$TYPE" == 'warn' ]; then
    if command -v gum > /dev/null; then
        gum style " $(gum style --foreground="#d1d100" "◆") $(gum style --bold --background="#ffff00" --foreground="#000000"  " WARNING ") $(gum style --bold "$MSG")"
    else
        echo "WARNING: $MSG"
    fi
  else
    if command -v gum > /dev/null; then
        gum style " $(gum style --foreground="#00ff00" "▶") $(gum style --bold "$TYPE")"
    else
        echo "$MSG"
    fi
  fi
}


logg "start" "Installing zsh-quickstart-kit and Nerd Fonts..."

# Install Nerd Fonts
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts && curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Hack.zip
unzip -o Hack.zip
rm Hack.zip
fc-cache -f -v

# Install Zgenom
cd $HOME
if [ ! -d "zgenom" ]; then
  git clone https://github.com/jandamm/zgenom.git
else
  logg "info" "zgenom already installed, skipping..."
fi

# Install the starter kit
cd $HOME
if [ ! -d "zsh-quickstart-kit" ]; then
  git clone https://github.com/unixorn/zsh-quickstart-kit.git
else
  logg "info" "zsh-quickstart-kit already installed, skipping..."
fi

# Configure zsh using stow
cd $HOME/zsh-quickstart-kit
if command -v stow >/dev/null 2>&1; then
  stow --target=$HOME zsh
else
  logg "warn" "Stow is not available, falling back to manual symlinking"
  ln -sf $HOME/zsh-quickstart-kit/zsh/.zshrc ~/.zshrc
  ln -sf $HOME/zsh-quickstart-kit/zsh/.zsh-functions ~/.zsh-functions
  ln -sf $HOME/zsh-quickstart-kit/zsh/.zgen-setup ~/.zgen-setup
  ln -sf $HOME/zsh-quickstart-kit/zsh/.zsh_aliases ~/.zsh_aliases
fi

# Set zsh as default shell
if grep -q "^$USER:" /etc/passwd; then
  # Regular user - use chsh
  chsh -s $(which zsh)
  logg "success" "Changed default shell to zsh"
else
  # AD user - update shell in /etc/passwd
  if command -v sudo >/dev/null 2>&1; then
    # Remove any existing entry for this user
    sudo sed -i "/^$USER:/d" /etc/passwd
    # Add new entry with zsh shell
    sudo sh -c "getent passwd $USER | sed 's:/bin/bash:/bin/zsh:' >> /etc/passwd"
    logg "success" "Updated AD user entry in /etc/passwd with zsh shell"
  else
    # Fallback to .bashrc/.profile method if no sudo
    echo 'exec zsh -l' >> ~/.bashrc
    echo 'exec zsh -l' >> ~/.profile
    logg "success" "Configured zsh as default shell for AD user (fallback method)"
  fi
fi

