function cat --description 'cat but bat'
    if test (count $argv) -gt 0
        if type -q bat > /dev/null
            bat --theme Dracula --paging=never --style plain $argv
        else
            command cat $argv
        end
    end
end