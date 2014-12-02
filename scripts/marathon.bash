#!/bin/bash

SESSION=$USER
tmux -2 new-session -d -s $SESSION

# Don't let windows be renamed; I give them a name for a reason, damnit!
tmux set-option -g allow-rename off
tmux set-window-option -g automatic-rename off

tmux new-window -t $SESSION:0 -n 'core'
tmux new-window -t $SESSION:1 -n 'base'
tmux new-window -t $SESSION:2 -n 'robot'
tmux new-window -t $SESSION:3 -n 'cams'
tmux new-window -t $SESSION:4 -n 'nav'
tmux new-window -t $SESSION:5 -n 'ui'
tmux new-window -t $SESSION:6 -n 'repo'
tmux new-window -t $SESSION:7 -n 'sched'
tmux new-window -t $SESSION:8 -n 'rout'
tmux new-window -t $SESSION:9 -n 'y1'

# Sometimes 2 is not enough. (Avoids doubling commands; "waits for the shells".)
sleep 3

# Roscore and htop to actually make use of all the space!
tmux select-window -t $SESSION:0
tmux split-window -v
tmux select-pane -t 0
tmux send-keys "roscore" C-m
tmux resize-pane -U 30
tmux select-pane -t 1
tmux send-keys "htop" C-m

# All the other launchfiles
tmux select-window -t $SESSION:1
tmux send-keys "HOSTNAME=karl roslaunch strands_bringup strands_core.launch user:=strands"
tmux select-window -t $SESSION:2
tmux send-keys "roslaunch strands_karl karl_robot.launch"
tmux select-window -t $SESSION:3
tmux send-keys "ROS_MASTER_URI=http://karl:11311 roslaunch strands_karl karl_cams.launch"
tmux select-window -t $SESSION:4
tmux send-keys "ROS_MASTER_URI=http://karl:11311 roslaunch strands_karl karl_navigation.launch"
tmux select-window -t $SESSION:5
tmux send-keys "ROS_MASTER_URI=http://karl:11311 roslaunch strands_ui strands_ui.launch"
tmux select-window -t $SESSION:6
tmux send-keys "rosrun marathon_reporter mileage_monitor.py"
tmux select-window -t $SESSION:7
tmux send-keys "roslaunch task_executor task-scheduler.launch"
tmux select-window -t $SESSION:8
tmux send-keys "rosrun strands_karl marathon_routine_node.py"
tmux select-window -t $SESSION:9
tmux send-keys "rosrun y1_interfaces web_interface.py"
# tmux select-window -t $SESSION:4
# tmux send-keys "ssh -t scitos@bruxelles.local ./start_cam.sh"
# tmux select-window -t $SESSION:5
# tmux send-keys "ssh -t scitos@amsterdam.local ./start_cam.sh"

# Set default window
tmux select-window -t $SESSION:0

# Attach to session
tmux -2 attach-session -t $SESSION
tmux setw -g mode-mouse on