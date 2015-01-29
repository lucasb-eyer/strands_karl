**PLEASE** create pull-requests if you had to do something differently. It's as easy as selecting the file in github and clicking on the pencil button in the top right corner, so there really is no excuse!

Basics
======

From [the wiki](https://github.com/strands-project-releases/strands-releases/wiki)

```bash
$ wget -qO- http://lcas.lincoln.ac.uk/repos/public.key | sudo apt-key add -
$ sudo apt-add-repository http://lcas.lincoln.ac.uk/repos/release
$ sudo apt-get update
```

Need to remove this because some auto-dependency stuff doesn't work:

```bash
$ sudo apt-get autoremove --purge libqwt-dev
```

Then, install ALL the things:

```bash
$ sudo apt-get install ros-hydro-strands-robot
$ sudo apt-get install ros-hydro-openni-wrapper
$ sudo apt-get install ros-hydro-scitos-bringup
```

TODO: remove these soon (will be in strands-robot)

Organization
============

Stuff installed via apt-get goes to `/opt/ros/hydro`. To see which files a package installed, run
`dpkg -L package-name`. Nodes (i.e. an executable file or python script) are usually installed into
`/opt/ros/hydro/lib/PACKAGE_NAME/` and launchfiles into `/opt/ros/hydro/share/PACKAGE_NAME`.

Stuff which you're working on should reside in an [`~/overlay`](http://lmgtfy.com/?q=ros+overlay)
in your home directory.

For finding the github repo which a ROS package resides in, look at [this file](https://github.com/strands-project/rosdistro/blob/strands-devel/hydro/distribution.yaml).

If you want to search for code, I've cloned ALL the repos into `~strands/ALL_THE_FUCKING_STRANDS`,
to update it from time to time using my ninja-foo'd
`find ~strands/ALL_THE_FUCKING_STRANDS -type d -mindepth 1 -maxdepth 1 -exec git --git-dir={}/.git --work-tree={} pull origin master \;`

Side-PCs
========

X-Server
--------

Besides the networking specified further down, configure the side-pc's just like the main one,
with the addition of installing nvidia drivers.

If you want to be able to hotplug a screen on their GPU, you also need to run the following once:

```bash
$ sudo nvidia-xconfig --allow-empty-initial-configuration
```

Clock-Sync
----------

The clocks of the side-pcs need to stay in sync with that of the main pc, or ROS will get mad.
This can be done using the `chrony` tool.

First, on the main PC:

```bash
$ sudo apt-get autoremove --purge ntpdate
$ sudo apt-get install chrony
```

Then, on each of the side-pcs:

```bash
$ sudo ntpdate karl
$ sudo apt-get autoremove --purge ntpdate
$ sudo apt-get install chrony
```

Then, replace the servers in `/etc/chrony.chrony.conf` by:

```
server karl minpoll 0 maxpoll 5 maxdelay .05
```

(I took that from the PR2 manuals, may need to tweak.)

And restart chrony with `sudo /etc/init.d/chrony restart`.

Networking
==========

We bought a switch (Netgear GS108), connected the on-board pc (`karl`) and the side-pcs
(`amsterdam` and `bruxelles`) to it, as well as the two AVT manta cameras.

1. Get `karl` connected to the internet via wifi.
2. In `karl`'s NetworkManager, choose the interface which is connected (`eth0` or `eth1`) and,
   in the `IPv4 Settings` tab, choose `Shared to other computers`.
3. Click on `Connection Information` in the NetworkManager, note that connection's
   `IP Address` and `Subnet Mask`.
4. On both the side-pcs, set the `IPv4 Settings` to `Manual`, choose an IP in the same subnet as `karl`,
   the same `Netmask`, and use aforenoted IP Address as both `Gateway` and `DNS servers`.
5. For reasons unbeknownst to me, you can access the side-pcs by their name suffixed with `.local`,
   e.g. `bruxelles.local`. When using the `<machine>` tag, ROS doesn't like that, thus you need to
   add an entry for each of the side pcs to `karl`'s `/etc/hosts` file.
6. Make sure there's passwordless ssh from `karl` to both sidepcs by creating a passwordless keypair
   for `karl` and push the public key to the side-pcs. See google.
7. Add the side-pcs to your `known_hosts` file: `ssh-keyscan bruxelles.local >> ~/.ssh/known_hosts`.
8. When sshing from a different pc, run `ssh karl` to connect to the main PC on Karl, and then `ssh scitos@bruxelles.local` to connect to the bruxelles side PC.

**If you launch anything remotely**, make sure `ROS_MASTER_URI` is set on the *launching* pc.

Firmware update
===============

@nilsbore:

> We are having the same problems still with the new driving firmware. In particular, the current minimum rotational velocity is too high and max rotational acceleration is too low, but there are other problems still, seems to be related to acceleration. In other words, upgrading the firmware seems to require tuning these parameters. Me and @RaresAmbrus are trying to find a good configuration. Might be of interest to @BFALacerda @lucasb-eyer

MongoDB
=======

Need to create an empty directory located at `/opt/strands/mongodb_store` to which the `strands`
user has write permissions:

```bash
$ sudo mkdir -p /opt/strands/mongodb_store
$ sudo chown -R strands:strands /opt/strands/
$ sudo chmod g+w /opt/strands/
```

Then, you can launch the mongodb_store passing that as a parameter, or put it in your launchfile.

```bash
$ roslaunch mongodb_store mongodb_store.launch db_path:=/opt/strands/mongodb_store
```

First, let it run, even if it complains. It needs some time to initialize (pre-allocate disk space)
and will connect once the initialization is done.

MIRA
====

We still need to have the MIRA license that were shipped with the robot located in `/opt/MIRA-licenses`.

Udev-rules
==========

- `/etc/udev/rules.d/72-persistent-can.rules`

    ```
    KERNEL=="ttyUSB?", ENV{ID_VENDOR}=="MetraLabs_GmbH", ENV{ID_MODEL}=="SCITOS_MCU", ENV{MINOR}=="2", NAME="can"
    ```

- `/etc/udev/rules.d/72-persistent-laser.rules`

    ```
    KERNEL=="ttyUSB?", ENV{ID_VENDOR}=="MetraLabs_GmbH", ENV{ID_MODEL}=="SCITOS_MCU", ENV{MINOR}=="0", NAME="laser"
    ```

- `/etc/udev/rules.d/73-persistent-joystick.rules`

    ```
    KERNEL=="js?", ENV{ID_VENDOR}=="Logitech", ENV{ID_MODEL}=="Wireless_Gamepad_F710", NAME="input/rumblepad"
    ```

Moving the PTU
==============

Needs the `flir_pantilt_d46/ptu46.launch` launchfile running. Then, on the commandline, control via:

```
rostopic pub --once /ptu/cmd sensor_msgs/JointState "header:
  seq: 0
  stamp: {secs: 0, nsecs: 0}
  frame_id: ''
name: ['tilt', 'pan']
position: [1, 0.5]
velocity: [0.6, 0.6]
effort: [1, 1]" 
```

Pressing `<tab>` after the message type helps.

**TODO**: Look into `joint_state_publisher`.

Kinects
=======

Reboot the side-pcs to enter their BIOS. There, in the advanced USB settings,
set `xHCI` to `Disabled`.

The `karl_cams.launch` file takes care of starting the necessary stuff (`openni_wrapper/main.launch`)
on each of the side-pcs.

If there is an error message about `escalating to SIGTERM` when stopping this launchfile, you'll
have to run `rosnode cleanup` before launching it again if you don't want to wreak havok.

If there is no publication on the chest's cam, you need to stop the launchfile, *physically* plug
out and back in the xtion and start the launchfile again. TODO: debug this. wtf? We have the same
problem in SPENCER.

Navigation
==========

TODO: remove these soon (will be in strands-robot)

```bash
$ sudo apt-get install ros-hydro-topological-utils
```

Mapping
-------

For creating a map just follow the [standard ROS map creation tutorial](http://wiki.ros.org/slam_gmapping/Tutorials/MappingFromLoggedData).

If such is your wish, you can crop the map, but don't forget to adapt the YAML file accordingly,
specifically the `origin` entry using the `m = pixels * resolution` formula.

Docking
-------

Instructions are in [the README.md](https://github.com/strands-project/scitos_apps/tree/hydro-devel/scitos_docking), but do `roslaunch scitos_docking charging_mux.launch` first.

(TODO: Move the `~/.charging.yaml` file to `/opt/strands`? Need to DI the param tho.)

Obstacle/Holes avoidance
------------------------

First, calibrate the chest camera by following [this README.md](https://github.com/strands-project/scitos_common).
Basically, it's just `rosrun calibrate_chest calibrate_chest` when almost only the floor is visible
in the chest cam. Have the datacentre running for storing the calibration in there.
It will open a viewer-window showing the "ground plane" and an axis for the camera. Close it.

### Cliffs

That's any kind of "holes" in the ground, like stairs. Those are detected mainly by
`strands_movebase/mirror_floor_points`, which is launched by `move_base` and publishes a pointcloud
at `/move_base/points_cliff`.

### Obstacles

Anything seen by the `chest_xtion` and higher than 5cm above the ground becomes an obstacle, which
is added to the `/move_base/local_costmap/costmap` by whom? `remove_edges_cloud`? The output
pointcloud `/move_base/points_obstacle` also always seems to contain anything? [TODO](https://github.com/strands-project/strands_movebase/blob/hydro-devel/strands_movebase/src/remove_edges_cloud.cpp#L22).

Monitored Navigation
--------------------

TODO: For now, it's not taken in by the base distro so

```bash
$ sudo apt-get install ros-hydro-strands-recovery-behaviours
```

It's being launched by `strands_navigation.launch` through `strands_recovery_behaviours/strands_monitored_nav.launch` and that should be all that's needed for strands.

TODO:
> to have these helpers you need to do roslaunch strands_ui strands_ui.launch
It's waiting for "a node that sets the main page for the webserver. I dont know which one will be doing it in the marathon system" @BFALacera

For details, again, see [the README.md](https://github.com/strands-project/strands_navigation/tree/hydro-devel/monitored_navigation), with [this default yaml file](https://github.com/strands-project/strands_recovery_behaviours/blob/hydro-devel/strands_recovery_behaviours/config/monitored_nav_config.yaml).

Topological Navigation
----------------------

In a topological map, nodes are locations (`pose`) on the corresponding metric map along with influence areas (`verts`) around them. Nodes are connected by edges which hold an `action` which defines how the robot "walks" that edge, being `move_base` for regular moving and `doorPassing` for, well, passing doors.

Creating a Topological Map
--------------------------

TODO Jaime wanted to write [a README.md](https://github.com/Jailander/strands_navigation/blob/hydro-devel/topological_navigation/README.md) about it.

For option 3 with Rviz, which is still missing from the README:

Create an empty topological map in the mongodb, the first name is the name of the new topological map,
the second one is (currently unused) the name of the metric map it's based on:

```bash
$ roslaunch topological_utils empty_topological_map.launch map:=umic_1st_floor
```

The map is not *really* empty, as it contains the `Station` and `ChargingPoint` nodes. The latter is placed at the origin of the map and the former (`Station`) 1.2m left to it.
You can edit nodes in rviz via the `/umic_1st_floor_add_rm_node/update` and `/umic_1st_floor_markers/update` topics.
The former is for adding new nodes by driving the robot there and then clicking on the green box, while the second one is to move and turn existing nodes.
For each door, you need one node on each side of the door, right in front of it and facing it. These need to be connected by a bidirectional `doorPassing` edge.

At creation time, a bidirectional edge will be created between two nodes if the distance between them is lower than a certain threshold. You can remove edges by clicking on them in rviz in the `/umic_1st_floor_edges/update` topic, but I don't know of a way to add edges in rviz.
So your best bet is exporting the map to a file, edit that file, clear the mongodb and reimport the file:

```bash
$ rosrun topological_utils map_export.py umic_1st_floor /opt/strands/maps/umic_1st_floor.tplg`
$ mongo localhost:62345/message_store
> db.topological_maps.remove({map: "umic_1st_floor"})
$ rosrun topological_utils insert_map.py /home/novak/overlay/src/strands_karl/resources/maps/umic_1st_floor.tplg umic_1st_floor umic_1st_floor

```

Whenever you change the map in mongodb, you need to ask for it to be republished by running `rosrun topological_utils topological_map_update.py`, though see [strands-project/strands_navigation#139](https://github.com/strands-project/strands_navigation/issues/139)

Finally, you can change the influence zones with `/umic_1st_floor_zones/update`.

Topological Navigation
----------------------

The important stuff is being started by `strands_navigation.launch`. This implies all debugging output concerning navigation is to be found there.
BUT for now, you need to `roslaunch strands_ui strands_ui.launch` first, because it defines recovery behaviour which is a hard dependency of `monitored_navigation` which in turn is a hard dependency of `topological_navigation`.

TODO
For starting the new (better?) door-passing behavior, do `rosrun door_pass door_pass.py` after the navigation.

To send the robot to a topological node, `rosrun topological_navigation nav_client.py NodeName` should do, and it will only exit when the node is reached or the robot gave up.

Debugging navigation
--------------------

- Sending a `2D Nav Goal` in rviz will use the `move_base` and thus bypass the topological navigation. This can be used to test if movement works at all.

Perception People
-----------------

Very basic command to start it:
```bash
$ ROS_MASTER_URI=http://karl:11311 roslaunch perception_people_launch people_tracker_robot.launch  gh_queue_size:=11 vo_queue_size:=22 ubd_queue_size:=33 pt_queue_size:=44 load_params_from_file:=true
```

Mainly this comes from the [readdme](https://github.com/strands-project/strands_perception_people/tree/hydro-devel/perception_people_launch)


Task Scheduling
===============

https://github.com/strands-project/strands_management/wiki/Marathon-2014

@hawesie

> BUT, i do have a new schedule routine to get your robots patrolling:
> `sudo apt-get install ros-hydro-routine-behaviours`
> `rosrun routine_behaviours patroller_routine_node.py`
> This should bring back the routine stuff for charging etc that we had int he deployments
> (assuming everything up to and including top nav is running)



> @jailander: how continous is continous patrolling Linda visits all the nodes once and then goes to the node next to the charging station and stays there saying I need a task and nothing happens
> @hawesie: Which script are you running?
> @jailander: roslaunch task_executor continuous-patrolling.launch
> @hawesie: Weird. That one shouldn't do idle stuff or return to the charger. Have you tried the other one I posted?
```
sudo apt-get install ros-hydro-routine-behaviours
rosrun routine_behaviours patroller_routine_node.py
```
> Either way the continuous patrolling one is a bit of a hack anyway, and I thought it should run badly but indefinitely,.
> Ok, I'll try that
> With that the robot should run a patrol then if it gets idle it should pick a random node to visit.
> You also need to run the roslaunch task_executor task-scheduler.launch


TODO: shouldn't need:

```bash
$ sudo apt-get install ros-hydro-wait-action
```


GUIs
====

They are generally created as javascript-powered webpages that can call ROS things through a websocket.
See the [README.md](https://github.com/strands-project/strands_ui) for how to create some.

Text-to-Speech
--------------

See the [README.md](https://github.com/strands-project/strands_ui/tree/hydro-devel/mary_tts) for how to set voices and language.

Marathon 2014 GUI:
------------------

Largely undecided. @cdondrup created a nice one [for the museum](https://github.com/LCAS/marathon_gui).
There's the one from [last year](https://github.com/strands-project/strands_deployment/tree/master/y1_interfaces) and @marc-hanheide [is working on one](https://github.com/strands-project/strands_interfaces) which is served at `http://localhost:9091/`.

3D Room Mapping
===============

```bash
$ sudo apt-get install ros-hydro-cloud-merge
$ ROS_MASTER_URI=http://karl:11311 roslaunch cloud_merge mapping.launch
$ ROS_MASTER_URI=http://karl:11311 roslaunch scitos_ptu ptu_action_server_metric_map.launch
```

Recording video streams
=======================

[README](https://github.com/strands-project/data_compression/tree/hydro-devel/mongodb_openni_compression)

Needs to be built from source for now:

```bash
$ sudo apt-get install yasm
$ git clone https://github.com/strands-project/data_compression.git
$ sudo apt-get install ros-hydro-mongodb-log
$ ROS_MASTER_URI=http://karl:11311 roslaunch mongodb_openni_compression record_server.launch
```

Compressed and into the mongodb:

```bash
$ sudo apt-get install ros-hydro-mongodb-openni-compression
```

For the cool
============

TODO: Mainly @cdondrup stuff.

- `ros-hydro-strands-visualise-speech` (blink LEDs when talking.)
- The look at people thing

@cdondrup:

> I do @PDuckworth. I guess starting it with load_params_from_file:=true will fix your issue
> This is due to me misunderstanding on how the datacentre will be set-up and used in the project. Sorry. Will be fixed at some point
> Please also make sure to run it with log:=true as well to save the stuff to your datacentre

> roslaunch perception_people_launch people_tracker_robot.launch load_params_from_file:=true log:=true

Marathon mileage reporting
--------------------------

Configured in `~/.marathon_auth`.

```bash
$ rosrun marathon_reporter mileage_monitor.py
```

Packaging
=========

> @cburbridge: should i put python package dependencies in a package.xml file? If so, what format.
> For example, I need python-requests as a runtime
> where do i lookup what to put?

> @marc-hanheide: check out `rosdep db | grep YOUR_PACKAGE`
> you need to put the rosdep key
> not the package itself

> thanks, i think that is what i have always done wrong

> if it doesn’t exist, add it to https://github.com/strands-project/rosdistro/blob/strands-devel/rosdep/strands.yaml
> if it doesn’t exist as a ubuntu package at all, we need to create one for it
