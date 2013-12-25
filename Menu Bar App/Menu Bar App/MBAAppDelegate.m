//
//  MBAAppDelegate.m
//  Menu Bar App
//
//  Created by Nathan Greenstein on 11/30/13.
//  Copyright (c) 2013 Nathan Greenstein. All rights reserved.
//

#import "MBAAppDelegate.h"

#import "MBAStatusItemView.h"
#include "MBAConstants.h"

#import "MBAHotCornersAction.h"
#import "MBAScrollingAction.h"
#import "MBANotificationsAction.h"

@interface MBAAppDelegate () <NSMenuDelegate, MBAStatusItemViewDelegate, MBAActionDelegate>

@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) MBAStatusItemView *statusItemView;

@property (weak) IBOutlet NSMenu *menu;
@property (nonatomic, getter = isShowingMenu) BOOL showingMenu;
@property (weak) IBOutlet NSMenuItem *hotCornersMenuItem;
@property (weak) IBOutlet NSMenuItem *scrollingMenuItem;
@property (weak) IBOutlet NSMenuItem *notificationCenterMenuItem;


@property (nonatomic) BOOL controlHotCorners;
@property (nonatomic) BOOL controlScrolling;
@property (nonatomic) BOOL controlNotifications;

@property (nonatomic) NSArray *controlledActions;
@property (nonatomic) MBAHotCornersAction *hotCornersAction;
@property (nonatomic) MBAScrollingAction *scrollingAction;
@property (nonatomic) MBANotificationsAction *notificationsAction;

@end

@implementation MBAAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	self.enabled = NO;
	
	NSStatusItem *statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:22.0];
	[statusItem setEnabled:YES];
	self.statusItem = statusItem;
	MBAStatusItemView *statusItemView = [[MBAStatusItemView alloc] initWithStatusItem:self.statusItem];
	statusItemView.highlighted = NO;
	statusItemView.delegate = self;
	self.statusItem.view = statusItemView;
	self.statusItemView = statusItemView;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSDictionary *defaultPreferenceValues = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:kDefaultPreferencesFileName ofType:@"plist"]];
	[defaults registerDefaults:defaultPreferenceValues];
	
	self.controlHotCorners = [defaults boolForKey:kControlHotCornersPrefKey];
	self.hotCornersMenuItem.state = self.controlHotCorners ? NSOnState : NSOffState;
	self.controlScrolling = [defaults boolForKey:kControlScrollingPrefKey];
	self.scrollingMenuItem.state = self.controlScrolling ? NSOnState : NSOffState;
	self.controlNotifications = [defaults boolForKey:kControlNotificationsPrefKey];
	self.notificationCenterMenuItem.state = self.controlNotifications ? NSOnState : NSOffState;
	
	self.hotCornersAction = [[MBAHotCornersAction alloc] init];
	self.hotCornersAction.delegate = self;
	self.scrollingAction = [[MBAScrollingAction alloc] init];
	self.scrollingAction.delegate = self;
	self.notificationsAction = [[MBANotificationsAction alloc] init];
	self.notificationsAction.delegate = self;
	
	if ([defaults boolForKey:kShowIntroWindowPrefKey]) {
		NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Welcome to AppName!", nil) defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Click the AppName icon in the menu bar to turn it on and off. Control + click it or right-click it for more options.", nil)];
		[alert runModal];
		[defaults setBool:NO forKey:kShowIntroWindowPrefKey];
		[defaults synchronize];
	}
	
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	self.enabled = NO;
}

#pragma mark - MBAStatusItemViewDelegate Methods

- (void)clicked:(id)sender {
	self.enabled = !self.enabled;
}

- (void)rightClicked:(id)sender {
	[self showMenu:!self.isShowingMenu];
}

#pragma mark - NSMenu Stuff

- (void)showMenu:(BOOL)show {
	self.statusItemView.highlighted = show;
	self.showingMenu = show;
	if (show) {
		[self.statusItem popUpStatusItemMenu:self.menu];
	} else {
		[self.menu cancelTracking]; // Dismisses the menu
	}
}

