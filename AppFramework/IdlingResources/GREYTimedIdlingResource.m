//
// Copyright 2017 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "GREYTimedIdlingResource.h"

#import "GREYUIThreadExecutor+Private.h"
#import "GREYUIThreadExecutor.h"
#import "GREYThrowDefines.h"

@implementation GREYTimedIdlingResource {
  NSObject *_trackedObject;
  NSString *_name;
  CFTimeInterval _duration;
  CFTimeInterval _endTrackingTime;
}

+ (instancetype)resourceForObject:(NSObject *)object
            thatIsBusyForDuration:(CFTimeInterval)seconds
                             name:(NSString *)name {
  GREYTimedIdlingResource *resource =
      [[GREYTimedIdlingResource alloc] initWithObject:object trackingDuration:seconds name:name];
  [[GREYUIThreadExecutor sharedInstance] registerIdlingResource:resource];
  return resource;
}

- (void)stopMonitoring {
  _endTrackingTime = 0;
  [[GREYUIThreadExecutor sharedInstance] deregisterIdlingResource:self];
}

- (instancetype)initWithObject:(NSObject *)object
              trackingDuration:(CFTimeInterval)seconds
                          name:(NSString *)name {
  GREYThrowOnNilParameter(object);
  GREYThrowOnNilParameter(name);
  GREYThrowOnFailedConditionWithMessage(seconds >= 0, @"seconds must be positive");

  self = [super init];
  if (self) {
    _trackedObject = object;
    _duration = seconds;
    _endTrackingTime = CACurrentMediaTime() + seconds;
    _name = [name copy];
  }
  return self;
}

#pragma mark - GREYIdlingResource

- (NSString *)idlingResourceName {
  return _name;
}

- (NSString *)idlingResourceDescription {
  return [NSString stringWithFormat:@"The App will be in busy state for %g seconds because of the "
                                    @"following object:\n%@",
                                    _duration, _trackedObject];
}

- (BOOL)isIdleNow {
  if (CACurrentMediaTime() > _endTrackingTime) {
    [self stopMonitoring];
    return YES;
  }
  return NO;
}

@end
