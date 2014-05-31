//
//  CLJChan.m
//  CLJConcurrency
//
//  Created by Alexis Gallagher on 2014-05-28.
//  Copyright (c) 2014 Bloom FIlter. All rights reserved.
//

#import "CLJChan.h"


#pragma mark - CLJChanBuffer

@interface CLJChanBuffer : NSObject
@property (assign,nonatomic,readonly) CLJChannelBufferType bufferType;
@property (assign,nonatomic,readonly) NSUInteger size;
- (BOOL) isUnblockingBuffer;
@end

/**
 CLJChanBuffer implements a thread-unsafe FIFO queue with three 
 types of buffering and associated behavior: fixed, dropping, sliding.
 */
@interface CLJChanBuffer ()
@property (strong,nonatomic) NSMutableArray * array;
@end

@implementation CLJChanBuffer
- (instancetype) initWithBufferType:(CLJChannelBufferType)type size:(NSUInteger)size
{
  self = [super init];
  if (self) {
    self->_bufferType = type;
    self->_size = size;
    self->_array = [NSMutableArray arrayWithCapacity:size];
  }
  return self;
}

/**
 Can this buffer always accept a put, no matter its state?
 
 @discussion like `unblocking-buffer?`
 */
- (BOOL) isUnblockingBuffer
{
  return
  (CLJChannelBufferTypeDropping == self.bufferType)
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
  if ([self.array count] < self.size) {
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
    NSLog(@"ERROR: put called on a fixed buffer with inadequate capacity. dropping value");
  }
}

/*! Takes and returns an item from the buffer, ASSUMEing it has items */
- (id) take
{
  if ([self.array count]==0) {
    NSLog(@"ERROR: take called on a buffer with zero elements. returning nil");
    return nil;
  }

  id val = [self.array objectAtIndex:0];
  [self.array removeObjectAtIndex:0];
  return val;
}
@end

#pragma mark - CLJChan

typedef NS_ENUM(NSInteger, CLJChanState)
{
  CLJChanStateOpenToNewPuts,
  CLJChanStateClosedOldPutsBeingProcessed,
  CLJChanStateClosedOldPutsFullyProcessed,
  CLJChanStateClosedOldPutsProcessedAndChannelEmpty
};

@interface CLJChan()
// track if channel is open, closed, etc..
@property (assign,nonatomic) CLJChanState chanState;

// Serializes put operations, preserving inter-put order and atomicity
@property (strong,nonatomic) dispatch_queue_t putQueue;
// Semaphore to allow put only when slots are free
@property (strong,nonatomic) dispatch_semaphore_t freeSlotsSemaphore;

// Serializes take operations, preserving inter-take order and atomicity
@property (strong,nonatomic) dispatch_queue_t takeQueue;
// Semaphore to allow take only when items are available
@property (strong,nonatomic) dispatch_semaphore_t availableItemsSemaphore;

// Serializes put & take operations, enforcing put-vs-take atomicity
@property (strong,nonatomic) dispatch_queue_t serialQueue;

// underlying, thread-unsafe FIFO queue structure
@property (strong,nonatomic) CLJChanBuffer * buffer;

@end


@implementation CLJChan

- (instancetype) initWithBufferType:(CLJChannelBufferType)type size:(NSUInteger)items
{
  self = [super init];
  if (self) {
    self->_chanState = CLJChanStateOpenToNewPuts;
    
    self->_buffer = [[CLJChanBuffer alloc] initWithBufferType:type size:items];
    self->_serialQueue = dispatch_queue_create("CLJChanAccess",
                                               DISPATCH_QUEUE_SERIAL);
    
    self->_putQueue = dispatch_queue_create("CLJChanPut",
                                            DISPATCH_QUEUE_SERIAL);
    self->_freeSlotsSemaphore = dispatch_semaphore_create(items);
    
    
    self->_takeQueue = dispatch_queue_create("CLJChanTake",
                                             DISPATCH_QUEUE_SERIAL);
    self->_availableItemsSemaphore = dispatch_semaphore_create(0);
    
  }
  return self;
}

- (void) dealloc
{
  // FIXME: double check if this implementation is kosher
  /*
   cannot release unbalanced semaphores, so we take the 
   remaining items from the channel here just in order to rebalance them.
   
   This may be dangerous because we are sending messages to self within dealloc.
   */
//  for ([self close];
//       [self take] != nil;
//       [self take]) { }
  
  while (![self.buffer empty]) {
    [self take];
  }
}

+ (instancetype) channelWithBufferType:(CLJChannelBufferType)type
                                  size:(NSUInteger)items
{
  return [[CLJChan alloc] initWithBufferType:type size:items];
}

- (void) put:(id) value
{
  if (nil == value) {
    NSLog(@"error: user attempted to add a nil value to a channel. ignoring");
    return;
  }
  
  if (CLJChanStateOpenToNewPuts != self.chanState) {
    return;
  }
  

  BOOL const putShouldSometimesBlock = ![self.buffer isUnblockingBuffer];
  
  dispatch_sync(self.putQueue, ^{
    if (putShouldSometimesBlock) {
      // wait until there is a free slot to put into
      dispatch_semaphore_wait(self.freeSlotsSemaphore, DISPATCH_TIME_FOREVER);
    }

    /* 
     assert: there is a free slot in the queue.

     since this task is the only kind of task that adds items to the queue,
     and since this task is in a serial queue, we can be certain that no
     other task will execute first and consume this slot before the next 
     statement is executed.
     */
    
    dispatch_sync(self.serialQueue, ^{
      [self.buffer put:value];
      // indicate that we added an item
      dispatch_semaphore_signal(self.availableItemsSemaphore);
    });
  });
}

- (id) take
{
  BOOL const putShouldSometimesBlock = ![self.buffer isUnblockingBuffer];
  
  __block id retVal = nil;
  
  dispatch_sync(self.takeQueue, ^{
    // case: channel is closed, puts processed, and marked as empty
    if (CLJChanStateClosedOldPutsProcessedAndChannelEmpty == self.chanState) {
      retVal = nil;
      return;
    }
    // case: channel is closed, puts processed, and we now notice it is empty
    else if (CLJChanStateClosedOldPutsFullyProcessed == self.chanState
             && [self.buffer empty]) {
      self.chanState = CLJChanStateClosedOldPutsProcessedAndChannelEmpty;
      retVal = nil;
      return;
    }
    // case: channel is open (more items coming) or closed with items waiting
    else
    {
      // wait until there is an item to take
      dispatch_semaphore_wait(self.availableItemsSemaphore, DISPATCH_TIME_FOREVER);
      
      // assert: there is an item available to take
      dispatch_sync(self.serialQueue, ^{
        retVal = [self.buffer take];
        if (putShouldSometimesBlock) {
          // indicate we removed an item
          dispatch_semaphore_signal(self.freeSlotsSemaphore);
        }
      });
    }
  });
  
  return retVal;
}


- (void) close
{
  if (CLJChanStateOpenToNewPuts == self.chanState)
  {
    // set state to indicate old puts are being processed
    self.chanState = CLJChanStateClosedOldPutsBeingProcessed;

    // once all old puts are processed, update the state to say so
    dispatch_async(self.putQueue, ^{
      self.chanState = CLJChanStateClosedOldPutsFullyProcessed;
    });
  }
}

@end
