#!/usr/bin/fish

set topics "/ptu/state"

if contains "head" $argv
  set topics "/head_xtion/rgb/camera_info" "/head_xtion/rgb/image_rect_color" $topics
  set topics "/head_xtion/depth/camera_info" "/head_xtion/depth/image_rect_meters" $topics
end

if contains "chest" $argv
  set topics "/chest_xtion/rgb/camera_info" "/chest_xtion/rgb/image_rect_color" $topics
  set topics "/chest_xtion/depth/camera_info" "/chest_xtion/depth/image_rect_meters" $topics
end

if contains "laser" $argv
  set topics "/scan" $topics
end

env ROS_MASTER_URI=http://karl:11311 bash -ic "rosbag record $topics -o /mnt/ffp/aaf/test"
