#!/usr/bin/env bash
cd ~/Library/Application\ Support/k9s
for i in /Users/rafaribe/.config/k9s/*; do
    if [ "$i" != "/Users/rafaribe/.config/k9s/symlink_everything_here.sh" ]; then
        echo "$i"
        ln -s "$i" .
    fi
done
