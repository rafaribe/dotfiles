# Git Repo Root
function grr
    set -l repo_dir (git rev-parse --show-toplevel 2>/dev/null)
    if test -n "$repo_dir"
        cd $repo_dir
    else
        echo "Not inside a Git repository."
    end
end

# Git last sha
function gls
    set -l repo_dir (git rev-parse --show-toplevel 2>/dev/null)
    if test -n "$repo_dir"
        set -l commit_sha_short (git rev-parse --short HEAD)
        set -l commit_sha (git rev-parse HEAD)
        echo "Latest commit SHA: $commit_sha_short"
        echo "Latest commit SHA: $commit_sha"
    else
        echo "Not inside a Git repository."
    end
end
# Git last tag
function glt
    set -l repo_dir (git rev-parse --show-toplevel 2>/dev/null)
    if test -n "$repo_dir"
        set -l latest_tag (git describe --tags --abbrev=0)
        if test -n "$latest_tag"
            echo "Latest tag: $latest_tag"
        else
            echo "No tags found in the repository."
        end
    else
        echo "Not inside a Git repository."
    end
end

function ec
    git commit -m "chore: empty commit" --allow-empty
    git push
end