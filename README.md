# taskwarrior utils
Taskwarrior scripts to manage tasks more comfortable

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


### dmenu_taskwarrior.sh
Is not using dmenu directly, but it is very easy to adapt to dmenu
Also uses notify-send, can be switch to another notifier
Uses walker launcher dmenu emulation to manage taskwarrior.

Can be use as:

`dmenu_taskwarrior.sh add` to add a task directly (no extra options, just add the task with the parameters you want)

`dmenu_taskwarrior.sh list` will list all the current tasks in ready, with the option to start, mark as done, use taskopen, or delete a task (requires confirmation)

`dmenu_taskwarrior.sh` without arguments will display a menu to list or add a task
