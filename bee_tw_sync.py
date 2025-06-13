import asyncio
import json
import re
import subprocess
from datetime import datetime, timezone
from beeai import Bee


def format_date(date_string):
    """
    Parses an ISO format date string and returns it in 'YYYYMMDDTHHmmss' format.
    """
    if not date_string:
        return None
    dt_object = datetime.fromisoformat(date_string.replace("Z", "+00:00"))
    return dt_object.strftime("%Y%m%dT%H%M%S")


def run_command(command):
    """
    Runs a shell command, prints its output, and returns True on success.
    """
    print(f"\n> Executing: {' '.join(command)}")
    try:
        result = subprocess.run(command, check=True, capture_output=True, text=True)
        print(result.stdout)
        return True
    except FileNotFoundError:
        print(f"Error: The command '{command[0]}' was not found.")
        print("Please ensure it is installed and in your system's PATH.")
        return False
    except subprocess.CalledProcessError as e:
        print(f"Error: Command failed with exit code {e.returncode}.")
        print("--- Stderr ---")
        print(e.stderr)
        print("--- Stdout ---")
        print(e.stdout)
        return False


async def main():
    """
    Full workflow: Fetch, filter, transform, sync, import, sync again,
    and finally mark as completed.
    """
    bee = Bee("YOUR BEE API KEY HERE")

    print("Step 1: Fetching todos from Bee...")
    todos_data = await bee.get_todos("me")

    if not (todos_data and "todos" in todos_data):
        print("No todos were found or there was an error in the response.")
        return

    print("\nStep 2: Processing and filtering active todos...")
    transformed_todos = []
    imported_todo_ids = []
    modified_time = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S")

    for todo in todos_data["todos"]:
        if todo.get("completed") is True:
            continue
        imported_todo_ids.append(todo.get("id"))
        original_text = todo.get("text", "")
        filtered_words = re.findall(r"\b[a-zA-Z]\w*\b", original_text)
        description = " ".join(filtered_words)
        new_todo = {
            "description": description,
            "status": "pending",
            "modified": modified_time,
            "entry": format_date(todo.get("created_at")),
            "urgency": 1,
            "project": "Bee",
        }
        due_date = format_date(todo.get("alarm_at"))
        if due_date:
            new_todo["due"] = due_date
        transformed_todos.append(new_todo)

    if not transformed_todos:
        print("\nNo active todos to process. Exiting.")
        return

    output_filename = "todos.json"
    with open(output_filename, "w") as json_file:
        json.dump(transformed_todos, json_file, indent=4)
    print(
        f"\nSuccessfully saved {len(transformed_todos)} active todos to {output_filename}"
    )

    # --- Step 3: Run Taskwarrior commands: sync -> import -> sync ---
    print("\nStep 3: Executing Taskwarrior command sequence...")

    # Run first sync
    if not run_command(["task", "sync"]):
        print("\nInitial 'task sync' failed. Aborting sequence.")
        return

    # Run import
    if not run_command(["task", "import", output_filename]):
        print("\n'task import' failed. Aborting sequence.")
        return

    # Run second sync
    if not run_command(["task", "sync"]):
        print("\nFinal 'task sync' failed. Aborting sequence.")
        return

    # If we get here, all commands were successful.
    print("\nTaskwarrior command sequence completed successfully.")

    # --- Step 4: Mark todos as completed in Bee ---
    if imported_todo_ids:
        print(
            f"\nStep 4: Marking {len(imported_todo_ids)} imported todos as completed in Bee..."
        )
        update_tasks = [
            bee.update_todo("me", todo_id, {"completed": True})
            for todo_id in imported_todo_ids
        ]
        try:
            await asyncio.gather(*update_tasks)
            print("Successfully marked all todos as completed.")
        except Exception as e:
            print(f"An error occurred while marking todos as completed: {e}")


if __name__ == "__main__":
    asyncio.run(main())
