//
//  RendezvousRef.h
//  CLJConcurrency
//
//  Created by Alexis Gallagher on 2014-06-01.
//  Copyright (c) 2014 Bloom FIlter. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 Rendezvous passing a value. `setVaue:` blocks until `value`, and vice versa.

 This works by implementing a plain two-semaphore rendezvous in `setValue:` and `value`, so
 that either blocks on its own, and then using a third rendezvous to coordinate
 `setValue:` storing the value before `value` can return it.
 
 */
@interface CLJRendezvousRef : NSObject

- (void) setValue:(id)value;
- (id) value;

@end
