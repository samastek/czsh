cheat() {
    if [ "$2" ]; then
        curl "https://cheat.sh/$1/$2+$3+$4+$5+$6+$7+$8+$9+$10"
    else
        curl "https://cheat.sh/$1"
    fi
}

speedtest() {
    curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -
}

s() {
    local query="$1"

    if [[ -z "$query" ]]; then
        echo "No search term provided"
        return 1
    fi

    rg --line-number "$query" | \
        fzf --preview "$CZSH_BAT_BIN --style=numbers --color=always --highlight-line {2} {1}" \
            --delimiter : --preview-window=up:wrap
}

f() {
    find . -type f -print0 | fzf --read0 --preview "$CZSH_BAT_BIN --color=always {}" | xargs -0 file -b
}

gask() {
    if [ "$1" ]; then
        echo "$*" | gemini
    else
        echo "Usage: gask <your question or prompt>"
    fi
}

greview() {
    local target="${1:-HEAD~1}"
    git diff "$target" | gemini "Please review this git diff and provide feedback on code quality, potential issues, and suggestions for improvement:"
}

gcommit() {
    local staged_diff
    staged_diff=$(git diff --staged)
    if [[ -z "$staged_diff" ]]; then
        echo "No staged changes found. Please stage your changes first with 'git add'."
        return 1
    fi

    echo "Staged changes:"
    git diff --staged --stat
    echo
    echo "Generating commit message with Gemini..."
    echo "$staged_diff" | gemini "Based on this git diff, generate a concise and descriptive commit message following conventional commit format. Only return the commit message, nothing else:"
}

gexplain() {
    if [ "$1" ]; then
        echo "Error: $*" | gemini "Please explain this error message and provide potential solutions:"
    else
        echo "Usage: gexplain <error message>"
    fi
}

gdoc() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cat "$file" | gemini "Please generate comprehensive documentation for this code file. Include function descriptions, usage examples, and any important notes:"
    else
        echo "Usage: gdoc <filename>"
    fi
}

ganalyze() {
    local path="${1:-.}"
    echo "Analyzing project structure in: $path"
    find "$path" -type f \( -name "*.md" -o -name "*.txt" -o -name "package.json" -o -name "requirements.txt" -o -name "Makefile" -o -name "*.yml" -o -name "*.yaml" \) | head -10 | xargs cat | gemini "Analyze this project structure and files. Provide insights about the project type, technologies used, and suggestions for improvement:"
}