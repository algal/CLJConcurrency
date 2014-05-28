//
//  CLJDelay.h
//  CLJConcurrency
//
//  Created by Alexis Gallagher on 2014-05-27.
//  Copyright (c) 2014 Bloom FIlter. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 A delay object contains a value that will be computed on-demand, and then cached.
 
 You create a delay by providing a block that computes and returns
 the value. Creation is asynchronous, so the delay is created immediately.
 
 Access is synchronous. So if the value has not yet been computed,
 your attempt to read the value will block until it is ready.
 
 */
@interface CLJDelay : NSObject

+ (instancetype) delayWithValueFromBlock:(id (^)(void))fn;

/** Tells if the future value has been realized (i.e., computed) */
@property (assign,nonatomic,readonly) BOOL isRealized;

/** Returns the value returned by fn, computing it if necessary.
 */
@property (strong,nonatomic,readonly) id value;

@end
