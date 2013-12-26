//
// PBLAction.h
// Passable
//
//  Created by Nathan Greenstein on 12/23/13.
//  Copyright (c) 2013 Nathan Greenstein. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PBLAction;
@protocol PBLActionDelegate <NSObject>

- (void)action:(PBLAction *)action didEnable:(BOOL)enabled withError:(NSError *)error;

@end

@interface PBLAction : NSObject

// Enable/disable the thing that this action controls (e.g. hot corners).
- (void)enable:(BOOL)enable;
// -enable: should be async whenever possible. This is the synchronous alternative, and what -enable: relies on.
- (void)enableNow:(BOOL)enable;

@property (nonatomic, weak) id <PBLActionDelegate> delegate;

@end
