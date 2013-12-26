//
// PBLStatusItemView.m
// Passable
//
//  Created by Nathan Greenstein on 11/30/13.
//  Copyright (c) 2013 Nathan Greenstein. All rights reserved.
//

#import "PBLStatusItemView.h"

#import "PBLConstants.h"

@interface PBLStatusItemView ()

@property (nonatomic) NSString *title;
@property (nonatomic) NSStatusItem *statusItem;

@end

@implementation PBLStatusItemView

- (instancetype)initWithStatusItem:(NSStatusItem *)statusItem {
	CGFloat height = [NSStatusBar systemStatusBar].thickness;
	CGFloat width = statusItem.length;
	if (width == NSSquareStatusItemLength) {
		width = height;
	}
	NSRect frame = NSMakeRect(0.0, 0.0, width, height);
	
    self = [super initWithFrame:frame];
    if (self) {
		self.statusItem = statusItem;
    }
	return self;
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
	[self.statusItem drawStatusBarBackgroundInRect:dirtyRect withHighlight:self.isHighlighted];
	NSImage *icon = [self iconForCurrentStatus];
	[icon drawInRect:dirtyRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	
}

- (void)setHighlighted:(BOOL)highlighted {
	if (highlighted != _highlighted) {
		_highlighted = highlighted;
		[self setNeedsDisplay:YES];
	}
}

- (void)setActive:(BOOL)active {
	if (active != _active) {
		_active = active;
		[self setNeedsDisplay:YES];
	}
}

- (NSImage *)iconForCurrentStatus {
	NSString *imageName = [NSString stringWithFormat:@"%@%@%@", kMenuItemIconBaseName, self.isActive ? @"Active" : @"", self.isHighlighted ? @"Highlighted" : @""];
	return [NSImage imageNamed:imageName];
}

#pragma mark - Mouse Event Handling

- (void)mouseDown:(NSEvent *)theEvent {
	if (theEvent.type == NSLeftMouseDown) {
		[self.delegate clicked:self];
	}
}

- (void)rightMouseDown:(NSEvent *)theEvent {
	if (theEvent.type == NSRightMouseDown) {
		[self.delegate rightClicked:self];
	}
}

@end
