//
//  MBAHotCornersAction.m
//  Menu Bar App
//
//  Created by Nathan Greenstein on 12/23/13.
//  Copyright (c) 2013 Nathan Greenstein. All rights reserved.
//

#import "MBAHotCornersAction.h"

#include "MBAConstants.h"

// When "disabling" hot corners, this goes through the user's hot corners and, for any that don't already have modifier keys required, requires the command key.
// Then, when "enabling" them again, it goes through and turns off any required modifiers that it added.

// There is a priate API that lets us change Dock settings without requiring a restart of Dock.app.
//		action = index of the action performed (e.g. 1 is nothing, 4 is show desktop)
//		corner = the index of the corner (0 = tl, 1 = tr, 2 = bl, 3 = br)
//		modifierKeysMask = the mask of modifier keys required (e.g. command = kDockCommandKeyIdentifier = 1048576; none = kDockNoModifierKeyIdnetifier = 0)
// See the wrapper method -setHotCorner:toAction:withModifierMask:
extern void CoreDockSetExposeCornerActionWithModifier(int action, int corner, int modifierKeysMask);

@implementation MBAHotCornersAction

- (void)enable:(BOOL)enable {
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *currentPrefs = [defaults persistentDomainForName:kDockPrefsDomain];
	
	NSNumber *noActionId = [NSNumber numberWithUnsignedInteger:kDockNoActionIdentifier];
	NSNumber *commandKeyId = [NSNumber numberWithUnsignedInteger:kDockCommandKeyIdentifier];
	NSNumber *noKeyId = [NSNumber numberWithUnsignedInteger:kDockNoModifierKeyIdnetifier];
	
	if (enable) {
		
		NSArray *storedActions = [defaults arrayForKey:kStoredHotCornerActionsPrefKey];
		NSArray *storedModifiers = [defaults arrayForKey:kStoredHotCornerModifiersPrefKey];
		
		if (!storedActions) {
			// [TODO ngreenstein] Update all these error conditions to use NSError and report them to the delegate.
			NSLog(@"!!! ERROR: Cannot find saved modifiers (defaults key \"%@\").", kStoredHotCornerActionsPrefKey);
		}
		if (!storedModifiers) {
			NSLog(@"!!! ERROR: Cannot find saved modifiers (defaults key \"%@\").", kStoredHotCornerModifiersPrefKey);
		}
		
		[defaults removeObjectForKey:kStoredHotCornerActionsPrefKey];
		[defaults removeObjectForKey:kStoredHotCornerModifiersPrefKey];
		
		NSArray *orderedActionPrefsKeys = @[kDockTopLeftActionPrefKey, kDockTopRightActionPrefKey, kDockBottomLeftActionPrefKey, kDockBottomRightActionPrefKey];
		NSArray *orderedModifierPrefsKeys = @[kDockTopLeftModifierPrefKey, kDockTopRightModifierPrefKey, kDockBottomLeftModifierPrefKey, kDockBottomRightModifierPrefKey];
		
		for (MBAScreenCorner screenCorner = kTopLeftScreenCorner; screenCorner < kBottomRightScreenCorner; screenCorner ++) {
			
//			id storedActionValue = storedActions[screenCorner];
			id storedModifierValue = storedModifiers[screenCorner];
			
			NSString *actionPrefsKey = orderedActionPrefsKeys[screenCorner];
			NSString *modifierPrefsKey = orderedModifierPrefsKeys[screenCorner];
			
			id currentActionValue = currentPrefs[actionPrefsKey];
			id currentModifierValue = currentPrefs[modifierPrefsKey];
			
			if ([currentModifierValue isNotEqualTo:storedModifierValue] && [currentModifierValue isEqual:commandKeyId]) { // Check whether this is a value that the app changed when disabling hot corners.
				[self setHotCorner:screenCorner toAction:currentActionValue withModifierMask:storedModifierValue];
			}
			
		}
		
	} else { // Disable
		
		NSArray *oldActions = @[currentPrefs[kDockTopLeftActionPrefKey],
								currentPrefs[kDockTopRightActionPrefKey],
								currentPrefs[kDockBottomLeftActionPrefKey],
								currentPrefs[kDockBottomRightActionPrefKey]];
		
		NSArray *oldModifiers = @[currentPrefs[kDockTopLeftModifierPrefKey],
								  currentPrefs[kDockTopRightModifierPrefKey],
								  currentPrefs[kDockBottomLeftModifierPrefKey],
								  currentPrefs[kDockBottomRightModifierPrefKey]];
		
		[defaults setObject:oldActions forKey:kStoredHotCornerActionsPrefKey];
		[defaults setObject:oldModifiers forKey:kStoredHotCornerModifiersPrefKey];
		
		for (MBAScreenCorner screenCorner = kTopLeftScreenCorner; screenCorner < kBottomRightScreenCorner; screenCorner ++) {
			// Only add the command key modifier if the corner has some action assigned to it and doesn't already have a modifier key.
			if (![oldActions[screenCorner] isEqualToNumber:noActionId] && [oldModifiers[screenCorner] isEqualToNumber:noKeyId]) {
				[self setHotCorner:screenCorner toAction:oldActions[screenCorner] withModifierMask:commandKeyId];
			}
		}
	}
	
	[defaults synchronize];
	
	[self.delegate action:self didEnable:enable withError:nil];
	
}

- (void)setHotCorner:(MBAScreenCorner)screenCorner toAction:(NSNumber *)action withModifierMask:(NSNumber *)modifierMask {
	CoreDockSetExposeCornerActionWithModifier([action intValue], screenCorner, [modifierMask intValue]);
}

@end
