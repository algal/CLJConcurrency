//
//  CLJRendezvous.h
//  CLJConcurrency
//
//  Created by Alexis Gallagher on 2014-05-30.
//  Copyright (c) 2014 Bloom FIlter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CLJRendezvous : NSObject

- (void) setValue:(id)value;

- (id) value;

- (void) a;
- (void) b;

@end
