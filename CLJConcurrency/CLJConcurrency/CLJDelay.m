//
//  CLJDelay.m
//  CLJConcurrency
//
//  Created by Alexis Gallagher on 2014-05-27.
//  Copyright (c) 2014 Bloom FIlter. All rights reserved.
//

#import "CLJDelay.h"

@interface CLJDelay ()
@property (strong,nonatomic) id (^block)(void) ;
@property (assign,nonatomic,readwrite) BOOL isRealized;
@property (strong,nonatomic,readwrite) id value;
@end

@implementation CLJDelay

+ (instancetype) delayWithValueFromBlock:(id (^)(void))fn
{
  return [[CLJDelay alloc] initWithBlock:fn];
}

- (instancetype)initWithBlock:(id (^)(void))block
{
    self = [super init];
    if (self)
    {
      self->_isRealized = NO;
      self->_block = block;
    }
    return self;
}

- (id) value
{
  if (self.isRealized) {
    return self->_value;
  }
  else {
    self->_value = self.block();
    self.isRealized = YES;
    return self->_value;
  }
}

@end
