//
//  PBLScrollingAction.m
//  Passable
//
//  Created by Nathan Greenstein on 12/23/13.
//  Copyright (c) 2013 Nathan Greenstein. All rights reserved.
//

#import "PBLScrollingAction.h"

#import "PBLConstants.h"

// This one is simple: store the user's old direction and use a private API to set the new one.

// Private API that lets us change the scroll direction without requiring a restart.
typedef int CGSConnection;
extern CGSConnection _CGSDefaultConnection(void);
extern void CGSSetSwipeScrollDirection(const CGSConnection connection, BOOL natural);

@implementation PBLScrollingAction

- (void)enableNow:(BOOL)enable {
	
	BOOL newDirectionToSet = enable;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSError *error;
	
	if (enable) {
		
		id oldValue = [defaults objectForKey:kStoredScrollDirectionPrefKey];
		if (oldValue) {
			BOOL oldBool = [oldValue boolValue];
			newDirectionToSet = oldBool;
			[defaults removeObjectForKey:kStoredScrollDirectionPrefKey];
		} else {
			NSDictionary *errorInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to restore user's previous scroll direction setting.", nil),
										NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Unable to find stored scroll direction at defaults key '%@'.", nil), kStoredScrollDirectionPrefKey]};
			error = [NSError errorWithDomain:kErrorDomain code:kErrorStoredValueNotFound userInfo:errorInfo];
		}
		
	} else {
		
		NSDictionary *globalPrefs = [defaults persistentDomainForName:NSGlobalDomain];
		BOOL naturalCurrentlyEnabled = [[globalPrefs valueForKey:kGlobalScrollingDirectionKey] boolValue];
		[defaults setBool:naturalCurrentlyEnabled forKey:kStoredScrollDirectionPrefKey];
		
	}
    
    const CGSConnection connection = _CGSDefaultConnection();
    CGSSetSwipeScrollDirection(connection, newDirectionToSet);
	
	if (![defaults synchronize]) {
		NSMutableDictionary *errorInfo = [@{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to save preferences while enabling or disabling natural scrolling.", nil),
											NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"Unable to sync NSUserDefaults to when enabling or disabling natural scrolling..", nil)} mutableCopy];
		if (error) {
			NSLog(@"Uh oh. Multiple errors encountered when enabling or disabling natural scrolling. Old error saved in new error's userInfo dict.");
			[errorInfo setObject:[error copy] forKey:kErrorOldErrorKey];
		}
		error = [NSError errorWithDomain:kErrorDomain code:kErrorUnableToSynchronizePrefs userInfo:errorInfo];
	}
	[self.delegate action:self didEnable:enable withError:error];
}

- (NSString *)description {
	return NSLocalizedString(@"natural scrolling direction", @"action description");
}

@end
