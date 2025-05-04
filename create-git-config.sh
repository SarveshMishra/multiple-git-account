#!/bin/bash

echo "How many GitHub accounts do you want to configure?"
read COUNT

GITCONFIG_MAIN="$HOME/.gitconfig"
SSH_CONFIG="$HOME/.ssh/config"
PROJECTS_ROOT="$HOME/projects"

mkdir -p "$PROJECTS_ROOT"
mkdir -p "$HOME/.ssh"

echo -e "\nSetting up $COUNT GitHub accounts..."

for (( i=1; i<=$COUNT; i++ ))
do
    echo -e "\nAccount #$i"
    
    read -p "  Label (e.g., personal, work): " LABEL
    read -p "  GitHub username: " USERNAME
    read -p "  GitHub email: " EMAIL
    
    SSH_KEY="$HOME/.ssh/id_ed25519_$LABEL"
    GITCONFIG_INCLUDE="$HOME/.gitconfig-$LABEL"
    DIR="$PROJECTS_ROOT/$LABEL"
    
    echo "  Generating SSH key for $LABEL..."
    ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_KEY" -N ""

    echo "  Adding key to ssh-agent..."
    eval "$(ssh-agent -s)"
    ssh-add "$SSH_KEY"

    echo "  Writing SSH config..."
    echo "
Host github.com-$LABEL
    HostName github.com
    User git
    IdentityFile $SSH_KEY
" >> "$SSH_CONFIG"

    echo "  Creating directory: $DIR"
    mkdir -p "$DIR"

    echo "  Creating git config include file: $GITCONFIG_INCLUDE"
    echo "[user]
    name = $USERNAME
    email = $EMAIL
" > "$GITCONFIG_INCLUDE"

    echo "  Linking config in global gitconfig..."
    git config --global includeIf.gitdir:$DIR/.path "$GITCONFIG_INCLUDE"

    echo -e "\n🔑 Please add the following public key to GitHub ($LABEL):"
    echo "------------------------------------------------------------"
    cat "$SSH_KEY.pub"
    echo "------------------------------------------------------------"
    read -p "Press Enter after adding the key to GitHub..."

done

echo -e "\n✅ All accounts configured. You can now clone using:"
echo "   git clone git@github.com-<label>:<username>/<repo>.git"
