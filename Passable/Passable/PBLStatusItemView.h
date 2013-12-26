//
//  PBLStatusItemView.h
//  Passable
//
//  Created by Nathan Greenstein on 11/30/13.
//  Copyright (c) 2013 Nathan Greenstein. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PBLStatusItemView;
@protocol PBLStatusItemViewDelegate <NSObject>

- (void)clicked:(id)sender;
- (void)rightClicked:(id)sender;

@end

@interface PBLStatusItemView : NSView

@property (nonatomic, getter = isActive) BOOL active;
@property (nonatomic, getter = isHighlighted) BOOL highlighted;
@property (nonatomic) id <PBLStatusItemViewDelegate> delegate;

- (instancetype)initWithStatusItem:(NSStatusItem *)statusItem;

@end
