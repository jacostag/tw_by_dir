#!/usr/bin/env bash

# This script first finds task IDs matching a specific filter.
# Then, it exports these tasks, extracts their unique annotations,
# and checks if any annotation is a directory path matching the
# target directory ($PWD by default, or a provided argument).
# If a match is found, it prints "".

function display_custom_task_indicator() {
  if ! command -v task &>/dev/null; then exit 1; fi
  if ! command -v jq &>/dev/null; then exit 1; fi
  if ! command -v readlink &>/dev/null; then exit 1; fi

  local target_dir_to_compare

  #validate the target directory
  if [[ $# -eq 0 ]]; then
    if ! target_dir_to_compare=$(readlink -f -- "$PWD"); then
      exit 1
    fi
  elif [[ $# -eq 1 ]]; then
    local input_path="$1"
    if [[ ! -d "$input_path" ]]; then
      exit 1
    fi
    if ! target_dir_to_compare=$(readlink -f -- "$input_path"); then
      exit 1
    fi
  else
    exit 1
  fi

  local found_match=false

  #Define Taskwarrior filters to limit task IDs.
  local id_filter_args=('desc.left:/' 'annotations.any:' 'annotations.count.gt:1' 'status:pending' '+dir')

  local task_ids_string
  task_ids_string=$(task _ids "${id_filter_args[@]}" 2>/dev/null)

  if [[ -z "$task_ids_string" ]]; then
    exit 1
  fi

  local ids_to_export_array=()
  mapfile -t ids_to_export_array <<<"$task_ids_string"

  if [[ ${#ids_to_export_array[@]} -eq 0 ]]; then
    exit 1
  fi

  #Export only these specific tasks by their IDs
  #use jq to extract all unique annotation descriptions.
  local annotation_descriptions
  annotation_descriptions=$(task "${ids_to_export_array[@]}" export 2>/dev/null |
    jq -r '[.[].annotations[]?.description // ""] | unique - Global() | .[]' 2>/dev/null)

  if [[ -z "$annotation_descriptions" ]]; then
    exit 1
  fi

  #get each unique annotation description line by line.
  while IFS= read -r annotation_desc; do
    if [[ -z "$annotation_desc" || "$annotation_desc" == "null" ]]; then # Skip empty or literal "null" strings
      continue
    fi

    if [[ -d "$annotation_desc" ]]; then
      local canonical_annotation_path
      if ! canonical_annotation_path=$(readlink -f -- "$annotation_desc"); then
        continue
      fi

      if [[ "$canonical_annotation_path" == "$target_dir_to_compare" ]]; then
        echo ""
        found_match=true
        break
      fi
    fi
  done <<<"$annotation_descriptions"

  # 6. Exit with status 0 if a match was found, 1 otherwise.
  if $found_match; then
    exit 0
  else
    exit 1
  fi
}

display_custom_task_indicator "$@" &
