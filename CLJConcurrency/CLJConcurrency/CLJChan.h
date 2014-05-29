//
//  CLJChan.h
//  CLJConcurrency
//
//  Created by Alexis Gallagher on 2014-05-28.
//  Copyright (c) 2014 Bloom FIlter. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CLJChannelBufferType)
{
  CLJChannelBufferTypeFixed,
  CLJChannelBufferTypeSliding,
  CLJChannelBufferTypeDropping
};

/**
 Like a core.async channel.
 */
@interface CLJChan : NSObject

#pragma mark core operations

/**
 Creates a channel.
 
 @param type the channel's buffer type. Buffers differ in their behavior when they are full:
 
   - Fixed buffer: when full, block calls to `put` until the buffer is emptied by a call to `take`. 
   - Dropping buffer: when full, return from `put` but ignores ("drops") the newly put value.
   - Sliding buffer: when full, return from `put` but dumps the oldest value in the channel (letting it slide off the channel)
 
 @param items the number of values allowed in the channel, by count (not e.g. by bytes)
 
 @discussion a channel is a thread-safe concurrent blocking FIFO queue. It has different buffer configurations that govern if it blocks on puts or accepts all puts but dumps some values. A channel can also be closed; once it is closed and empty, take operations return nil instead of blocking while they wait for puts.

 @return a fresh channel object
 */
+ (instancetype) channelWithBufferType:(CLJChannelBufferType)type
                                  size:(NSUInteger)items;

/**
 Puts a value into the channel, blocking if it's full and has a fixed buffer.
 
 @param value the value to insert into the channel
 */
- (void) put:(id) value;

/**
 Takes a value from the channel, blocking if its empty, returning nil if closed.
 
 @return the value from the channel, or nil if it is closed and empty
 */
- (id) take;


/**
 Closes a channel.
 
 The channel will no longer accept puts. Data in the channel remains 
 available for taking, until exhausted, after which takes will return nil.
 */
- (void) close;

#pragma mark - derived operations

@end
