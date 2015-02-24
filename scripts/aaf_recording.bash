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
tmux new-window -t $SESSION:4 -n 'ppl'
tmux new-window -t $SESSION:5 -n 'loc'
tmux new-window -t $SESSION:6 -n 'rqt'
tmux new-window -t $SESSION:7 -n 'rec'

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
tmux send-keys "ROS_MASTER_URI=http://karl:11311 roslaunch strands_karl karl_people.launch"
tmux select-window -t $SESSION:5
tmux send-keys "roslaunch strands_karl karl_localization_only.launch"
tmux select-window -t $SESSION:6
tmux send-keys "rqt"
tmux select-window -t $SESSION:7
tmux send-keys "ssh scitos@bruxelles"

# Set default window
tmux select-window -t $SESSION:0

# Attach to session
tmux -2 attach-session -t $SESSION
tmux setw -g mode-mouse on
