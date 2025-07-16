# taskwarrior utils
Taskwarrior scripts to manage tasks more comfortable


## Ulauncher extension
[Ulauncher extension](https://pforg.staging.gpcloudtest.com/)


## bee_tw_sync.py
A python script that uses beeai sdk to get the not done todos from bee, creates a json file with the proper format, removes the emojies and uses task import to add all the tasks to taskwarrior. All the todos are marked as done on bee, task sync is executed.
beeai has to be installed using pip/pipx/uv.
replace `YOUR BEE API KEY HERE` with your bee api key


## task-add.sh
You can add a new task and the current directory will be saved as an annotation with +dir tag


## cdt (cd on to task)
This is inspired by taskopen but works for directories (I added my taskopenrc that handles almost the same functionality)
Will allow you to display and copy to the clipboard an annotated directory from a task
it will use wl-copy to add to the clipboard the PATH
if there are many directories on a task annotation you can select your choice
an useful alias `'cd $(cdt )'` will cd to the task directory


## task-dir.sh
This will display an icon, if there is a task in the current directory
I use this one with starship (example of configuration exists on this repo) on my left side


## task_prompt.sh
This was not created by me, but I did not find it on github, unknown author, but the first script seems very old
Is nice to have it on starship prompt, it shows different icons on the right (depending on the urgency of the tasks)


## task_annotate.sh
I call this one from nvim to create a task, it will include the tag +nvim
taskopen can open the file


## taskfzf
I added 2 scripts, not mine, both are pretty much the same, I have to analyze which one has more capabilities,
for now, I just added an extra function to sync with taskchampion server using 'Y'

taskfzfprint Is the one provided by https://gitlab.com/doronbehar/taskwarrior-fzf/ and posix compatible

taskfzfURL Is another one, with some modifications that allows to open an URL
https://github.com/petrovag/taskfzf/


## notify_tasks.sh
Using notify-send, this works great on crontab, every hour. It will show a notification for each task due in less than 1 hour,
allowing you to start it, mark it as done, or setting the due time for 1 more hour.


## dmenu_taskwarrior.sh
Is not using dmenu directly, but it is very easy to adapt to dmenu
Also uses notify-send, can be switch to another notifier
Uses walker launcher dmenu emulation to manage taskwarrior.

Can be use as:

`dmenu_taskwarrior.sh add` to add a task directly (no extra options, just add the task with the parameters you want)

`dmenu_taskwarrior.sh list` will list all the current tasks in ready, with the option to start, mark as done, use taskopen, or delete a task (requires confirmation)

`dmenu_taskwarrior.sh` without arguments will display a menu to list or add a task


## zen_task.sh
Script to manage tasks in a more graphical way using zenity


## tw_telegram_bot.py
A very simple telegram bot in python that will allow to control your task list from telegram. 
You need to export your env variable TELEGRAM_TOKEN with the token provided by telegram bot father.
Also, you need to update line 15 to point to your taskrc file.
