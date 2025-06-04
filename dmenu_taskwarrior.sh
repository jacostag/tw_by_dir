#!/usr/bin/env bash

# Function to display ready tasks and allow management
manage_ready_tasks() {
  # Get tasks that are in a 'ready' state with their descriptions and UUIDs
  tasks_list=$(task +READY rc.verbose=nothing export | jq -r '.[] | .description + " - " + .uuid')

  if [ -z "$tasks_list" ]; then
    notify-send "Taskwarrior" "No ready tasks to manage."
    exit 0
  fi

  # Display ready tasks and allow selection using walker
  selected_task_line=$(echo -e "$tasks_list" | walker -d -f -k -p "Select a ready task:" 2>/dev/null)

  if [ -n "$selected_task_line" ]; then
    # Extract description first, then UUID from the selected line
    selected_description=$(echo "$selected_task_line" | cut -d '-' -f 1 | sed 's/ *$//')
    selected_uuid=$(echo "$selected_task_line" | awk -F ' - ' '{print $NF}')

    # Options for the selected task, now including 'Open' and 'Annotate'
    task_actions="Start\nDone\nDelete\nOpen\nAnnotate"
    action_choice=$(echo -e "$task_actions" | walker -d -f -k -p "Action for '$selected_description':" 2>/dev/null)

    case "$action_choice" in
    "Start")
      task "$selected_uuid" start
      notify-send "Taskwarrior" "Task '$selected_description' started."
      ;;
    "Done")
      task "$selected_uuid" done
      notify-send "Taskwarrior" "Task '$selected_description' marked as done."
      ;;
    "Delete")
      # Ask for confirmation before deleting
      confirm_delete=$(walker -d -f -k -p "Confirm delete '$selected_description'? (y/N):" 2>/dev/null)
      if [[ "$confirm_delete" == "y" || "$confirm_delete" == "Y" ]]; then
        task rc.confirmation=off "$selected_uuid" delete
        notify-send "Taskwarrior" "Task '$selected_description' deleted."
      else
        notify-send "Taskwarrior" "Deletion of task '$selected_description' cancelled."
      fi
      ;;
    "Open")
      taskopen "$selected_uuid"
      notify-send "Taskwarrior" "Attempting to open links/files for '$selected_description'."
      ;;
    "Annotate")
      annotation_text=$(walker -d -f -k -p "Enter annotation for '$selected_description':" 2>/dev/null)
      if [ -n "$annotation_text" ]; then
        task "$selected_uuid" annotate "$annotation_text"
        notify-send "Taskwarrior" "Annotated task '$selected_description'."
      else
        notify-send "Taskwarrior" "No annotation text entered for task '$selected_description'."
      fi
      ;;
    *)
      notify-send "Taskwarrior" "No action selected for task."
      ;;
    esac
  else
    notify-send "Taskwarrior" "No task selected."
  fi
}

# Function to add a new task
add_new_task() {
  new_task_description=$(walker -d -f -k -p "Enter new task description:" 2>/dev/null)
  if [ -n "$new_task_description" ]; then
    task add "$new_task_description"
    notify-send "Taskwarrior" "Task added: $new_task_description"
  else
    notify-send "Taskwarrior" "No task description entered."
  fi
}

# --- Main Script Logic ---
if [ "$1" == "add" ]; then
  add_new_task
elif [ "$1" == "list" ]; then
  manage_ready_tasks
else
  # Original main menu if no arguments are provided
  main_options="Add New Task\nManage Ready Tasks"
  main_choice=$(echo -e "$main_options" | walker -d -f -k -p "Taskwarrior Menu:" 2>/dev/null)

  case "$main_choice" in
  "Add New Task")
    add_new_task
    ;;
  "Manage Ready Tasks")
    manage_ready_tasks
    ;;
  *)
    notify-send "Taskwarrior" "No option selected."
    ;;
  esac
fi
