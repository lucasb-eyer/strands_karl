#!/bin/bash

SESSION=main
tmux -2 new-session -d -s $SESSION

message () { tmux send-keys " #   ===  $1  ===" C-m;  };

split_4 () { tmux split-window -v; tmux select-pane -t 1; tmux split-window -h; tmux select-pane -t 0; tmux split-window -h; tmux select-pane -t 0; };
split_3 () { tmux split-window -v; tmux select-pane -t 1; tmux split-window -h; tmux select-pane -t 0; };
split_2 () { tmux split-window -v; tmux select-pane -t 0; };
pane () { tmux select-pane -t $1;  };
cmd () { tmux send-keys "$1"; };
cmd_do () { tmux send-keys "$1" C-m; };
window () { tmux select-window -t $SESSION:$1;  };


# Don't let windows be renamed; I give them a name for a reason, damnit!
tmux set-option -g allow-rename off
tmux set-window-option -g automatic-rename off

tmux new-window -t $SESSION:0 -n 'core'
tmux new-window -t $SESSION:1 -n 'db'
tmux new-window -t $SESSION:2 -n 'robot'
tmux new-window -t $SESSION:3 -n 'cams'
tmux new-window -t $SESSION:4 -n 'ui'
tmux new-window -t $SESSION:5 -n 'nav'
tmux new-window -t $SESSION:6 -n 'ppl'
tmux new-window -t $SESSION:7 -n 'sched'

# Sometimes 2 is not enough. (Avoids doubling commands; "waits for the shells".)
sleep 3

window 0
  split_2
    pane 0
      cmd_do "roscore"
      tmux resize-pane -U 30
    pane 1 
      cmd_do "htop"

window 1
  cmd  "HOSTNAME=bruxelles roslaunch strands_bringup strands_core.launch machine:=bruxelles user:=scitos db_path:=/mnt/ffp1/mongodb_store"

window 2
  cmd 'roslaunch strands_bringup strands_robot.launch with_mux:=false js:=/dev/input/rumblepad laser:=/dev/laser scitos_config:=`rospack find strands_karl`/resources/SCITOSDriver.xml with_magnetic_barrier:=false'

window 3
  split_2
     pane 0
        cmd_do "ssh a"
        cmd_do "tmux"
        sleep 3
        cmd "roslaunch openni2_launch openni2.launch camera:=chest_xtion depth_registration:=false publish_tf:=false debayer_processing:=true"
     pane 1
        cmd_do "ssh b"
        cmd_do "tmux"
        sleep 3
        cmd "roslaunch openni2_launch openni2.launch camera:=head_xtion depth_registration:=true publish_tf:=false debayer_processing:=true"

window 4
  cmd "HOST_IP=192.168.42.42 roslaunch strands_bringup strands_ui.launch mary_machine:=amsterdam mary_machine_user:=scitos"

window 5
  cmd 'roslaunch strands_karl karl_navigation.launch'

window 6
  split_4
    pane 0
      message "People Perception"
      # image_rect (OpenNI2) == image_rect_meters (openni_wrapper)
      cmd "roslaunch perception_people_launch people_tracker_robot.launch machine:=bruxelles user:=scitos depth_image:=/depth/image_rect"
    pane 1
      message "UBD Logging"
      cmd "roslaunch vision_people_logging logging_ubd.launch machine:=bruxelles user:=scitos"
    pane 2
      message "Robot Pose Logging"
      cmd "rosrun mongodb_log mongodb_log.py /robot_pose"
    pane 3
      message "Spare people terminal..."

window 7
  split_4
    pane 0
      message "MDP & Scheduler & Executor"
      cmd "roslaunch task_executor task-scheduler-mdp.launch"
    pane 1
      message "Routine"
      cmd "roslaunch review_bringup review_routine.launch"
    pane 2
      message "Schedule Status"
      cmd "rosrun task_executor schedule_status.py"
    pane 3
      message "Spare scheduling terminal..."
      


# Set default window
tmux select-window -t $SESSION:0

# Attach to session
tmux -2 attach-session -t $SESSION

tmux setw -g mode-mouse off
