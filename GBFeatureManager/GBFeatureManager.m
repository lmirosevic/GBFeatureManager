//
//  GBFeatureManager.m
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

#import "GBFeatureManager.h"

#import <GBStorage/GBStorage.h>
#import <GBToolbox/GBToolbox.h>

#pragma mark - Notifications

NSString * const kGBFeatureManagerFeatureIdentifierKey =                            @"kGBFeatureManagerFeatureIdentifierKey";
NSString * const kGBFeatureManagerFeatureLockStateKey =                             @"kGBFeatureManagerFeatureLockStateKey";
NSString * const kGBFeatureManagerFeatureUnlockedNotification =                     @"kGBFeatureManagerFeatureUnlockedNotification";
NSString * const kGBFeatureManagerFeatureLockedNotification =                       @"kGBFeatureManagerFeatureLockedNotification";
NSString * const kGBFeatureManagerFeatureLockStateChangedNotification =             @"kGBFeatureManagerFeatureLockStateChangedNotification";
NSString * const kGBFeatureManagerWildcardFeatureOverrideEnabledNotification =      @"kGBFeatureManagerWildcardFeatureOverrideEnabledNotification";
NSString * const kGBFeatureManagerWildcardFeatureOverrideDisabledNotification =     @"kGBFeatureManagerWildcardFeatureOverrideDisabledNotification";

#pragma mark - Local consts

static NSString * const kStorageNamespace =                                         @"GBFeatureManager";
static NSString * const kStorageKeyDiskPrefix =                                     @"FeatureID";
static NSString * const kWildcardFeatureKey =                                       @"WildcardFeatureID";

@interface GBFeatureManager ()

@property (strong, nonatomic) NSMutableDictionary   *cache;

#pragma mark - Handlers

@property (strong, nonatomic) NSMutableArray *didUnlockFeatureHandlers;
@property (strong, nonatomic) NSMutableArray *didLockFeatureHandlers;
@property (strong, nonatomic) NSMutableArray *didChangeFeatureLockStateHandlers;
@property (strong, nonatomic) NSMutableArray *didEnableWildcardOverrideHandlers;
@property (strong, nonatomic) NSMutableArray *didDisableWildcardOverrideHandlers;

@end

@implementation GBFeatureManager

#pragma mark - Life

_singleton(sharedFeatureManager)

_lazy(NSMutableArray, didUnlockFeatureHandlers, _didUnlockFeatureHandlers)
_lazy(NSMutableArray, didLockFeatureHandlers, _didLockFeatureHandlers)
_lazy(NSMutableArray, didChangeFeatureLockStateHandlers, _didChangeFeatureLockStateHandlers)
_lazy(NSMutableArray, didEnableWildcardOverrideHandlers, _didEnableWildcardOverrideHandlers)
_lazy(NSMutableArray, didDisableWildcardOverrideHandlers, _didDisableWildcardOverrideHandlers)

