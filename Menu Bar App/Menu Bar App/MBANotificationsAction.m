//
//  MBANotificationsAction.m
//  Menu Bar App
//
//  Created by Nathan Greenstein on 12/23/13.
//  Copyright (c) 2013 Nathan Greenstein. All rights reserved.
//

#import "MBANotificationsAction.h"

#import "MBAConstants.h"

@implementation MBANotificationsAction

// The best hack I've found to do this is to temporarily set the automatic DND schedule (usually used to disable notifications at night)
// to go from 3:01 AM to 3:00 AM and then restore the user's actual settings after the app is disabled.
// This means that there will be one minute at 3:00 AM where notifications are enabled, which isn't ideal.
// [TODO ngreenstein] Add a timer to change the gap minute to something else before it is hit.

- (void)enable:(BOOL)enable {
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSNumber *currentStart = (__bridge NSNumber *)CFPreferencesCopyValue(kNotificationCenterDNDStartPrefKey,
																			 kNotificationCenterPrefsDomain,
																			 kCFPreferencesCurrentUser,
																			 kCFPreferencesCurrentHost);
	NSNumber *currentEnd = (__bridge NSNumber *)CFPreferencesCopyValue(kNotificationCenterDNDEndPrefKey,
																		   kNotificationCenterPrefsDomain,
																		   kCFPreferencesCurrentUser,
																		   kCFPreferencesCurrentHost);
	
	NSNumber *customStart = [NSNumber numberWithUnsignedInteger:kNotificationCenterDNDStartTime];
	NSNumber *customEnd = [NSNumber numberWithUnsignedInteger:kNotificationCenterDNDEndTime];
	
	CFNumberRef newStart =  nil;
	CFNumberRef newEnd = nil;
	
	BOOL updateNotificationCenterPrefs = YES;
	
	if (enable) {
		
		NSNumber *storedStart = [defaults valueForKey:kStoredDNDStartPrefKey];
		NSNumber *storedEnd = [defaults valueForKey:kStoredDNDEndPrefKey];
		
		[defaults removeObjectForKey:kStoredDNDStartPrefKey];
		[defaults removeObjectForKey:kStoredDNDEndPrefKey];
		
		// If the user doesn't have a schedule set, the values are nil, so we store -1 in that case
		// so we can distinguish between errors/data loss and the user not having a previous shcedule.
		// [TODO ngreenstein] Update this to use NSError and report it to delegate.
		
		if (!storedStart) {
			NSLog(@"!!! ERROR: Stored DND start time not found.");
			updateNotificationCenterPrefs = NO;
		} else if ([storedStart integerValue] >= 0) { // Leave it as nil if we stored it as -1 so we delete the key.
			newStart = (__bridge CFNumberRef)storedStart;
		}
		if ([currentStart isNotEqualTo:customStart]) {
			NSLog(@"!!! ERROR: User changed their DND start time, so we won't revert.");
			updateNotificationCenterPrefs = NO;
		}
		
		if (!storedEnd) {
			NSLog(@"!!! ERROR: Stored DND end time not found.");
			updateNotificationCenterPrefs = NO;
		} else if ([storedEnd integerValue] >= 0) {
			newEnd = (__bridge CFNumberRef)storedEnd;
		}
		if ([currentEnd isNotEqualTo:customEnd]) {
			NSLog(@"!!! ERROR: User changed their DND end time, so we won't revert.");
			updateNotificationCenterPrefs = NO;
		}
		
	} else {
		
		if (!currentStart) {
			currentStart = [NSNumber numberWithInteger:-1];
		}
		if (!currentEnd) {
			currentEnd = [NSNumber numberWithInteger:-1];
		}
		
		[defaults setValue:currentStart forKey:kStoredDNDStartPrefKey];
		[defaults setValue:currentEnd forKey:kStoredDNDEndPrefKey];
		
		newStart = (__bridge CFNumberRef)customStart;
		newEnd = (__bridge CFNumberRef)customEnd;
	}
	
	[defaults synchronize];
	
	if (updateNotificationCenterPrefs) {
		CFPreferencesSetValue(kNotificationCenterDNDStartPrefKey, newStart, kNotificationCenterPrefsDomain, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
		CFPreferencesSetValue(kNotificationCenterDNDEndPrefKey, newEnd, kNotificationCenterPrefsDomain, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
		CFPreferencesSynchronize(kNotificationCenterPrefsDomain, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
	
		// Tell the NC app to update its menu bar icon, etc without having to restart it.
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.apple.notificationcenterui.dndprefs_changed"
																	   object:nil
																	 userInfo:nil
														   deliverImmediately:YES];
	}
	
	[self.delegate action:self didEnable:enable withError:nil];
}

- (NSString *)description {
	return @"Enable/disable Do Not Disturb mode in Notification Center.";
}

@end
