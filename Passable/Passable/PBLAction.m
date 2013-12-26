//
//  PBLAction.m
//  Passable
//
//  Created by Nathan Greenstein on 12/23/13.
//  Copyright (c) 2013 Nathan Greenstein. All rights reserved.
//

#import "PBLAction.h"

@implementation PBLAction

- (void)enable:(BOOL)enable {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[self enableNow:enable];
	});
}

- (void)enableNow:(BOOL)enable {
	// Subclasses do the actual work to enable/disable here, e.g. changing a system preference file.
	// Don't forget to make the delgate call.
	
	[self.delegate action:self didEnable:enable withError:nil];
}

@end
