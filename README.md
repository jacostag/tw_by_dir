# tw_by_dir taskwarrior by directory
Taskwarrior scripts to track tasks in directories

This is inspired by taskopen but works for directories

## task-add.sh
You can add a new task and the current directory will be saved as an annotation

## cdt (cd on to task)
Will allow you to display and copy to the clipboard an annotated directory from a task
it will use wl-copy to add to the clipboard the PATH
if there are many directories on a task annotation you can select
an useful alias 'cd $(cdt )' will cd to the task directory

## task-dir.sh
This will display an icon, if there is a task in the current directory
I use this one with starship (example of configuration exists on this repo)

## task_prompt.sh
This was not created by me, but I did not find it on github, the author seems to be
https://github.com/mrichar1

## task_annotate.sh
I call this one from nvim to create a task, it will include the tag +nvim
taskopen can open the file

## taskfzf
Is the one provided by https://gitlab.com/doronbehar/taskwarrior-fzf/
With the only addition of Y to sync with taskchampion
There is another one, with some modifications that allows to open an URL
https://github.com/petrovag/taskfzf/
