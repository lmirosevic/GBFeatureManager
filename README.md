GBFeatureManager
============

Simple iOS and Mac OS X feature manager for unlocking functionality (e.g. for IAP purchases).

Usage
------------

Unlock a feature (all features are locked by default):

```objective-c
[GBFeatureManager unlockFeature:@"speedBoost"];
```

Lock a feature:

```objective-c
[GBFeatureManager lockFeature:@"speedBoost"];
```

Check to see if a feature is unlocked:

```objective-c
[GBFeatureManager isFeatureUnlocked:@"speedBoost"];		//Returns: YES or NO
```

If you want to unlock all features + any future features, think of it as an "all features unlocked override" (this will supersede any individual setting):

```objective-c
[GBFeatureManager enableWildcardFeatureOverride];
```

To turn off the "all features unlocked override":

```objective-c
[GBFeatureManager disableWildcardFeatureOverride];
```

Don't forget to import header, for iOS:

```objective-c
#import "GBFeatureManager.h"
```

... or on OSX:

```objective-c
#import <GBFeatureManager/GBFeatureManager.h>
```

Storage mechanics
------------

Features are each stored to disk in simple serialized NSNumber object to NSDocumentsDirectory on iOS, or NSApplicationSupportDirectory OS X.

When checking whether a feature is available, the disk is only accessed the first time, and the result is cached in memory, subsequent checks never hit the disk.

Dependencies
------------

* [GBToolbox](https://github.com/lmirosevic/GBToolbox)
* [GBStorageController](https://github.com/lmirosevic/GBStorageController)

iOS: Add to your project's workspace, add dependency for GBToolbox-iOS and GBStorageController-iOS, link with your binary, add -ObjC linker flag, add header search path.

OS X: Add to your project's workspace, add dependency for GBToolbox-OSX and GBStorageController-OSX, link with your binary, add "copy file" step to copy framework into bundle.

Copyright & License
------------

Copyright 2013 Luka Mirosevic

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this work except in compliance with the License. You may obtain a copy of the License in the LICENSE file, or at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.