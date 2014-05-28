//
//  CLJPromise.h
//  CLJConcurrency
//
//  Created by Alexis Gallagher on 2014-05-27.
//  Copyright (c) 2014 Bloom FIlter. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 A promise contains a value that will be provided in the future.
 
 Blocks on read until the value is provided
 */
@interface CLJPromise : NSObject

+ (instancetype) promise;

@property (assign,nonatomic,readonly) BOOL isRealized;

/** Returns the value returned by fn, computing it if necessary.
 
 @discussion 
 
 the accessor `value` is like `deref` in Clojure.
 the setter `setValue` is like `deliver` in Clojure.
 */
@property (strong,nonatomic,readwrite) id value;
- (id)valueUnlessTimeout:(NSTimeInterval)timeout timeoutValue:(id)timeoutValue;
@end
