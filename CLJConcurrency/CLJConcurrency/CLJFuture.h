//
//  CLJFuture.h
//  CLJConcurrency
//
//  Created by Alexis Gallagher on 2014-03-30.
//  Copyright (c) 2014 Bloom FIlter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CLJFuture : NSObject

/** Creates a future object, containing the value returned by fn */
+ (instancetype) futureWithValueFromBlock:(id (^)(void))fn
__attribute__((nonnull (1)));

/** Tells if the future value has been realized */
@property (assign,nonatomic,readonly) BOOL isRealized;

/** Returns the value returned by fn, blocking if it is not yet computed */
@property (strong,nonatomic,readonly) id value;

@end
