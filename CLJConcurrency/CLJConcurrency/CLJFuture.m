//
//  CLJFuture.m
//  CLJConcurrency
//
//  Created by Alexis Gallagher on 2014-03-30.
//  Copyright (c) 2014 Bloom FIlter. All rights reserved.
//

#import "CLJFuture.h"

@interface CLJFuture ()
@property (strong,nonatomic) dispatch_queue_t valueQueue;
@property (assign,nonatomic,readwrite) BOOL isRealized;
@property (strong,nonatomic,readwrite) id value;
@end

/**
 Represents a Clojure-like future.
 */

@implementation CLJFuture

- (instancetype) initWithBlock:(id (^)(void))blockName
{
  self.valueQueue = dispatch_queue_create("valuequeue", DISPATCH_QUEUE_SERIAL);
  self.isRealized = NO;

  __weak __typeof(self) weakSelf = self;
  dispatch_async(self.valueQueue, ^{
    __strong __typeof(weakSelf) strongSelf = weakSelf;
    strongSelf.value = blockName();
    strongSelf.isRealized = YES;
  });
  
  return nil;
}

- (id) value
{
  __block id retValue;
  dispatch_sync(self.valueQueue, ^{
    retValue = _value;
  });
  return retValue;
}

@end
