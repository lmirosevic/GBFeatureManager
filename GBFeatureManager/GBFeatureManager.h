//
//  GBFeatureManager.h
//  GBFeatureManager
//
//  Created by Luka Mirosevic on 15/03/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

// Handlers
typedef void(^GBFeatureManagerFeatureStateChangedUpdateHandler)(NSString *featureIdentifier);
typedef void(^GBFeatureManagerGenericHandler)(void);

// Notifications
extern NSString * const kGBFeatureManagerFeatureUnlockedNotification;
extern NSString * const kGBFeatureManagerFeatureLockedNotification;
extern NSString * const kGBFeatureManagerFeatureIdentifierKey;//get the value for this key in the userInfo dict to find out which feature was unlocked

extern NSString * const kGBFeatureManagerWildcardFeatureOverrideEnabledNotification;
extern NSString * const kGBFeatureManagerWildcardFeatureOverrideDisabledNotification;

@interface GBFeatureManager : NSObject

// Simple feature unlocking
+ (void)unlockFeature:(NSString *)featureID;
+ (void)lockFeature:(NSString *)featureID;

// Wildcard feature override... to unlock all possible features
+ (void)enableWildcardFeatureOverride;
+ (void)disableWildcardFeatureOverride;

// Checking whether a feature is unlocked
+ (BOOL)isFeatureUnlocked:(NSString *)featureID;
+ (BOOL)areFeaturesAllUnlocked:(NSArray *)featureIDs;
+ (BOOL)areFeaturesAnyUnlocked:(NSArray *)featureIDs;

// Registering handlers for when features get locked/unlocked, etc.
+ (void)addHandlerForDidUnlockFeature:(GBFeatureManagerFeatureStateChangedUpdateHandler)handler;
+ (void)addHandlerForDidLockFeature:(GBFeatureManagerFeatureStateChangedUpdateHandler)handler;
+ (void)addHandlerForDidEnableWildcardFeatureOverride:(GBFeatureManagerGenericHandler)handler;
+ (void)addHandlerForDidDisableWildcardFeatureOverride:(GBFeatureManagerGenericHandler)handler;

@end
