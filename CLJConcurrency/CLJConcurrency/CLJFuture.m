//
//  CLJFuture.m
//  CLJConcurrency
//
//  Created by Alexis Gallagher on 2014-03-30.
//  Copyright (c) 2014 Bloom FIlter. All rights reserved.
//

#import "CLJFuture.h"

@interface CLJFuture ()
/**
 Serializes access to the ivars backing `isRealized` and `value`
 */
@property (assign,nonatomic,readwrite) BOOL isRealized;
@property (strong,nonatomic,readwrite) id value;
@property (strong,nonatomic) dispatch_semaphore_t sema;
@end

/**
 Represents a Clojure-like future.
 */
@implementation CLJFuture

+ (instancetype) futureWithValueFromBlock:(id (^)(void))fn
{
  return [[CLJFuture alloc] initWithBlock:fn];
}

- (instancetype) initWithBlock:(id (^)(void))blockName
{
  self = [super init];
  if (self) {
    self->_isRealized = NO;
    self->_sema = dispatch_semaphore_create(0);
    
    dispatch_queue_t valueQueue = dispatch_queue_create("CLJFuture", DISPATCH_QUEUE_SERIAL);
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(valueQueue, ^{
      __strong __typeof__(weakSelf) strongSelf = weakSelf;
      strongSelf.value = blockName();
      strongSelf.isRealized = YES;
      dispatch_semaphore_signal(strongSelf.sema);
    });
  }
  return self;
}

- (id) value
{
  dispatch_semaphore_wait(self.sema, DISPATCH_TIME_FOREVER);
  return self->_value;
}

- (id)valueUnlessTimeout:(NSTimeInterval)timeout timeoutValue:(id)timeoutValue
{
  dispatch_time_t const timeoutTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t) NSEC_PER_SEC * timeout);
  BOOL const success = dispatch_semaphore_wait(self.sema, timeoutTime);
  
  if (0 == success) {
    return self->_value;
  }
  else {
    return timeoutValue;
  }
}

// FIXME: implement -[CLJFuture cancel] ?
// FIXME: implement - (BOOL) [CLJFuture cancelled] ?

@end
