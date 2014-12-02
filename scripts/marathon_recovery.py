import smach
from monitored_navigation.recover_state_machine import RecoverStateMachine

import recover_nav_states as rns


class RecoverKarlNav(RecoverStateMachine):
    def __init__(self):
        RecoverStateMachine.__init__(self,input_keys=['goal','n_nav_fails'],output_keys=['goal','n_nav_fails'])
        
        self.sleep_and_retry = rns.SleepAndRetry()
        self.clear = rns.ClearCostmaps()
        self.backtrack = rns.Backtrack()
        self.nav_help = rns.Help()
        with self:
            smach.StateMachine.add('SLEEP_AND_RETRY',
                                   self.sleep_and_retry,
                                   transitions={'preempted':'preempted',
                                                'try_nav':'recovered_without_help',
                                                'do_other_recovery':'CLEAR'})
            smach.StateMachine.add('CLEAR',
                                   self.clear,
                                   transitions={'preempted':'preempted',
                                                'try_nav':'recovered_without_help',
                                                'do_other_recovery':'BACKTRACK'})
            smach.StateMachine.add('BACKTRACK',
                                   self.backtrack,
                                   transitions={'succeeded':'recovered_without_help',
                                                'failure':'NAV_HELP',
                                                'preempted':'preempted'})
            smach.StateMachine.add('NAV_HELP',
                                   self.nav_help,
                                   transitions={'recovered_with_help':'recovered_with_help', 
                                                'recovered_without_help':'recovered_without_help',
                                                'not_recovered_with_help':'not_recovered_with_help', 
                                                'not_recovered_without_help':'not_recovered_without_help', 
                                                'preempted':'preempted'})