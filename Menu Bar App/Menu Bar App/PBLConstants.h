//
//  PBLConstants.h
// Passable
//
//  Created by Nathan Greenstein on 12/1/13.
//  Copyright (c) 2013 Nathan Greenstein. All rights reserved.
//

#ifndef PBLConstants_h
#define PBLConstants_h

#pragma mark - General
static NSString *const kMenuItemIconBaseName = @"TempIcon";

#pragma mark - MBA Preferences
static NSString *const kDefaultPreferencesFileName = @"DefaultPreferenceValues";

static NSString *const kControlHotCornersPrefKey = @"controlHotCornersEnabled";
static NSString *const kControlScrollingPrefKey = @"controlScrollingEnabled";
static NSString *const kControlNotificationsPrefKey = @"controlNotificationsEnabled";

static NSString *const kShowIntroWindowPrefKey = @"showIntroWindow";

static NSString *const kStoredHotCornerModifiersPrefKey = @"oldHotCornerModifiers";
static NSString *const kStoredDNDStartPrefKey = @"oldDndStart";
static NSString *const kStoredDNDEndPrefKey = @"oldDndEnd";

#pragma mark - Dock Stuff
typedef NS_ENUM(NSUInteger, MBAScreenCorner) {
	kTopLeftScreenCorner,
	kTopRightScrenCorner,
	kBottomLeftScreenCorner,
	kBottomRightScreenCorner,
};

static NSString *const kDockPrefsDomain = @"com.apple.dock";

static NSString *const kDockTopLeftActionPrefKey = @"wvous-tl-corner";
static NSString *const kDockTopRightActionPrefKey = @"wvous-tr-corner";
static NSString *const kDockBottomLeftActionPrefKey = @"wvous-bl-corner";
static NSString *const kDockBottomRightActionPrefKey = @"wvous-br-corner";

static NSString *const kDockTopLeftModifierPrefKey = @"wvous-tl-modifier";
static NSString *const kDockTopRightModifierPrefKey = @"wvous-tr-modifier";
static NSString *const kDockBottomLeftModifierPrefKey = @"wvous-bl-modifier";
static NSString *const kDockBottomRightModifierPrefKey = @"wvous-br-modifier";

static NSUInteger const kDockNoActionIdentifier = 1;

static NSUInteger const kDockCommandKeyIdentifier = NSCommandKeyMask;
static NSUInteger const kDockNoModifierKeyIdnetifier = 0;

#pragma mark - Notification Center Stuff
static CFStringRef const kNotificationCenterPrefsDomain = (__bridge  CFStringRef)@"com.apple.notificationcenterui";

static CFStringRef const kNotificationCenterDNDStartPrefKey = (__bridge  CFStringRef)@"dndStart";
static CFStringRef const kNotificationCenterDNDEndPrefKey = (__bridge  CFStringRef)@"dndEnd";
static NSUInteger const kNotificationCenterDNDStartTime = 181; // Minutes since midnight, = 3:01 AM.
static NSUInteger const kNotificationCenterDNDEndTime = 180;

#pragma mark - Errors
static NSString *const kErrorDomain = @"MBAErrorDomain";
static NSString *const kErrorOldErrorKey = @"oldErrorObject";
typedef NS_ENUM(NSInteger, MBAErrorCode) {
	kErrorUnableToSynchronizePrefs,
	kErrorStoredValueNotFound,
};

#endif
