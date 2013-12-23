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

- (void)enable:(BOOL)enable;

@property (nonatomic, weak) id <MBAActionDelegate> delegate;

@end
