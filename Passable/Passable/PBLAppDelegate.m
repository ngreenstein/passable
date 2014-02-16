//
//  PBLAppDelegate.m
//  Passable
//
//  Created by Nathan Greenstein on 11/30/13.
//  Copyright (c) 2013 Nathan Greenstein. All rights reserved.
//

#import "PBLAppDelegate.h"

#import "PBLStatusItemView.h"
#include "PBLConstants.h"

#import "PBLHotCornersAction.h"
#import "PBLScrollingAction.h"
#import "PBLNotificationsAction.h"

#import "BWQuincyManager.h"
#import "BWQuincyUI.h"
#import "PFMoveApplication.h"
#import <CoreServices/CoreServices.h>

@interface PBLAppDelegate () <NSMenuDelegate, PBLStatusItemViewDelegate, PBLActionDelegate, BWQuincyManagerDelegate>

@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) PBLStatusItemView *statusItemView;

@property (weak) IBOutlet NSMenu *menu;
@property (nonatomic, getter = isShowingMenu) BOOL showingMenu;
@property (weak) IBOutlet NSMenuItem *hotCornersMenuItem;
@property (weak) IBOutlet NSMenuItem *scrollingMenuItem;
@property (weak) IBOutlet NSMenuItem *notificationCenterMenuItem;
@property (weak) IBOutlet NSMenuItem *openAtLoginMenu;
@property (weak) IBOutlet NSMenuItem *activateWhenOpenedMenu;


@property (nonatomic) BOOL controlHotCorners;
@property (nonatomic) BOOL controlScrolling;
@property (nonatomic) BOOL controlNotifications;
@property (nonatomic) BOOL openAtLogin;
@property (nonatomic) BOOL activateOnOpen;

@property (nonatomic) NSArray *controlledActions;
@property (nonatomic) PBLHotCornersAction *hotCornersAction;
@property (nonatomic) PBLScrollingAction *scrollingAction;
@property (nonatomic) PBLNotificationsAction *notificationsAction;

@end

@implementation PBLAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	PFMoveToApplicationsFolderIfNecessary();
	
	self.enabled = NO;
	
	NSStatusItem *statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:22.0];
	[statusItem setEnabled:YES];
	self.statusItem = statusItem;
	PBLStatusItemView *statusItemView = [[PBLStatusItemView alloc] initWithStatusItem:self.statusItem];
	statusItemView.highlighted = NO;
	statusItemView.delegate = self;
	self.statusItem.view = statusItemView;
	self.statusItemView = statusItemView;
	self.statusItemView.toolTip = NSLocalizedString(@"Click to turn Passable on and off. Right-click or Control + click for more options.", @"tooltip for menu bar icon");
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSDictionary *defaultPreferenceValues = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:kDefaultPreferencesFileName ofType:@"plist"]];
	[defaults registerDefaults:defaultPreferenceValues];
	
	self.controlHotCorners = [defaults boolForKey:kControlHotCornersPrefKey];
	self.hotCornersMenuItem.state = self.controlHotCorners ? NSOnState : NSOffState;
	self.controlScrolling = [defaults boolForKey:kControlScrollingPrefKey];
	self.scrollingMenuItem.state = self.controlScrolling ? NSOnState : NSOffState;
	self.controlNotifications = [defaults boolForKey:kControlNotificationsPrefKey];
	self.notificationCenterMenuItem.state = self.controlNotifications ? NSOnState : NSOffState;
	self.openAtLogin = [defaults boolForKey:kOpenAtLoginPrefsKey];
	self.openAtLoginMenu.state = self.openAtLogin ? NSOnState : NSOffState;
	self.activateOnOpen = [defaults boolForKey:kActivateOnOpenPrefsKey];
	self.activateWhenOpenedMenu.state = self.activateOnOpen ? NSOnState : NSOffState;
	
	self.hotCornersAction = [[PBLHotCornersAction alloc] init];
	self.hotCornersAction.delegate = self;
	self.scrollingAction = [[PBLScrollingAction alloc] init];
	self.scrollingAction.delegate = self;
	self.notificationsAction = [[PBLNotificationsAction alloc] init];
	self.notificationsAction.delegate = self;
	
	if (![defaults boolForKey:kDoNotShowIntroWindowPrefKey]) {
		NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Welcome to Passable!", nil) defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Click the Passable icon in the menu bar to turn it on and off. Control + click it or right-click it for more options.", nil)];
		[alert runModal];
		[defaults setBool:YES forKey:kDoNotShowIntroWindowPrefKey];
		[defaults synchronize];
	}
	
	// Crash reporting.
	[[BWQuincyManager sharedQuincyManager] setSubmissionURL:@"http://www.ngreenstein.com/quincy/crash_v200.php"];
	[[BWQuincyManager sharedQuincyManager] setCompanyName:NSLocalizedString(@"the Passable developers", nil)];
	[[BWQuincyManager sharedQuincyManager] setDelegate:self];
