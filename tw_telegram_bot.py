import logging
import os

from telegram import Update
from telegram.ext import ApplicationBuilder, CommandHandler, ContextTypes
from taskw_ng import TaskWarrior


# Enable logging
logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s", level=logging.INFO
)
logger = logging.getLogger(__name__)

taskrc = os.path.join(os.path.dirname(__file__), "/home/YOUR_USER/.config/task/taskrc")
w = TaskWarrior(config_filename=taskrc)


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await context.bot.send_message(
        chat_id=update.effective_chat.id,
        text="I'm a bot, please talk to me!",
    )


async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    help_text = """
    Available commands:
    /start - Start the bot
    /help - Show this help message
    /list - List active tasks
    /add <description> - Add a new task
    /done <task_id> - Mark a task as done
    /delete <task_id> - Delete a task
    """
    await context.bot.send_message(
        chat_id=update.effective_chat.id,
        text=help_text,
    )


async def list_tasks(update: Update, context: ContextTypes.DEFAULT_TYPE):
    tasks = w.filter_tasks({"status": "pending"})
    if not tasks:
        await context.bot.send_message(
            chat_id=update.effective_chat.id,
            text="No active tasks.",
        )
        return

    message = "Active tasks:\n"
    for task in tasks:
        message += f"{task['id']}: {task['description']}\n"

    await context.bot.send_message(
        chat_id=update.effective_chat.id,
        text=message,
    )


async def add_task(update: Update, context: ContextTypes.DEFAULT_TYPE):
    description = " ".join(context.args)
    if not description:
        await context.bot.send_message(
            chat_id=update.effective_chat.id,
            text="Please provide a description for the task.",
        )
        return

    w.task_add(description)
    await context.bot.send_message(
        chat_id=update.effective_chat.id,
        text=f"Task '{description}' added.",
    )


async def done_task(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.args:
        await context.bot.send_message(
            chat_id=update.effective_chat.id,
            text="Please provide a task ID.",
        )
        return

    task_id = context.args[0]
    try:
        w.task_done(id=task_id)
        await context.bot.send_message(
            chat_id=update.effective_chat.id,
            text=f"Task {task_id} marked as done.",
        )
    except Exception as e:
        await context.bot.send_message(
            chat_id=update.effective_chat.id,
            text=f"Error: {e}",
        )


async def delete_task(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.args:
        await context.bot.send_message(
            chat_id=update.effective_chat.id,
            text="Please provide a task ID.",
        )
        return

    task_id = context.args[0]
    try:
        w.task_delete(id=task_id)
        await context.bot.send_message(
            chat_id=update.effective_chat.id,
            text=f"Task {task_id} deleted.",
        )
    except Exception as e:
        await context.bot.send_message(
            chat_id=update.effective_chat.id,
            text=f"Error: {e}",
        )


def main():
    application = ApplicationBuilder().token(os.environ["TELEGRAM_TOKEN"]).build()

    start_handler = CommandHandler("start", start)
    help_handler = CommandHandler("help", help_command)
    list_handler = CommandHandler("list", list_tasks)
    add_handler = CommandHandler("add", add_task)
    done_handler = CommandHandler("done", done_task)
    delete_handler = CommandHandler("delete", delete_task)

    application.add_handler(start_handler)
    application.add_handler(help_handler)
    application.add_handler(list_handler)
    application.add_handler(add_handler)
    application.add_handler(done_handler)
    application.add_handler(delete_handler)

    application.run_polling()


if __name__ == "__main__":
    main()
