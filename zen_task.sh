#!/usr/bin/env bash

# A script to manage Taskwarrior tasks using Zenity.
# This version includes an 'Annotate' option.

main_title="Taskwarrior Task Manager"

while true; do

  declare -A uuid_map=()
  declare -a task_args=()

  while IFS= read -r id && IFS= read -r uuid && IFS= read -r description; do
    uuid_map[$id]=$uuid
    task_args+=("$id" "$description")
  done < <(task +READY export | jq -r '.[] | .id, .uuid, .description')

  selection=""

  if [ ${#task_args[@]} -eq 0 ]; then
    zenity --info --title="$main_title" --text="No READY tasks to display." --width=350
    if zenity --question --title="$main_title" --text="Would you like to add a new task?"; then
      selection="Add Task"
    else
      break
    fi
  else
    selection=$(zenity --list \
      --title="$main_title" \
      --text="Select a task to manage, or add a new one:" \
      --column="ID" --column="Description" \
      --ok-label="Manage Selected" \
      --extra-button="Add Task" \
      "${task_args[@]}" \
      --width=800 --height=900)

    exit_status=$?

    if [ $exit_status -ne 0 ]; then
      if [ "$selection" != "Add Task" ]; then
        break
      fi
    fi
  fi

  case "$selection" in
  "Add Task")
    new_task_info=$(zenity --forms \
      --title="Add New Task" \
      --text="Enter the details for the new task:" \
      --add-entry="Description" \
      --add-calendar="Due Date (optional)" \
      --add-entry="Due Time (e.g., 5pm or 17:00, optional)" \
      --width=450)

    if [ $? -ne 0 ]; then continue; fi

    description=$(echo "$new_task_info" | cut -d'|' -f1)
    due_date=$(echo "$new_task_info" | cut -d'|' -f2)
    due_time=$(echo "$new_task_info" | cut -d'|' -f3)

    if [ -n "$description" ]; then
      cmd_args=("add" "$description")
      if [ -n "$due_date" ]; then
        formatted_date=$(date -d "$due_date" "+%Y-%m-%d")
        if [ -n "$due_time" ]; then
          cmd_args+=("due:${formatted_date}T${due_time}")
        else
          cmd_args+=("due:${formatted_date}")
        fi
      fi

      task "${cmd_args[@]}"
      zenity --info --text="Task added." --width=300
    else
      zenity --warning --text="No description provided. Task not created." --width=300
    fi
    ;;

  *)
    task_id=$selection
    if [ -z "$task_id" ]; then continue; fi

    task_uuid=${uuid_map[$task_id]}
    task_description=$(task "$task_uuid" _get description)

    action=$(zenity --list \
      --title="Manage Task: $task_id" \
      --text="What would you like to do with:\n<b>$task_description</b>" \
      --radiolist \
      --column="Select" --column="Action" \
      FALSE "Start" \
      FALSE "Stop" \
      FALSE "Modify" \
      FALSE "Annotate" \
      FALSE "Done" \
      FALSE "Delete" \
      --height=480 --width=500)

    case $action in
    "Start") task "$task_uuid" start && zenity --info --text="Task $task_id started." --width=300 ;;
    "Stop") task "$task_uuid" stop && zenity --info --text="Task $task_id stopped." --width=300 ;;
    "Done") task "$task_uuid" done && zenity --info --text="Task $task_id marked as done." --width=300 ;;

    "Annotate")
      annotation_text=$(zenity --entry \
        --title="Annotate Task $task_id" \
        --text="Enter the annotation:" \
        --width=500)
      if [ $? -eq 0 ] && [ -n "$annotation_text" ]; then
        task "$task_uuid" annotate "$annotation_text"
        zenity --info --text="Annotation added to task $task_id." --width=300
      fi
      ;;

    "Modify")
      new_description=$(zenity --entry \
        --title="Modify Task $task_id" \
        --text="Enter the new description:" \
        --entry-text="$task_description" \
        --width=500)
      if [ -n "$new_description" ] && [ "$new_description" != "$task_description" ]; then
        task "$task_uuid" modify "$new_description"
        zenity --info --text="Task $task_id modified." --width=300
      fi
      ;;
    "Delete")
      if zenity --question --title="Confirm Deletion" --text="Are you sure you want to delete task $task_id?\n\n$task_description" --width=400; then
        task "$task_uuid" delete
        zenity --info --text="Task $task_id deleted." --width=300
      fi
      ;;
    esac
    ;;
  esac
done

exit 0
