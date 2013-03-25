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

@interface GBFeatureManager : NSObject

+(void)unlockFeature:(NSString *)featureID;
+(void)lockFeature:(NSString *)featureID;

+(void)enableWildcardFeatureOverride;
+(void)disableWildcardFeatureOverride;

+(BOOL)isFeatureUnlocked:(NSString *)featureID;
+(BOOL)areFeaturesAllUnlocked:(NSArray *)featureIDs;

@end
