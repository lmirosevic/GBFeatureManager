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

//Notifications
NSString * const kGBFeatureManagerFeatureIdentifierKey =                            @"kGBFeatureManagerFeatureIdentifierKey";
NSString * const kGBFeatureManagerFeatureUnlockedNotification =                     @"kGBFeatureManagerFeatureUnlockedNotification";
NSString * const kGBFeatureManagerFeatureLockedNotification =                       @"kGBFeatureManagerFeatureLockedNotification";
NSString * const kGBFeatureManagerWildcardFeatureOverrideEnabledNotification =      @"kGBFeatureManagerWildcardFeatureOverrideEnabledNotification";
NSString * const kGBFeatureManagerWildcardFeatureOverrideDisabledNotification =     @"kGBFeatureManagerWildcardFeatureOverrideDisabledNotification";

static NSString * const kStorageNamespace =                                         @"GBFeatureManager";
static NSString * const kStorageKeyDiskPrefix =                                     @"FeatureID";
static NSString * const kWildcardFeatureKey =                                       @"WildcardFeatureID";

@interface GBFeatureManager ()

@property (strong, nonatomic) NSMutableDictionary   *cache;

//handlers
@property (strong, nonatomic) NSMutableArray *didUnlockFeatureHandlers;
@property (strong, nonatomic) NSMutableArray *didLockFeatureHandlers;
@property (strong, nonatomic) NSMutableArray *didEnableWildcardOverrideHandlers;
@property (strong, nonatomic) NSMutableArray *didDisableWildcardOverrideHandlers;

@end

@implementation GBFeatureManager

#pragma mark - memory

_singleton(sharedFeatureManager)

_lazy(NSMutableArray, didUnlockFeatureHandlers, _didUnlockFeatureHandlers)
_lazy(NSMutableArray, didLockFeatureHandlers, _didLockFeatureHandlers)
_lazy(NSMutableArray, didEnableWildcardOverrideHandlers, _didEnableWildcardOverrideHandlers)
_lazy(NSMutableArray, didDisableWildcardOverrideHandlers, _didDisableWildcardOverrideHandlers)

-(id)init {
    if (self = [super init]) {
        self.cache = [NSMutableDictionary new];
    }
    return self;
}

-(void)dealloc {
    self.cache = nil;
    
    self.didUnlockFeatureHandlers = nil;
    self.didLockFeatureHandlers = nil;
    self.didEnableWildcardOverrideHandlers = nil;
    self.didDisableWildcardOverrideHandlers = nil;
}

#pragma mark - private API

+(NSString *)_storageKeyForFeatureID:(NSString *)featureID {
    return _f(@"%@.%@", kStorageKeyDiskPrefix, featureID);
}

+(void)_storeBoolean:(BOOL)boolean forKey:(NSString *)featureID {
    if (IsValidString(featureID)) {
        GBStorage(kStorageNamespace)[[self _storageKeyForFeatureID:featureID]] = @(boolean);
        [GBStorage(kStorageNamespace) save:[self _storageKeyForFeatureID:featureID]];
    }
    else {
        @throw [NSException exceptionWithName:@"GBFeatureManager error" reason:@"key must be non-empty NSString" userInfo:nil];
    }
}

+(BOOL)_readBooleanForKey:(NSString *)featureID {
    if (IsValidString(featureID)) {
        id result = GBStorage(kStorageNamespace)[[self _storageKeyForFeatureID:featureID]];
        
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

#pragma mark - public API

+(void)unlockFeature:(NSString *)featureID {
    [self _storeBoolean:YES forKey:featureID];
    [[NSNotificationCenter defaultCenter] postNotificationName:kGBFeatureManagerFeatureUnlockedNotification object:self userInfo:@{kGBFeatureManagerFeatureIdentifierKey: featureID}];
    
    for (GBFeatureManagerFeatureStateChangedUpdateHandler handler in [GBFeatureManager featureManagerSingleton].didUnlockFeatureHandlers) {
        handler(featureID);
    }
}

+(void)lockFeature:(NSString *)featureID {
    [self _storeBoolean:NO forKey:featureID];
    [[NSNotificationCenter defaultCenter] postNotificationName:kGBFeatureManagerFeatureLockedNotification object:self userInfo:@{kGBFeatureManagerFeatureIdentifierKey: featureID}];
    
    for (GBFeatureManagerFeatureStateChangedUpdateHandler handler in [GBFeatureManager featureManagerSingleton].didLockFeatureHandlers) {
        handler(featureID);
    }
}

+(void)enableWildcardFeatureOverride {
    [self _storeBoolean:YES forKey:kWildcardFeatureKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:kGBFeatureManagerWildcardFeatureOverrideEnabledNotification object:self];
    
    for (GBFeatureManagerGenericHandler handler in [GBFeatureManager featureManagerSingleton].didEnableWildcardOverrideHandlers) {
        handler();
    }
}

+(void)disableWildcardFeatureOverride {
    [self _storeBoolean:NO forKey:kWildcardFeatureKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:kGBFeatureManagerWildcardFeatureOverrideDisabledNotification object:self];
    
    for (GBFeatureManagerGenericHandler handler in [GBFeatureManager featureManagerSingleton].didDisableWildcardOverrideHandlers) {
        handler();
    }
}

+(BOOL)isFeatureUnlocked:(NSString *)featureID {
    return [self _readBooleanForKey:kWildcardFeatureKey] || [self _readBooleanForKey:featureID];
}

+(BOOL)areFeaturesAllUnlocked:(NSArray *)featureIDs {
    return [[[featureIDs map:^id(id object) {
        return @([self isFeatureUnlocked:object]);
    }] reduce:^id(id objectA, id objectB) {
        return @([objectA boolValue] && [objectB boolValue]);
    } lastObject:@(YES)] boolValue];
}

+(BOOL)areFeaturesAnyUnlocked:(NSArray *)featureIDs {
    return [[[featureIDs map:^id(id object) {
        return @([self isFeatureUnlocked:object]);
    }] reduce:^id(id objectA, id objectB) {
        return @([objectA boolValue] || [objectB boolValue]);
    } lastObject:@(NO)] boolValue];
}

+(void)addHandlerForDidUnlockFeature:(GBFeatureManagerFeatureStateChangedUpdateHandler)handler {
    if (handler) [[GBFeatureManager featureManagerSingleton].didUnlockFeatureHandlers addObject:[handler copy]];
}

+(void)addHandlerForDidLockFeature:(GBFeatureManagerFeatureStateChangedUpdateHandler)handler {
    if (handler) [[GBFeatureManager featureManagerSingleton].didLockFeatureHandlers addObject:[handler copy]];
}

+(void)addHandlerForDidEnableWildcardFeatureOverride:(GBFeatureManagerGenericHandler)handler {
    if (handler) [[GBFeatureManager featureManagerSingleton].didEnableWildcardOverrideHandlers addObject:[handler copy]];
}

+(void)addHandlerForDidDisableWildcardFeatureOverride:(GBFeatureManagerGenericHandler)handler {
    if (handler) [[GBFeatureManager featureManagerSingleton].didDisableWildcardOverrideHandlers addObject:[handler copy]];
}

@end
