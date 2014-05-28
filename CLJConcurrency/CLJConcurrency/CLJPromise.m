//
//  CLJPromise.m
//  CLJConcurrency
//
//  Created by Alexis Gallagher on 2014-05-27.
//  Copyright (c) 2014 Bloom FIlter. All rights reserved.
//

#import "CLJPromise.h"

@interface CLJPromise ()
@property (assign,nonatomic,readwrite) BOOL isRealized;
@property (strong,nonatomic) dispatch_semaphore_t sema;
@end

@implementation CLJPromise

@synthesize value = _value;

+ (instancetype) promise
{
  return [[CLJPromise alloc] init];
}

- (instancetype) init
{
  self = [super init];
  if (self) {
    self->_isRealized = NO;
    self->_sema = dispatch_semaphore_create(0);
  }
  return self;
}

- (void) setValue:(id)value
{
  // do not allow promise to be set more than once.
  if (self.isRealized)
  {
    return;
  }
  else
  {
    self->_isRealized = YES;
    self->_value = value;
    dispatch_semaphore_signal(self.sema);
  }
}

- (id) value
{
  if (self.isRealized)
  {
    return self->_value;
  }
  else
  {
    dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
    return self->_value;
  }
}

- (id)valueUnlessTimeout:(NSTimeInterval)timeout timeoutValue:(id)timeoutValue
{
  if (self.isRealized) {
    return self->_value;
  }
  else {
    dispatch_time_t const timeoutTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t) NSEC_PER_SEC * timeout);
    BOOL const success = dispatch_semaphore_wait(self.sema, timeoutTime);
    
    if (0 == success) {
      return self->_value;
    }
    else {
      return timeoutValue;
    }
  }
}

@end