- (IBAction)hotCornersClicked:(NSMenuItem *)sender {
	self.controlHotCorners = (sender.state != NSOnState); // Using != because the state isn't updated until later, so as a user turns it off the state is still on.
}
- (IBAction)naturalScrollingClciked:(NSMenuItem *)sender {
	self.controlScrolling = (sender.state != NSOnState);
}
- (IBAction)notificationCenterClicked:(NSMenuItem *)sender {
	self.controlNotifications = (sender.state != NSOnState);
}

- (IBAction)donateClicked:(NSMenuItem *)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://apple.com"]];
}
- (IBAction)aboutClicked:(id)sender {
	[NSApp orderFrontStandardAboutPanel:self];
}
- (IBAction)helpClicked:(NSMenuItem *)sender {
	[NSApp showHelp:self];
}
- (IBAction)quitClicked:(id)sender {
	[[NSApplication sharedApplication] terminate:self];
}

- (void)menuDidClose:(NSMenu *)menu {
	self.statusItemView.highlighted = NO;
	self.showingMenu = NO;
}

#pragma mark - Managing App Prefs

- (void)setControlHotCorners:(BOOL)controlHotCorners {
	if (_controlHotCorners != controlHotCorners) {
		_controlHotCorners = controlHotCorners;
		self.hotCornersMenuItem.state = controlHotCorners ? NSOnState : NSOffState;
		if (self.enabled) {
			[self.hotCornersAction enable:!controlHotCorners]; // If we are currently enabled, turn hot corners on/off now.
		}
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		if ([defaults boolForKey:kControlHotCornersPrefKey] != controlHotCorners) {
			[defaults setBool:controlHotCorners forKey:kControlHotCornersPrefKey];
			[defaults synchronize];
		}
	}
}

- (void)setControlScrolling:(BOOL)controlScrolling {
	if (_controlScrolling != controlScrolling) {
		_controlScrolling = controlScrolling;
		self.scrollingMenuItem.state = controlScrolling ? NSOnState : NSOffState;
		if (self.enabled) {
			[self.scrollingAction enable:!controlScrolling];
		}
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		if ([defaults boolForKey:kControlScrollingPrefKey] != controlScrolling) {
			[defaults setBool:controlScrolling forKey:kControlScrollingPrefKey];
			[defaults synchronize];
		}
	}
}

- (void)setControlNotifications:(BOOL)controlNotifications {
	if (_controlNotifications != controlNotifications) {
		_controlNotifications = controlNotifications;
		self.notificationCenterMenuItem.state = controlNotifications ? NSOnState : NSOffState;
		if (self.enabled) {
			[self.notificationsAction enable:!controlNotifications];
		}
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		if ([defaults boolForKey:kControlNotificationsPrefKey] != controlNotifications) {
			[defaults setBool:controlNotifications forKey:kControlNotificationsPrefKey];
			[defaults synchronize];
		}
	}
}

#pragma mark - Turning On and Off

- (void)setEnabled:(BOOL)enabled {
	if (enabled != _enabled) {
		_enabled = enabled;
		
		[self.controlledActions enumerateObjectsUsingBlock:^(MBAAction *action, NSUInteger index, BOOL *stop) {
			[action enable:!enabled];
		}];
		
		self.statusItemView.active = enabled;
	}
}

- (NSArray *)controlledActions {
	NSMutableArray *actions = [[NSMutableArray alloc] init];
	if (self.controlHotCorners) {
		[actions addObject:self.hotCornersAction];
	}
	if (self.controlScrolling) {
		[actions addObject:self.scrollingAction];
	}
	if (self.controlNotifications) {
		[actions addObject:self.notificationsAction];
	}
	return [actions copy];
}

#pragma mark - MBAActionDelegate Methods

- (void)action:(MBAAction *)action didEnable:(BOOL)enabled withError:(NSError *)error {
	if (error) {
		NSLog(@"Error %li occured when %@ the action '%@'.", (long)error.code, enabled ? @"enabling" : @"disabling", action.description);
	}
}

@end
