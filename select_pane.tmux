#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
default_pane_bind_key='s'
default_window_bind_key='w'
default_preview_pane='true'
default_fzf_window_position='center,70%,80%'
default_fzf_preview_window_position='right,,,nowrap'
default_tmux_list_panes_format='{session_name} -> {window_index}: {window_name} -> {pane_title} ({pane_current_command})'
default_tmux_list_windows_format='{session_name} -> {window_index}: {window_name}'

# User overridable options
tmux_pane_bind_key="@fzf_pane_switch_bind-key"
tmux_window_bind_key="@fzf_pane_switch_bind-key"
tmux_preview_pane="@fzf_pane_switch_preview-pane"
tmux_fzf_window_position="@fzf_pane_switch_window-position"
tmux_fzf_preview_window_position="@fzf_pane_switch_preview-pane-position"
tmux_list_panes_format="@fzf_pane_switch_list-panes-format"
tmux_list_windows_format="@fzf_pane_switch_list-windows-format"

get_tmux_option() {
    local option="${1}"
    local default_value="${2}"
    local option_override
    option_override="$(tmux show-option -gqv "${option}")"
    if [ -z "${option_override}" ]; then
        echo "${default_value}"
    else
        echo "${option_override}"
    fi
}

set_switch_bindings() {
    local pane_bind_key window_bind_key
    local preview_pane fzf_window_position fzf_preview_window_position
    local list_panes_format list_windows_format

    pane_bind_key="$(get_tmux_option "${tmux_pane_bind_key}" "${default_pane_bind_key}")"
    window_bind_key="$(get_tmux_option "${tmux_window_bind_key}" "${default_window_bind_key}")"

    preview_pane="$(get_tmux_option "${tmux_preview_pane}" "${default_preview_pane}")"
    fzf_window_position="$(get_tmux_option "${tmux_fzf_window_position}" "${default_fzf_window_position}")"
    fzf_preview_window_position="$(get_tmux_option "${tmux_fzf_preview_window_position}" "${default_fzf_preview_window_position}")"

    list_panes_format="$(get_tmux_option "${tmux_list_panes_format}" "${default_tmux_list_panes_format}")"
    list_windows_format="$(get_tmux_option "${tmux_list_windows_format}" "${default_tmux_list_windows_format}")"

    tmux bind-key "${pane_bind_key}" run-shell \
        "'${CURRENT_DIR}/select.sh' 'panes' '${preview_pane}' '${fzf_window_position}' '${fzf_preview_window_position}' '${list_panes_format}'"
    tmux bind-key "${window_bind_key}" run-shell \
        "'${CURRENT_DIR}/select.sh' 'windows' '${preview_pane}' '${fzf_window_position}' '${fzf_preview_window_position}' '${list_windows_format}'"
}

set_switch_bindings

