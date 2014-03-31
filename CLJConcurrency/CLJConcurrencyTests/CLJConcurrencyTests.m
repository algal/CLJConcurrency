//
//  CLJConcurrencyTests.m
//  CLJConcurrencyTests
//
//  Created by Alexis Gallagher on 2014-03-30.
//  Copyright (c) 2014 Bloom FIlter. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "CLJFuture.h"

@interface CLJConcurrencyTests : XCTestCase

@end

@implementation CLJConcurrencyTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testFuture
{
  CLJFuture * futureSum = [[CLJFuture alloc] initWithBlock:^id{
    return @(40 +2);
  }];
  
  XCTAssertEqualObjects(@(42), futureSum.value, @"sums interested");
  
}


@end
