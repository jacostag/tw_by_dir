#!/usr/bin/env bash
# Add the current dir as an annotation to a new task

# Exit immediately if a command exits with a non-zero status.
set -e

# Prints an error message to stderr and exits.
#
# @param $1 - The error message to print.
function error_exit() {
  echo "ERROR: $1" >&2
  exit 1
}

function main() {
  # Verify that the 'task' command is available.
  if ! command -v task &>/dev/null; then
    error_exit "The 'task' command could not be found. Please ensure Taskwarrior is installed and in your PATH."
  fi

  # Verify that a task description has been provided.
  if [[ $# -eq 0 ]]; then
    error_exit "You must provide a description for the task.
Usage: task-add <your task description>"
  fi

  # Add the task and capture the output to get the ID.
  task add +dir "$@"
  local new_id
  new_id=$(task +LATEST ids)

  # Add the current directory path ($PWD) as an annotation to the new task.
  task "$new_id" annotate "$PWD"
  echo "Successfully annotated task $new_id with directory: $PWD"
}

main "$@"
