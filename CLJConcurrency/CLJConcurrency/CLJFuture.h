//
//  CLJFuture.h
//  CLJConcurrency
//
//  Created by Alexis Gallagher on 2014-03-30.
//  Copyright (c) 2014 Bloom FIlter. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef id(^valueReturning_t)(void);

@interface CLJFuture : NSObject

/** Creates a future, containing the value returned by fn */
- (instancetype) initWithBlock:(id (^)(void))fn;

/** Tells if the future has been realized */
@property (assign,nonatomic,readonly) BOOL isRealized;

/** Returns the value returned by fn, or blocks until it can do so */
@property (strong,nonatomic,readonly) id value;

@end
