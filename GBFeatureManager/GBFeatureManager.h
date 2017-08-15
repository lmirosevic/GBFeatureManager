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

#pragma mark - Handlers

/**
 The block that is called when a feature state changes.
 */
typedef void(^GBFeatureManagerFeatureStateChangedUpdateHandler)(NSString * _Nonnull featureId, BOOL isUnlocked);

/**
 A generic handelr block that takes no params.
 */
typedef void(^GBFeatureManagerGenericHandler)(void);

#pragma mark - Notifications

/**
 Fired when a feature is unlocked
 */
FOUNDATION_EXTERN NSString * _Nonnull const kGBFeatureManagerFeatureUnlockedNotification;

/**
 Fired when a feature is locked.
 */
FOUNDATION_EXTERN NSString * _Nonnull const kGBFeatureManagerFeatureLockedNotification;

/**
 Fired both in case of a feature lock and and unlock
 */
FOUNDATION_EXTERN NSString * _Nonnull const kGBFeatureManagerFeatureLockStateChangedNotification;

/**
 Get the value for this key in the userInfo dict to find out which feature was locked/unlocked
 */
FOUNDATION_EXTERN NSString * _Nonnull const kGBFeatureManagerFeatureIdentifierKey;

/**
 Get the value for this key in the userInfo dict to find out what the feature's new lock state is
 */
FOUNDATION_EXTERN NSString * _Nonnull const kGBFeatureManagerFeatureLockStateKey;

/**
 Fired when the wildcard feature override has been enabled.
 */
FOUNDATION_EXTERN NSString * _Nonnull const kGBFeatureManagerWildcardFeatureOverrideEnabledNotification;

/**
 Fired when the wildcard feature override has been disabled.
 */
FOUNDATION_EXTERN NSString * _Nonnull const kGBFeatureManagerWildcardFeatureOverrideDisabledNotification;

@interface GBFeatureManager : NSObject

// Simple feature unlocking
+ (void)unlockFeature:(nonnull NSString *)featureId;
+ (void)lockFeature:(nonnull NSString *)featureId;

// Wildcard feature override... to unlock all possible features
+ (void)enableWildcardFeatureOverride;
+ (void)disableWildcardFeatureOverride;

// Checking whether a feature is unlocked
+ (BOOL)isFeatureUnlocked:(nonnull NSString *)featureId;
+ (BOOL)areFeaturesAllUnlocked:(nonnull NSArray *)featureIds;
+ (BOOL)areFeaturesAnyUnlocked:(nonnull NSArray *)featureIds;

// Registering handlers for when features get locked/unlocked, etc.
+ (void)addHandlerForDidUnlockFeature:(nonnull GBFeatureManagerFeatureStateChangedUpdateHandler)handler;
+ (void)addHandlerForDidLockFeature:(nonnull GBFeatureManagerFeatureStateChangedUpdateHandler)handler;
+ (void)addHandlerForDidChangeFeatureLockState:(nonnull GBFeatureManagerFeatureStateChangedUpdateHandler)handler;
+ (void)addHandlerForDidEnableWildcardFeatureOverride:(nonnull GBFeatureManagerGenericHandler)handler;
+ (void)addHandlerForDidDisableWildcardFeatureOverride:(nonnull GBFeatureManagerGenericHandler)handler;

@end
