//
//  MBAAction.h
//  Menu Bar App
//
//  Created by Nathan Greenstein on 12/23/13.
//  Copyright (c) 2013 Nathan Greenstein. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MBAAction;
@protocol MBAActionDelegate <NSObject>

- (void)action:(MBAAction *)action didEnable:(BOOL)enabled withError:(NSError *)error;

@end

@interface MBAAction : NSObject

// Enable/disable the thing that this action controls (e.g. hot corners).
- (void)enable:(BOOL)enable;
// -enable: should be async whenever possible. This is the synchronous alternative, and what -enable: relies on.
- (void)enableNow:(BOOL)enable;

@property (nonatomic, weak) id <MBAActionDelegate> delegate;

@end
