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

- (void)enableNow:(BOOL)enable {
	
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
	NSError *error;
	
	if (enable) {
		
		NSNumber *storedStart = [defaults valueForKey:kStoredDNDStartPrefKey];
		NSNumber *storedEnd = [defaults valueForKey:kStoredDNDEndPrefKey];
		
		[defaults removeObjectForKey:kStoredDNDStartPrefKey];
		[defaults removeObjectForKey:kStoredDNDEndPrefKey];
		
		// If the user doesn't have a schedule set, the values are nil, so we store -1 in that case
		// so we can distinguish between errors/data loss and the user not having a previous shcedule.
		
		if (!storedStart) {
			NSDictionary *errorInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to restore user's previous DND start time.", nil),
										NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Unable to find stored start time at defaults key '%@'.", nil), kStoredDNDStartPrefKey]};
			error = [NSError errorWithDomain:kErrorDomain code:kErrorStoredValueNotFound userInfo:errorInfo];
		} else if ([storedStart integerValue] >= 0) { // Leave it as nil if we stored it as -1 so we delete the key.
			newStart = (__bridge CFNumberRef)storedStart;
		}
		// Check if the user has updated their prefs manually and don't revert if they have.
		if ([currentStart isNotEqualTo:customStart]) {
			updateNotificationCenterPrefs = NO;
		}
		
		if (!storedEnd) {
			NSDictionary *errorInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to restore user's previous DND end time.", nil),
										NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Unable to find stored end time at defaults key '%@'.", nil), kStoredDNDEndPrefKey]};
			error = [NSError errorWithDomain:kErrorDomain code:kErrorStoredValueNotFound userInfo:errorInfo];
		} else if ([storedEnd integerValue] >= 0) {
			newEnd = (__bridge CFNumberRef)storedEnd;
		}
		if ([currentEnd isNotEqualTo:customEnd]) {
			updateNotificationCenterPrefs = NO;
		}
		
		if (![defaults synchronize]) {
			NSMutableDictionary *errorInfo = [@{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to clean up after re-enabling notifications.", nil),
												NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"Unable to sync NSUserDefaults to delete old start/end times.", nil)} mutableCopy];
			if (error) {
				NSLog(@"Uh oh. Multiple errors encountered when re-enabling notifications. Old error saved in new error's userInfo dict.");
				[errorInfo setObject:[error copy] forKey:kErrorOldErrorKey];
			}
			error = [NSError errorWithDomain:kErrorDomain code:kErrorUnableToSynchronizePrefs userInfo:errorInfo];
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
		
		if (![defaults synchronize]) {
			NSDictionary *errorInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to disable notifications.", nil),
										NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"Unable to sync NSUserDefaults to store old start/end times.", nil)};
			error = [NSError errorWithDomain:kErrorDomain code:kErrorUnableToSynchronizePrefs userInfo:errorInfo];
			updateNotificationCenterPrefs = NO; // Don't change to the new prefs if we can't save the old ones.
		}
	}
	
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

	[self.delegate action:self didEnable:enable withError:error];
}

- (NSString *)description {
	return NSLocalizedString(@"notifications", nil);
}

@end
