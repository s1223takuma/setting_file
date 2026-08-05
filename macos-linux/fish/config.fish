fish_add_path $HOME/.local/bin

# macOS / Linuxの代表的なインストール先からCondaを探す。
for conda_root in /opt/miniconda3 $HOME/miniconda3 $HOME/anaconda3
    if test -x "$conda_root/bin/conda"
        eval "$conda_root/bin/conda" "shell.fish" "hook" $argv | source
        break
    else if test -f "$conda_root/etc/fish/conf.d/conda.fish"
        source "$conda_root/etc/fish/conf.d/conda.fish"
        break
    end
end



if status is-interactive; and command -q starship
    starship init fish | source
end
