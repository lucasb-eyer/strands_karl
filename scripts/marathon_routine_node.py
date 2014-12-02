#!/usr/bin/env python

import rospy
import random

from datetime import time, timedelta, datetime
from dateutil.tz import tzutc, tzlocal

from routine_behaviours.marathon_routine import MarathonRoutine
from routine_behaviours.patrol_routine import create_patrol_task
from task_executor.task_routine import time_less_than as timeless

class AachenMarathonRoutine(MarathonRoutine):
    def __init__(self, daily_start, evening_start, daily_end, tour_duration_estimate=None, idle_duration=rospy.Duration(5), tz=tzlocal()):
        super(MarathonRoutine, self).__init__(daily_start=daily_start, daily_end=daily_end, tour_duration_estimate=tour_duration_estimate, idle_duration=idle_duration)

        self.tz = tz
        self.day_random_nodes = []
        self.night_random_nodes = []
        self.evening_start = evening_start

    def on_idle(self):
        random_nodes = list(self.day_random_nodes if datetime.now(self.tz).timetz() < self.evening_start else self.night_random_nodes)

        rospy.loginfo('Idle for too long, generating a random waypoint task')
        self.add_tasks([create_patrol_task(random.choice(random_nodes))])

if __name__ == '__main__':
    rospy.init_node("marathon_routine")

    # start and end times -- all times should be in a particular timezone - local has stopped working!
    localtz = tzlocal()
    # localtz = tzutc()
    start = time(7,00, tzinfo=localtz)
    morning = time(9,15, tzinfo=localtz)
    evening = time(16,00, tzinfo=localtz)
    end = time(17,00, tzinfo=localtz)

    # how long [in seconds] to stand idle before doing something
    idle_duration=rospy.Duration(10)

    # how long [in seconds] do you want it to take to do a tour.
    # this must be greater than the time you think it will take!
    tour_duration_estimate = rospy.Duration(60 * 60)

    routine = AachenMarathonRoutine(daily_start=start, evening_start=evening, daily_end=end, 
        idle_duration=idle_duration, tour_duration_estimate=tour_duration_estimate, tz=localtz)

    routine.day_random_nodes = routine.all_waypoints_except([
        'DoorInsideIsolationCell',
        'RoomInsideIsolationCell',
        'DoorOutsideIsolationCell',
        'BabyStroller',
        'ExploraRoom',
    ])

    routine.night_random_nodes = ['Vojta', 'IshratMichael', 'DoorInside129', 'Umer', 'Station', 'RedLightDistrict']

    # Only our room until most people are there.
    routine.create_patrol_routine(waypoints=routine.night_random_nodes,
        daily_start=start,
        daily_end=morning,
        repeat_delta=timedelta(minutes=15)
    )

    # then all of the rooms mid-day.
    routine.create_patrol_routine(waypoints=routine.all_waypoints(),
        daily_start=morning,
        daily_end=evening,
        repeat_delta=timedelta(minutes=60)
    )

    # And again, only our room in the evening.
    routine.create_patrol_routine(waypoints=routine.night_random_nodes,
        daily_start=evening,
        daily_end=end,
        repeat_delta=timedelta(minutes=15)
    )

    # do 3d scans
    scan_waypoints = ['RedLightDistrict', 'IshratMichael', 'MakeSammich', 'DogPflanzi']
    routine.create_3d_scan_routine(waypoints=scan_waypoints, repeat_delta=timedelta(hours=2))

    # where to stop and what to tweet with the image
    #twitter_waypoints = [['MakeSammich', 'I\'m in the kitchen boi! #ERW2014 #RobotMarathon'],
    #                     ['WaitingForBastian', 'Waiting for the boss. #ERW2014 #RobotMarathon']]
    # routine.create_tweet_routine(twitter_waypoints, daily_start=time(23,00, tzinfo=localtz), daily_end=time(00,00, tzinfo=localtz))
    # routine.create_tweet_routine(twitter_waypoints, image_topic="")

    # the list of collections from the message_store db to be replicated
    # message_store_collections = ['heads','metric_map_data','rosout_agg','robot_pose','task_events','scheduling_problems','ws_observations','monitored_nav_events']
    # routine.message_store_entries_to_replicate(message_store_collections)

    # do rgbd recording for a minute at these places every hour
    rgbd_waypoints = ['MakeSammich', 'DogPflanzi', 'IshratMichael', 'RedLightDistrict', 'BrotherLaserjet', 'SecretSyerva']
    routine.create_rgbd_record_routine(waypoints=rgbd_waypoints, duration=rospy.Duration(60), repeat_delta=timedelta(hours=2))

    # the list of collections to be replicated
    # db = 'message_store'
    # collections = ['heads','metric_map_data','rosout_agg','robot_pose','task_events','scheduling_problems','ws_observations','monitored_nav_events', 'people_perception']
    # routine.message_store_entries_to_replicate(collections, db=db)

    # db = 'roslog'
    # collections = ['head_xtion_compressed_depth_libav', 'head_xtion_compressed_rgb_theora', 'head_xtion_compressed_rgb_compressed']
    # routine.message_store_entries_to_replicate(collections, db=db)

    # db = 'metric_maps'
    # collections = ['data', 'summary']
    # routine.message_store_entries_to_replicate(collections, db=db)

    routine.start_routine()

    rospy.spin()