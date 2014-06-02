//
//  CLJRendezvous.h
//  CLJConcurrency
//
//  Created by Alexis Gallagher on 2014-05-30.
//  Copyright (c) 2014 Bloom FIlter. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 A simple rendezvous. a blocks until b is called, and vice vera.

 Implemented with two sempahores.
 */
@interface CLJRendezvous : NSObject
- (void) a;
- (void) b;
@end
