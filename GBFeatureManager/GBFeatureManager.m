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

#if TARGET_OS_IPHONE
    #import "GBStorageController.h"
    #import "GBToolbox.h"
#else
    #import <GBStorageController/GBStorageController.h>
    #import <GBToolbox/GBToolbox.h>
#endif

static NSString * const kStorageKeyPrefix = @"gb-feature-manager-feature-id";
static NSString * const kWildcardFeatureKey = @"gb-feature-manager-wildcard-feature-id";

@interface GBFeatureManager ()

@property (strong, nonatomic) NSMutableDictionary   *cache;

@end

@implementation GBFeatureManager

#pragma mark - memory

_singleton(GBFeatureManager, featureManagerSingleton)

-(id)init {
    if (self = [super init]) {
        self.cache = [NSMutableDictionary new];
    }
    return self;
}

-(void)dealloc {
    self.cache = nil;
}

#pragma mark - private API

+(NSString *)_storageKeyForFeatureID:(NSString *)featureID {
    return _f(@"%@-%@", kStorageKeyPrefix, featureID);
}

+(void)_storeBoolean:(BOOL)boolean forKey:(NSString *)key {
    if (IsValidString(key)) {
        //save to cache
        [GBFeatureManager featureManagerSingleton].cache[key] = @(boolean);
        
        //save to disk
        GBStorage[key] = @(boolean);
        [GBStorage save];
    }
    else {
        @throw [NSException exceptionWithName:@"GBFeatureManager error" reason:@"key must be non-empty NSString" userInfo:nil];
    }
}

+(BOOL)_readBooleanForKey:(NSString *)key {
    if (IsValidString(key)) {
        //check cache first
        if (IsTruthy([GBFeatureManager featureManagerSingleton].cache[key])) {
            return [[GBFeatureManager featureManagerSingleton].cache[key] boolValue];
        }
        else {
            //fetch from disk
            id result = GBStorage[key];
            
            //update cache
            if (IsTruthy(result)) {
                [GBFeatureManager featureManagerSingleton].cache[key] = result;
            }
            else {
                [GBFeatureManager featureManagerSingleton].cache[key] = @(NO);
            }
            
            //boolianize result
            if ([result isKindOfClass:[NSNumber class]] && [result boolValue]) {
                return YES;
            }
            else {
                return NO;
            }
        }
    }
    else {
        @throw [NSException exceptionWithName:@"GBFeatureManager error" reason:@"key must be non-empty NSString" userInfo:nil];
    }
}

#pragma mark - public API

+(void)unlockFeature:(NSString *)featureID {
    [self _storeBoolean:YES forKey:[self _storageKeyForFeatureID:featureID]];
}

+(void)lockFeature:(NSString *)featureID {
    [self _storeBoolean:NO forKey:[self _storageKeyForFeatureID:featureID]];
}

+(void)enableWildcardFeatureOverride {
    [self _storeBoolean:YES forKey:kWildcardFeatureKey];
}

+(void)disableWildcardFeatureOverride {
    [self _storeBoolean:NO forKey:kWildcardFeatureKey];
}

+(BOOL)isFeatureUnlocked:(NSString *)featureID {
    return [self _readBooleanForKey:kWildcardFeatureKey] || [self _readBooleanForKey:[self _storageKeyForFeatureID:featureID]];
}

+(BOOL)areFeaturesAllUnlocked:(NSArray *)featureIDs {
    return [[[featureIDs map:^id(id object) {
        return @([self isFeatureUnlocked:object]);
    }] reduce:^id(id objectA, id objectB) {
        return @([objectA boolValue] && [objectB boolValue]);
    } lastObject:@(YES)] boolValue];
}

@end
