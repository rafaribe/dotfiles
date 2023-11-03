#!/usr/bin/env bash
cd ~/Library/Application\ Support/linak-controller
for i in $HOME/.config/linak-controller/*; do
    if [ "$i" != "$HOME/.config/linak-controller/symlink_everything_here.sh" ]; then
        echo "$i"
        rm -rf $i
        ln -s "$i" .
    fi
done
