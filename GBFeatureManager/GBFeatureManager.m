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

static NSString * const kStorageKeyDiskPrefix = @"gb-feature-manager-feature-id-";
static NSString * const kStorageKeyPlistPrefix = @"GBFeatureManager:";
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

+(NSString *)_diskStorageKeyForFeatureID:(NSString *)featureID {
    return _f(@"%@%@", kStorageKeyDiskPrefix, featureID);
}

+(NSString *)_plistStorageKeyForFeatureID:(NSString *)featureID {
    return _f(@"%@%@", kStorageKeyPlistPrefix, featureID);
}

+(void)_storeBoolean:(BOOL)boolean forKey:(NSString *)featureID {
    if (IsValidString(featureID)) {
        //save to cache
        [GBFeatureManager featureManagerSingleton].cache[featureID] = @(boolean);
        
        //save to disk
        GBStorage[[self _diskStorageKeyForFeatureID:featureID]] = @(boolean);
        [GBStorage save];
    }
    else {
        @throw [NSException exceptionWithName:@"GBFeatureManager error" reason:@"key must be non-empty NSString" userInfo:nil];
    }
}

+(BOOL)_readBooleanForKey:(NSString *)featureID {
    if (IsValidString(featureID)) {
        //check cache first
        if (IsTruthy([GBFeatureManager featureManagerSingleton].cache[featureID])) {
            return [[GBFeatureManager featureManagerSingleton].cache[featureID] boolValue];
        }
        else {
            //fetch from disk
            id result = GBStorage[[self _diskStorageKeyForFeatureID:featureID]];
            
            //try to fallback to reading from plist
            if (IsFalsy(result)) {
                result = InfoPlist[[self _plistStorageKeyForFeatureID:featureID]];
            }
            
            //update cache
            if (IsTruthy(result)) {
                [GBFeatureManager featureManagerSingleton].cache[featureID] = result;
            }
            else {
                [GBFeatureManager featureManagerSingleton].cache[featureID] = @(NO);
            }
            
            //booleanize result
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
    [self _storeBoolean:YES forKey:featureID];
}

+(void)lockFeature:(NSString *)featureID {
    [self _storeBoolean:NO forKey:featureID];
}

+(void)enableWildcardFeatureOverride {
    [self _storeBoolean:YES forKey:kWildcardFeatureKey];
}

+(void)disableWildcardFeatureOverride {
    [self _storeBoolean:NO forKey:kWildcardFeatureKey];
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

@end
