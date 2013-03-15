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

@implementation GBFeatureManager

#pragma mark - private API

+(NSString *)_storageKeyForFeatureID:(NSString *)featureID {
    return _f(@"%@-%@", kStorageKeyPrefix, featureID);
}

+(void)_storeBoolean:(BOOL)boolean forKey:(NSString *)key {
    if (IsValidString(key)) {
        GBStorage[key] = @(boolean);
        [GBStorage save];
    }
    else {
        @throw [NSException exceptionWithName:@"GBFeatureManager error" reason:@"key must be non-empty NSString" userInfo:nil];
    }
}

+(BOOL)_readBooleanForKey:(NSString *)key {
    if (IsValidString(key)) {
        id result = GBStorage[key];
        if ([result isMemberOfClass:[NSNumber class]] && [result boolValue]) {
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

@end
