#!/usr/bin/env bash

# Define the notification duration in milliseconds
NOTIFICATION_DURATION=5000

# Define the delay between notifications in seconds (1 minute)
NOTIFICATION_DELAY=10

# Path to your Taskwarrior icon (ensure this path is correct)
TW_ICON="$HOME/Pictures/tw.svg"

# Get tasks that are +READY and due within the next hour,
# and format them as "uuid@description" using jq.
TASKS=$(task +READY due.before:now+1h export | jq -r '.[] | "\(.uuid)@\(.description)"' || true)

# Read tasks into a bash array, splitting by newline.
IFS=$'\n' read -r -d '' -a TASK_ARRAY <<<"$TASKS"

# Get the number of tasks
NUM_TASKS=${#TASK_ARRAY[@]}

# Check if there are any tasks
if [ "$NUM_TASKS" -eq 0 ]; then
  echo "No tasks found to notify."
else
  echo "Found $NUM_TASKS task(s) to notify."
  # Loop through each task
  for ((i = 0; i < NUM_TASKS; i++)); do
    # Split the "uuid@description" string
    FULL_TASK_INFO="${TASK_ARRAY[$i]}"
    TASK_UUID=$(echo "$FULL_TASK_INFO" | cut -d'@' -f1)
    TASK_DESCRIPTION=$(echo "$FULL_TASK_INFO" | cut -d'@' -f2-)

    echo "Sending notification for task UUID: $TASK_UUID - Description: $TASK_DESCRIPTION"

    # Main notification with action buttons
    ACTION_RESULT=$(notify-send \
      -u critical 'Task' \
      -i "$TW_ICON" \
      -t "$NOTIFICATION_DURATION" \
      -a TW \
      "$TASK_DESCRIPTION" \
      --action="1=+1hr" \
      --action="done=Done" \
      --action="start=Start")

    # Trim whitespace from the result to ensure clean comparison
    ACTION_RESULT=$(echo "$ACTION_RESULT" | xargs)

    # Handle the action based on the captured output (action ID)
    case "$ACTION_RESULT" in
    "1") # Action ID "1" (+1hr) was clicked
      echo "Action: Due in 1hr! for task $TASK_UUID"
      task "$TASK_UUID" modify due:now+1hr
      if [ $? -eq 0 ]; then
        notify-send -u critical 'Task' -i "$TW_ICON" -t 2000 -a TW "'$TASK_DESCRIPTION' updated: Due in +1 hour."
      else
        notify-send -u critical 'Task' -i "$TW_ICON" -t 5000 -a TW "Error updating task '$TASK_DESCRIPTION'."
      fi
      ;;
    "done") # Action ID "done" (Done) was clicked
      echo "Action: Done! for task $TASK_UUID"
      task "$TASK_UUID" done
      if [ $? -eq 0 ]; then
        notify-send -u critical 'Task' -i "$TW_ICON" -t 2000 -a TW "'$TASK_DESCRIPTION' is done."
      else
        notify-send -u critical 'Task' -i "$TW_ICON" -t 5000 -a TW "Error marking task '$TASK_DESCRIPTION' as done."
      fi
      ;;
    "start")
      echo "Action: Start! for task $TASK_UUID"
      task "$TASK_UUID" start
      if [ $? -eq 0 ]; then
        notify-send -u critical 'Task' -i "$TW_ICON" -t 2000 -a TW "'$TASK_DESCRIPTION' started."
      else
        notify-send -u critical 'Task' -i "$TW_ICON" -t 5000 -a TW "Error starting task '$TASK_DESCRIPTION'."
      fi
      ;;
    "") # No action was clicked (timed out or dismissed)
      echo "Notification for task '$TASK_DESCRIPTION' timed out or was dismissed."
      ;;
    *) # Fallback for unexpected output (shouldn't happen with these actions)
      echo "Unexpected action result for task '$TASK_DESCRIPTION': '$ACTION_RESULT'"
      notify-send -u critical 'Task' -i "$TW_ICON" -t 5000 -a TW "Unexpected action for '$TASK_DESCRIPTION': '$ACTION_RESULT'"
      ;;
    esac

    # If it's not the last task, wait for the specified delay
    if [ "$i" -lt $((NUM_TASKS - 1)) ]; then
      echo "Waiting $NOTIFICATION_DELAY seconds before next notification..."
      sleep "$NOTIFICATION_DELAY"
    fi
  done
  echo "All notifications processed."
fi
