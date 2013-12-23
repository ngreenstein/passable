//
//  MBAStatusItemView.h
//  Menu Bar App
//
//  Created by Nathan Greenstein on 11/30/13.
//  Copyright (c) 2013 Nathan Greenstein. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MBAStatusItemView;
@protocol MBAStatusItemViewDelegate <NSObject>

- (void)clicked:(id)sender;
- (void)rightClicked:(id)sender;

@end

@interface MBAStatusItemView : NSView

@property (nonatomic, getter = isActive) BOOL active;
@property (nonatomic, getter = isHighlighted) BOOL highlighted;
@property (nonatomic) id <MBAStatusItemViewDelegate> delegate;

- (instancetype)initWithStatusItem:(NSStatusItem *)statusItem;

@end
