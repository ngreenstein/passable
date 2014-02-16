//
//  PBLHotCornersAction.m
//  Passable
//
//  Created by Nathan Greenstein on 12/23/13.
//  Copyright (c) 2013 Nathan Greenstein. All rights reserved.
//

#import "PBLHotCornersAction.h"

#include "PBLConstants.h"

// When "disabling" hot corners, this goes through the user's hot corners and, for any that don't already have modifier keys required, requires the command key.
// Then, when "enabling" them again, it goes through and turns off any required modifiers that it added.

// There is a priate API that lets us change Dock settings without requiring a restart of Dock.app.
//		action = index of the action performed (e.g. 1 is nothing, 4 is show desktop)
//		corner = the index of the corner (0 = tl, 1 = tr, 2 = bl, 3 = br)
//		modifierKeysMask = the mask of modifier keys required (e.g. command = kDockCommandKeyIdentifier = 1048576; none = kDockNoModifierKeyIdnetifier = 0)
// See the wrapper method -setHotCorner:toAction:withModifierMask:
extern void CoreDockSetExposeCornerActionWithModifier(int action, int corner, int modifierKeysMask);

@implementation PBLHotCornersAction

- (void)enableNow:(BOOL)enable {
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *currentPrefs = [defaults persistentDomainForName:kDockPrefsDomain];
	
	NSNumber *noActionId = [NSNumber numberWithUnsignedInteger:kDockNoActionIdentifier];
	NSNumber *commandKeyId = [NSNumber numberWithUnsignedInteger:kDockCommandKeyIdentifier];
	NSNumber *noModifierId = [NSNumber numberWithUnsignedInteger:kDockNoModifierKeyIdnetifier];
	
	NSError *error;
	
	if (enable) {
		
		NSArray *storedModifiers = [defaults arrayForKey:kStoredHotCornerModifiersPrefKey];
		
		if (!storedModifiers) {
			
			NSDictionary *errorInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to restore user's previous hot corner modifier keys.", nil),
										NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Unable to find stored modifiers at defaults key '%@'.", nil), kStoredHotCornerModifiersPrefKey]};
			error = [NSError errorWithDomain:kErrorDomain code:kErrorStoredValueNotFound userInfo:errorInfo];
			
			// If we somehow lose the stored modifiers, make the assumption that the user didn't have any modifiers setup before and remove any command-key modifiers. Note that any modifiers other than command-key ones will, as normal, not be removed.
			storedModifiers = @[noModifierId, noModifierId, noModifierId, noModifierId];
		}
		
		[defaults removeObjectForKey:kStoredHotCornerModifiersPrefKey];
		
		NSArray *orderedActionPrefsKeys = @[kDockTopLeftActionPrefKey, kDockTopRightActionPrefKey, kDockBottomLeftActionPrefKey, kDockBottomRightActionPrefKey];
		NSArray *orderedModifierPrefsKeys = @[kDockTopLeftModifierPrefKey, kDockTopRightModifierPrefKey, kDockBottomLeftModifierPrefKey, kDockBottomRightModifierPrefKey];
		
		for (MBAScreenCorner screenCorner = kTopLeftScreenCorner; screenCorner <= kBottomRightScreenCorner; screenCorner ++) {

			id storedModifierValue = storedModifiers[screenCorner];
			
			NSString *actionPrefsKey = orderedActionPrefsKeys[screenCorner];
			NSString *modifierPrefsKey = orderedModifierPrefsKeys[screenCorner];
			
			id currentActionValue = currentPrefs[actionPrefsKey];
			id currentModifierValue = currentPrefs[modifierPrefsKey];
			
			// Check whether this is a value that the app changed when disabling hot corners.
			if ([currentModifierValue isNotEqualTo:storedModifierValue] && [currentModifierValue isEqual:commandKeyId]) {
				[self setHotCorner:screenCorner toAction:currentActionValue withModifierMask:storedModifierValue];
			}
			
		}
		
		if (![defaults synchronize]) {
			NSMutableDictionary *errorInfo = [@{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to clean up after re-enabling hot corners.", nil),
												NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"Unable to sync NSUserDefaults to delete old modifiers.", nil)} mutableCopy];
			if (error) {
				NSLog(@"Uh oh. Multiple errors encountered when re-enabling hot corners. Old error saved in new error's userInfo dict.");
				[errorInfo setObject:[error copy] forKey:kErrorOldErrorKey];
			}
			error = [NSError errorWithDomain:kErrorDomain code:kErrorUnableToSynchronizePrefs userInfo:errorInfo];
		}
		
	} else { // Disable
		
		// If there are some corners where the user has never enabled hot corners, the pref keys for those corners may not exist.
		id topLeftAction = currentPrefs[kDockTopLeftActionPrefKey] ? currentPrefs[kDockTopLeftActionPrefKey] : noActionId;
		id topRightAction = currentPrefs[kDockTopRightActionPrefKey] ? currentPrefs[kDockTopRightActionPrefKey] : noActionId;
		id bottomLeftAction = currentPrefs[kDockBottomLeftActionPrefKey] ? currentPrefs[kDockBottomLeftActionPrefKey] : noActionId;
		id bottomRightAction = currentPrefs[kDockBottomRightActionPrefKey] ? currentPrefs[kDockBottomRightActionPrefKey] : noActionId;
		
		id topLeftModifier = currentPrefs[kDockTopLeftModifierPrefKey] ? currentPrefs[kDockTopLeftModifierPrefKey] : noModifierId;
		id topRightModifier = currentPrefs[kDockTopRightModifierPrefKey] ? currentPrefs[kDockTopRightModifierPrefKey] : noModifierId;
		id bottomLeftModifier = currentPrefs[kDockBottomLeftModifierPrefKey] ? currentPrefs[kDockBottomLeftModifierPrefKey] : noModifierId;
		id bottomRightModifier = currentPrefs[kDockBottomRightModifierPrefKey] ? currentPrefs[kDockBottomRightModifierPrefKey] : noModifierId;
		
		NSArray *currentActions = @[topLeftAction, topRightAction, bottomLeftAction, bottomRightAction];
		
		NSArray *currentModifiers = @[topLeftModifier, topRightModifier, bottomLeftModifier, bottomRightModifier];
		
		[defaults setObject:currentModifiers forKey:kStoredHotCornerModifiersPrefKey];
		
		if ([defaults synchronize]) { // Only change the modfiers if we can save the old ones successfully.
			for (MBAScreenCorner screenCorner = kTopLeftScreenCorner; screenCorner <= kBottomRightScreenCorner; screenCorner ++) {
				// Only add the command key modifier if the corner has some action assigned to it and doesn't already have a modifier key.
				if (![currentActions[screenCorner] isEqualToNumber:noActionId] && [currentModifiers[screenCorner] isEqualToNumber:noModifierId]) {
					[self setHotCorner:screenCorner toAction:currentActions[screenCorner] withModifierMask:commandKeyId];
				}
			}
		} else {
			NSDictionary *errorInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to disable hot corners.", nil),
												NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"Unable to sync NSUserDefaults to save old modifiers.", nil)};
			error = [NSError errorWithDomain:kErrorDomain code:kErrorUnableToSynchronizePrefs userInfo:errorInfo];
		}
	}
	
	[self.delegate action:self didEnable:enable withError:error];
	
}

- (void)setHotCorner:(MBAScreenCorner)screenCorner toAction:(NSNumber *)action withModifierMask:(NSNumber *)modifierMask {
	CoreDockSetExposeCornerActionWithModifier([action intValue], screenCorner, [modifierMask intValue]);
}

- (NSString *)description {
	return NSLocalizedString(@"hot corners", @"action description");
}

@end