//	BWQuincyUI *quincyWindow = [[BWQuincyUI alloc] initWithManager:[BWQuincyManager sharedQuincyManager] crashFile:nil companyName:[[BWQuincyManager sharedQuincyManager] companyName] applicationName:@"Passable"];
//	[quincyWindow askCrashReportDetails];
	
	if (self.activateOnOpen) {
		self.enabled = YES;
	}
	
}

- (void) showMainApplicationWindow {
	// Required by Quincy. We don't do anything here.
}

// Don't let the app quit if there are async actions going on; otherwise some temporary settings could be left un-reverted.
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	NSApplicationTerminateReply __block reply = NSTerminateNow;
	[self.controlledActions enumerateObjectsUsingBlock:^(PBLAction *action, NSUInteger index, BOOL *stop) {
		if (action.isBusy) {
			reply = NSTerminateCancel;
			*stop = YES;
		}
	}];
	return reply;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	[self setEnabled:NO asynchronously:NO];
}

#pragma mark - MBAStatusItemViewDelegate Methods

- (void)clicked:(id)sender {
	self.enabled = !self.enabled;
}

- (void)rightClicked:(id)sender {
//	kill( getpid(), SIGABRT );
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

- (IBAction)openAtLoginClicked:(NSMenuItem *)sender {
	self.openAtLogin = (sender.state != NSOnState);
}
- (IBAction)activateWhenOpenedClicked:(NSMenuItem *)sender {
	self.activateOnOpen = (sender.state != NSOnState);
}

- (IBAction)aboutClicked:(id)sender {
	[NSApp orderFrontStandardAboutPanel:self];
}
- (IBAction)helpClicked:(NSMenuItem *)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://passableapp.com"]];
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

- (void)setOpenAtLogin:(BOOL)openAtLogin {
	if (_openAtLogin != openAtLogin) {
		_openAtLogin = openAtLogin;
		self.openAtLoginMenu.state = openAtLogin ? NSOnState : NSOffState;
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		if ([defaults boolForKey:kOpenAtLoginPrefsKey] != openAtLogin) {
			[defaults setBool:openAtLogin forKey:kOpenAtLoginPrefsKey];
			[defaults synchronize];
		}
	}
	[self registerToOpenAtLogin:openAtLogin];
}

- (void)setActivateOnOpen:(BOOL)activateOnOpen {
	if (_activateOnOpen != activateOnOpen) {
		_activateOnOpen = activateOnOpen;
		self.activateWhenOpenedMenu.state = activateOnOpen ? NSOnState : NSOffState;
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		if ([defaults boolForKey:kActivateOnOpenPrefsKey] != activateOnOpen) {
			[defaults setBool:activateOnOpen forKey:kActivateOnOpenPrefsKey];
			[defaults synchronize];
		}
	}
}

- (void)registerToOpenAtLogin:(BOOL)openAtLogin {

	LSSharedFileListRef listRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	if (openAtLogin) {
		
		LSSharedFileListInsertItemURL(listRef, kLSSharedFileListItemLast, NULL, NULL, (__bridge  CFURLRef)[[NSBundle mainBundle] bundleURL], NULL, NULL);
		
	} else {
		
		UInt32 seedValue;
		NSArray *currentLoginItems = (__bridge NSArray *)LSSharedFileListCopySnapshot(listRef, &seedValue);
		CFURLRef myUrl = (__bridge CFURLRef)([[NSBundle mainBundle] bundleURL]);

		[currentLoginItems enumerateObjectsUsingBlock:^(id thisObject, NSUInteger idx, BOOL *stop) {
			LSSharedFileListItemRef thisItem = (__bridge LSSharedFileListItemRef)thisObject;
			CFURLRef thisUrl;
			LSSharedFileListItemResolve(thisItem, 0, &thisUrl, NULL);
			if (CFEqual(myUrl, thisUrl)) {
				LSSharedFileListItemRemove(listRef, thisItem);
				*stop = YES;
			}
			CFRelease(thisItem);
			CFRelease(thisUrl);
		}];
		CFRelease(myUrl);
	}
	
	CFRelease(listRef);
}

#pragma mark - Turning On and Off

- (void)setEnabled:(BOOL)enabled asynchronously:(BOOL)async {
	if (_enabled != enabled) {
		_enabled = enabled;
		
		[self.controlledActions enumerateObjectsUsingBlock:^(PBLAction *action, NSUInteger index, BOOL *stop) {
			if (async) {
				[action enable:!enabled];
			} else {
				[action enableNow:!enabled];
			}
		}];
		
		self.statusItemView.active = enabled;
	}
}

- (void)setEnabled:(BOOL)enabled {
	[self setEnabled:enabled asynchronously:YES];
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

- (void)action:(PBLAction *)action didEnable:(BOOL)enabled withError:(NSError *)error {
	if (error) {
		NSLog(@"Error %li occured when %@ the action '%@'.", (long)error.code, enabled ? @"enabling" : @"disabling", action.description);
	}
}

@end
