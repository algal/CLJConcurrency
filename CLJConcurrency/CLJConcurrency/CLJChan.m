//
//  CLJChan.m
//  CLJConcurrency
//
//  Created by Alexis Gallagher on 2014-05-28.
//  Copyright (c) 2014 Bloom FIlter. All rights reserved.
//

#import "CLJChan.h"


@interface CLJChanBuffer : NSObject
@property (assign,nonatomic,readonly) CLJChannelBufferType bufferType;
@property (assign,nonatomic,readonly) NSUInteger items;
- (BOOL) isUnblockingBuffer;
@end

@interface CLJChanBuffer ()
@property (strong,nonatomic) NSMutableArray * array;
@end

@implementation CLJChanBuffer
- (instancetype) initWithBufferType:(CLJChannelBufferType)type size:(NSUInteger)items
{
  self = [super init];
  if (self) {
    self->_bufferType = type;
    self->_items = items;
    self->_array = [NSMutableArray arrayWithCapacity:items];
  }
  return self;
}

/**
 Can this buffer accept a put?
 
 @discussion like `unblocking-buffer?`
 */
- (BOOL) isUnblockingBuffer
{
  return
  ([self.array count] < self.items)
  ||  (CLJChannelBufferTypeDropping == self.bufferType)
  ||  (CLJChannelBufferTypeSliding == self.bufferType);
}

/*! is it empty? */
- (BOOL) empty
{
  return [self.array count] == 0;
}

/**
 Adds an item to the buffer, ASSUMEing it is in a valid state
 */
- (void) put:(id) value
{
  // if there's space, add an item
  if ([self.array count] < self.items) {
    [self.array addObject:value];
  }
  else if (self.bufferType == CLJChannelBufferTypeDropping) {
    return;
  }
  else if (self.bufferType == CLJChannelBufferTypeSliding) {
    // remove object at head
    [self.array removeObjectAtIndex:0];
    // add an
    [self.array addObject:value];
  }
  else {
    NSLog(@"ERROR: put called when buffer had no capacity. dropping value");
  }
}

/*! Takes and returns an item from the buffer, ASSUMEing it has items */
- (id) take
{
  id val = [self.array objectAtIndex:0];
  [self.array removeObjectAtIndex:0];
  return val;
}
@end


@interface CLJChan()
@property (strong,nonatomic) CLJChanBuffer * buffer;
// Serializes access to the buffer, providing needing blocking semantics
@property (strong,nonatomic) dispatch_queue_t serialQeueue;
@end

@implementation CLJChan

- (instancetype) initWithBufferType:(CLJChannelBufferType)type size:(NSUInteger)items
{
  self = [super init];
  if (self) {
    self->_buffer = [[CLJChanBuffer alloc] initWithBufferType:type size:items];
    self->_serialQeueue = dispatch_queue_create("CLJChan", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

+ (instancetype) channelWithBufferType:(CLJChannelBufferType)type
                                  size:(NSUInteger)items
{
  return [[CLJChan alloc] initWithBufferType:type size:items];
}

- (void) put:(id) value
{
  // FIXME;
  return;
}
- (id) take
{
  // FIXME;
  return nil;
}

- (void) close
{
  // FIXME: implement
  return;
}

@end
