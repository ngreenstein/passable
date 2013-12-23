//
//  MBAScrollingAction.m
//  Menu Bar App
//
//  Created by Nathan Greenstein on 12/23/13.
//  Copyright (c) 2013 Nathan Greenstein. All rights reserved.
//

#import "MBAScrollingAction.h"

// This one is simple: set a GlobalDomain pref and call a private API to notify apps of the change.

// Private API that lets us change the scroll direction without requiring a restart.
typedef int CGSConnection;
extern CGSConnection _CGSDefaultConnection(void);
extern void CGSSetSwipeScrollDirection(const CGSConnection connection, BOOL natural);

@implementation MBAScrollingAction

- (void)enable:(BOOL)enable {
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSMutableDictionary *globalPrefs = [[defaults persistentDomainForName:NSGlobalDomain] mutableCopy];
    
    const CGSConnection connection = _CGSDefaultConnection();
    CGSSetSwipeScrollDirection(connection, enable);
    
    [globalPrefs setValue:[NSNumber numberWithBool:enable] forKey:@"com.apple.swipescrolldirection"];
    
    [defaults setPersistentDomain:globalPrefs forName:NSGlobalDomain];
	[defaults synchronize];
	
//	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"SwipeScrollDirectionDidChangeNotification" object:nil userInfo:nil]; // Doesn't look like this is necessary.
	
	[self.delegate action:self didEnable:enable withError:nil];
}

@end