- (id)init {
    if (self = [super init]) {
        self.cache = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc {
    self.cache = nil;
    
    self.didUnlockFeatureHandlers = nil;
    self.didLockFeatureHandlers = nil;
    self.didChangeFeatureLockStateHandlers = nil;
    self.didEnableWildcardOverrideHandlers = nil;
    self.didDisableWildcardOverrideHandlers = nil;
}

#pragma mark - Public

+ (void)unlockFeature:(NSString *)featureId {
    AssertParameterNotNil(featureId);
    
    [self _setFeature:featureId unlockedState:YES];
}

+ (void)lockFeature:(NSString *)featureId {
    AssertParameterNotNil(featureId);
    
    [self _setFeature:featureId unlockedState:NO];
}

+ (void)enableWildcardFeatureOverride {
    [self _storeBoolean:YES forKey:kWildcardFeatureKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:kGBFeatureManagerWildcardFeatureOverrideEnabledNotification object:self];
    
    for (GBFeatureManagerGenericHandler handler in [GBFeatureManager sharedFeatureManager].didEnableWildcardOverrideHandlers) {
        handler();
    }
}

+ (void)disableWildcardFeatureOverride {
    [self _storeBoolean:NO forKey:kWildcardFeatureKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:kGBFeatureManagerWildcardFeatureOverrideDisabledNotification object:self];
    
    for (GBFeatureManagerGenericHandler handler in [GBFeatureManager sharedFeatureManager].didDisableWildcardOverrideHandlers) {
        handler();
    }
}

+ (BOOL)isFeatureUnlocked:(NSString *)featureId {
    AssertParameterNotNil(featureId);
    
    return [self _readBooleanForKey:kWildcardFeatureKey] || [self _readBooleanForKey:featureId];
}

+ (BOOL)areFeaturesAllUnlocked:(NSArray *)featureIds {
    AssertParameterNotNil(featureIds);
    
    return [[[featureIds map:^id(id object) {
        return @([self isFeatureUnlocked:object]);
    }] reduce:^id(id objectA, id objectB) {
        return @([objectA boolValue] && [objectB boolValue]);
    } lastObject:@(YES)] boolValue];
}

+ (BOOL)areFeaturesAnyUnlocked:(NSArray *)featureIds {
    AssertParameterNotNil(featureIds);
    
    return [[[featureIds map:^id(id object) {
        return @([self isFeatureUnlocked:object]);
    }] reduce:^id(id objectA, id objectB) {
        return @([objectA boolValue] || [objectB boolValue]);
    } lastObject:@(NO)] boolValue];
}

+ (void)addHandlerForDidUnlockFeature:(GBFeatureManagerFeatureStateChangedUpdateHandler)handler {
    AssertParameterNotNil(handler);
    
    if (handler) [[GBFeatureManager sharedFeatureManager].didUnlockFeatureHandlers addObject:[handler copy]];
}

+ (void)addHandlerForDidLockFeature:(GBFeatureManagerFeatureStateChangedUpdateHandler)handler {
    AssertParameterNotNil(handler);
    
    if (handler) [[GBFeatureManager sharedFeatureManager].didLockFeatureHandlers addObject:[handler copy]];
}

+ (void)addHandlerForDidChangeFeatureLockState:(GBFeatureManagerFeatureStateChangedUpdateHandler)handler {
    AssertParameterNotNil(handler);
    
    if (handler) [[GBFeatureManager sharedFeatureManager].didChangeFeatureLockStateHandlers addObject:[handler copy]];
}

+ (void)addHandlerForDidEnableWildcardFeatureOverride:(GBFeatureManagerGenericHandler)handler {
    AssertParameterNotNil(handler);
    
    if (handler) [[GBFeatureManager sharedFeatureManager].didEnableWildcardOverrideHandlers addObject:[handler copy]];
}

+ (void)addHandlerForDidDisableWildcardFeatureOverride:(GBFeatureManagerGenericHandler)handler {
    AssertParameterNotNil(handler);
    
    if (handler) [[GBFeatureManager sharedFeatureManager].didDisableWildcardOverrideHandlers addObject:[handler copy]];
}

#pragma mark - Private

+ (NSString *)_storageKeyForFeatureId:(NSString *)featureId {
    return _f(@"%@.%@", kStorageKeyDiskPrefix, featureId);
}

+ (void)_storeBoolean:(BOOL)boolean forKey:(NSString *)featureId {
    if (IsValidString(featureId)) {
        GBStorage(kStorageNamespace)[[self _storageKeyForFeatureId:featureId]] = @(boolean);
        [GBStorage(kStorageNamespace) save:[self _storageKeyForFeatureId:featureId]];
    }
    else {
        @throw [NSException exceptionWithName:@"GBFeatureManager error" reason:@"key must be non-empty NSString" userInfo:nil];
    }
}

+ (BOOL)_readBooleanForKey:(NSString *)featureId {
    if (IsValidString(featureId)) {
        id result = GBStorage(kStorageNamespace)[[self _storageKeyForFeatureId:featureId]];
        
        //booleanize result
        if ([result isKindOfClass:[NSNumber class]] && [result boolValue]) {
            return YES;
        }
        else {
            return NO;
        }
    }
    else {
        @throw [NSException exceptionWithName:@"GBFeatureManager error" reason:@"key must be non-empty NSString" userInfo:nil];
    }
}

+ (void)_setFeature:(NSString *)featureId unlockedState:(BOOL)isUnlocked {
    [self _storeBoolean:isUnlocked forKey:featureId];
    
    for (NSString *notificationName in @[
        (isUnlocked ? kGBFeatureManagerFeatureUnlockedNotification : kGBFeatureManagerFeatureLockedNotification),
        kGBFeatureManagerFeatureLockStateChangedNotification
    ]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:@{
            kGBFeatureManagerFeatureIdentifierKey: featureId,
            kGBFeatureManagerFeatureLockStateKey: @(isUnlocked)
        }];
    }
    
    for (GBFeatureManagerFeatureStateChangedUpdateHandler handler in (isUnlocked ? [GBFeatureManager sharedFeatureManager].didUnlockFeatureHandlers : [GBFeatureManager sharedFeatureManager].didLockFeatureHandlers)) {
        handler(featureId, isUnlocked);
    }
    
    for (GBFeatureManagerFeatureStateChangedUpdateHandler handler in [GBFeatureManager sharedFeatureManager].didChangeFeatureLockStateHandlers) {
        handler(featureId, isUnlocked);
    }
}

@end
