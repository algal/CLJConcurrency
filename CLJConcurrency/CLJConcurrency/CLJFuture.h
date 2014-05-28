//
//  CLJFuture.h
//  CLJConcurrency
//
//  Created by Alexis Gallagher on 2014-03-30.
//  Copyright (c) 2014 Bloom FIlter. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 A future object represents a value that may not yet be available, 
 but will be available in the future.
 
 You create a future by providing a block that computes and returns 
 the value. Creation is asynchronous, so the future is created immediately
 while the value is computed on a background thread (not the main thread).
 
 Access is synchronous. So if the value has not yet been computed, 
 your attempt to read the value will block until it is ready.

 */
@interface CLJFuture : NSObject

/** Creates a future object, containing the value returned by fn */
+ (instancetype) futureWithValueFromBlock:(id (^)(void))fn
__attribute__((nonnull (1)));

/** Tells if the future value has been realized (i.e., computed) */
@property (assign,nonatomic,readonly) BOOL isRealized;

/** Returns the value returned by fn, blocking if it is not yet computed */
@property (strong,nonatomic,readonly) id value;

/**
 Returns either the computed value, or on timeout, the timeout value.
 
 Between now and `timeout`, blocks until and if computed value becomes avaiable. After `timeout`,
 returns the timeout value.
 
 @param timeout      time in seconds to block before returning the timeoutValue instead of the computed value
 @param timeoutValue value to return on timeout
 
 @return either the originally specified computed value, or the timeoutValue
 */
- (id)valueUnlessTimeout:(NSTimeInterval)timeout timeoutValue:(id)timeoutValue;

@end
