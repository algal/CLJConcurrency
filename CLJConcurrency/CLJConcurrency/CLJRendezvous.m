//
//  CLJRendezvous.m
//  CLJConcurrency
//
//  Created by Alexis Gallagher on 2014-05-30.
//  Copyright (c) 2014 Bloom FIlter. All rights reserved.
//

#import "CLJRendezvous.h"


@interface CLJRendezvous ()
@property (strong,nonatomic) dispatch_semaphore_t semaSet;
@property (strong,nonatomic) dispatch_semaphore_t semaGet;

@property (strong,nonatomic) dispatch_semaphore_t semaA1;
@property (strong,nonatomic) dispatch_semaphore_t semaB1;
@end

@implementation CLJRendezvous
{
  id _value;
}

- (id)init
{
  self = [super init];
  if (self) {
    self->_value = nil;
    self->_semaSet = dispatch_semaphore_create(0);
    self->_semaGet = dispatch_semaphore_create(0);
    self->_semaA1 = dispatch_semaphore_create(0);
    self->_semaB1 = dispatch_semaphore_create(0);
  }
  return self;
}

- (void) setValue:(id)value
{
  self->_value = value;
  dispatch_semaphore_signal(self.semaSet);
  dispatch_semaphore_wait(self.semaGet, DISPATCH_TIME_FOREVER);
  self->_value = nil;
}

- (id) value
{
  dispatch_semaphore_signal(self.semaGet);
  dispatch_semaphore_wait(self.semaSet, DISPATCH_TIME_FOREVER);
  return nil;
}

- (void) a
{
  dispatch_semaphore_signal(self.semaA1);
  dispatch_semaphore_wait(self.semaB1, DISPATCH_TIME_FOREVER);
}

- (void) b
{
  dispatch_semaphore_signal(self.semaB1);
  dispatch_semaphore_wait(self.semaA1, DISPATCH_TIME_FOREVER);
}


@end
