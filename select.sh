#!/usr/bin/env bash
# This script uses fzf to display a list of windows and allows you to select one.
#
# If you press ENTER, it switches to the selected pane.
# If you press ENTER on an empty line, it creates a new window in the current session.
function do_select() {
    local mode
    local border_styling="" fzf_version_comparison
    local current_pane window window_id preview
    local pane pane_id

    mode=${1}
    # Save the currently active pane ID
    current_pane=$(tmux display-message -p '#{pane_id}')

    # Setup border styling
    # Specific fzf releases have added additional styling options.
    fzf_version=$(fzf --version | awk '{print $1}')
    # - 0.58.0 or later, we can enable border styling
    vercomp '0.58.0' "${fzf_version}"
    fzf_version_comparison=$?
    if [[ ${fzf_version_comparison} -ne 1 ]]; then
        border_styling+=" --input-border --input-label=' Search ' --info=inline-right"
        if [[ ${mode} == "panes" ]]; then
          border_styling+=" --list-border --list-label=' Panes '"
        else
          border_styling+=" --list-border --list-label=' Windows '"
        fi
        border_styling+=" --preview-border --preview-label=' Preview '"
    fi
    # - 0.61.0 or later, we can enable ghost text
    vercomp '0.61.0' "${fzf_version}"
    fzf_version_comparison=$?
    if [[ ${fzf_version_comparison} -ne 1 ]]; then
        border_styling+=" --ghost 'type to search...'"
    fi
    # Fallback to old border styling used in tmux-fzf-pane-switch release v1.1.2 if $border_styling is not set
    if [[ -z ${border_styling+x} ]]; then
        border_styling="--preview-label='pane preview'"
    fi

    # Check if we're using the fzf preview pane
    if [[ "${2}" = 'true' ]]; then
        preview="--preview 'tmux capture-pane -ep -t {1}' --preview-window=${4}"
    fi

    if [[ "${mode}" = 'panes' ]]; then
      switch_pane "${current_pane}" "${3}" "${border_styling}" "${preview}" "${5}"
    else
      switch_window "${current_pane}" "${3}" "${border_styling}" "${preview}" "${5}"
    fi
}

function switch_window() {
  local current_pane fzf_position border_styling preview list_format

  current_pane=${1}
  fzf_position=${2}
  border_styling=${3}
  preview=${4}
  list_format=${5}

  # Launch switcher
  window=$(tmux list-windows -aF "#{window_id} ${list_format}" | 
    eval fzf --exit-0 --print-query --reverse --tmux "${fzf_position}" --with-nth=2.. "${border_styling}" "${preview}" | 
    tail -1)

  # Set window_id to first part of fzf output
  window_id=$(echo "${window}" | awk '{print $1}')

  # If window_id is empty, exit without changing window
  if [[ -z "${window_id}" ]]; then
    tmux switch-client -t "${current_pane}"
  else
    pane_id=$(tmux list-panes -F "#{pane_id}" -t ${window_id} | head -1 | awk '{print $1}')
    tmux switch-client -t "${pane_id}"
  fi
}

function switch_pane() {
  local current_pane fzf_position border_styling preview list_format

  current_pane=${1}
  fzf_position=${2}
  border_styling=${3}
  preview=${4}
  list_format=${5}

  # Launch switcher
  pane=$(tmux list-panes -aF "#{pane_id} ${list_format}" | 
    eval fzf --exit-0 --print-query --reverse --tmux "${fzf_position}" --with-nth=2.. "${border_styling}" "${preview}" | 
    tail -1)

  # Set pane_id to first part of fzf output
  pane_id=$(echo "${pane}" | awk '{print $1}')

  # If pane_id is empty, exit without changing pane
  if [[ -z "${pane_id}" ]]; then
    tmux switch-client -t "${current_pane}"
  # Check if pane exists
  elif tmux has-session -t "${pane_id}" >/dev/null 2>&1; then
    # Found it! Let's switch.
    tmux switch-client -t "${pane_id}"
  else
    # Pane not found, let's create it.
    tmux command-prompt -b -p "Press ENTER to create a new window in the current session [${pane}]" "new-window -n \"${pane}\""
  fi
}


function vercomp() {
  local v1="$1"
  local v2="$2"

  # Split each version string into arrays using '.' as the delimiter
  IFS='.' read -r -a ver1 <<< "$v1"
  IFS='.' read -r -a ver2 <<< "$v2"

  # Compare major, minor, and patch components one by one
  for i in 0 1 2; do
    # Default to 0 if a component is missing (e.g., "1.2" becomes "1.2.0")
    local num1="${ver1[i]:-0}"
    local num2="${ver2[i]:-0}"

    # Compare the numeric values of the current component
    if (( num1 > num2 )); then
      return 1  # First version is newer
    elif (( num1 < num2 )); then
      return 2  # First version is older
    fi
  done

  return 0  # Versions are equal
}

# Check for required commands
command -v tmux >/dev/null 2>&1 || { echo "tmux not found"; exit 1; }
command -v fzf >/dev/null 2>&1 || { echo "fzf not found"; exit 1; }

# mode
mode="${1}"
# Pane preview
preview_pane="${2}"
# FZF window position
fzf_window_position="${3}"
# FZF previe window position
fzf_preview_window_position="${4}"
# TMUX list-panes format
read -r -a list_format_input <<< "${5}"
list_format=""
for w in "${list_format_input[@]}"; do
  if [[ ${w} == *"{"* ]] && [[ ${w} == *"}"* ]]; then
    list_format+="${w/{/#{} "
  else
    list_format+="${w} "
  fi
done

do_select "${mode}" "${preview_pane}" "${fzf_window_position}" "${fzf_preview_window_position}" "${list_format}"

