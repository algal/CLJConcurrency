//
//  RendezvousRef.m
//  CLJConcurrency
//
//  Created by Alexis Gallagher on 2014-06-01.
//  Copyright (c) 2014 Bloom FIlter. All rights reserved.
//

#import "CLJRendezvousRef.h"

@interface CLJRendezvousRef ()
@property (strong,nonatomic) dispatch_semaphore_t semaSetterArrived;
@property (strong,nonatomic) dispatch_semaphore_t semaGetterArrived;
@property (strong,nonatomic) dispatch_semaphore_t semaValueStored;
@end

@implementation CLJRendezvousRef
{
  id _value;
}

- (id)init
{
  self = [super init];
  if (self) {
    self->_value = nil;
    self->_semaSetterArrived = dispatch_semaphore_create(0);
    self->_semaGetterArrived = dispatch_semaphore_create(0);
    self->_semaValueStored = dispatch_semaphore_create(0);
  }
  return self;
}

- (void) setValue:(id)value
{
  dispatch_semaphore_signal(self.semaSetterArrived);
  dispatch_semaphore_wait(self.semaGetterArrived, DISPATCH_TIME_FOREVER);
  // assert: a getter thread is ready
  
  self->_value = value;
  // tell getter thread it can grab the value
  dispatch_semaphore_signal(self.semaValueStored);
}

- (id) value
{
  dispatch_semaphore_signal(self.semaGetterArrived);
  dispatch_semaphore_wait(self.semaSetterArrived, DISPATCH_TIME_FOREVER);
  // assert: a setter thread is ready
  dispatch_semaphore_wait(self.semaValueStored, DISPATCH_TIME_FOREVER);
  // assert: value is ready to return
  return self->_value;
}


@end
