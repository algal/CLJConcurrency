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

- (void) testFutureValue
{
  CLJFuture * futureSum = [[CLJFuture alloc] initWithBlock:^id{
    return @(40 +2);
  }];
  XCTAssertEqualObjects(@(42), futureSum.value, @"sums");
}

- (void) testIsRealized
{
  CLJFuture * delayedValue = [[CLJFuture alloc] initWithBlock:^id{
    sleep(1);
    return @(1);
  }];
  XCTAssertEqual(NO, delayedValue.isRealized, @"not realized");
  sleep(2);
  XCTAssertEqual(YES, delayedValue.isRealized, @"not realized");
  XCTAssertEqualObjects(@(1),delayedValue.value,@"sums2");
}

- (void) testAsyncOrdering
{
  __block NSMutableArray * results = [NSMutableArray array];
  CLJFuture * delayedSum = [[CLJFuture alloc] initWithBlock:^id{
    sleep(1);
    [results addObject:@"second"];
    return nil;
  }];
  XCTAssertEqual(NO, delayedSum.isRealized, @"not realized");
  [results addObject:@"first"];
  sleep(2);
  XCTAssertEqual(YES, delayedSum.isRealized, @"not realized");

  NSArray * expected = @[@"first",@"second"];
  XCTAssertEqualObjects(expected,results,@"sums2");
}

- (void) testDerefBlocks
{
  CFAbsoluteTime const start = CFAbsoluteTimeGetCurrent();
  
  CLJFuture *  v = [[CLJFuture alloc] initWithBlock:^id{
    sleep(3);
    return @(1);
  }];
  
  NSNumber * n = v.value;
  CFAbsoluteTime const end = CFAbsoluteTimeGetCurrent();
  CFTimeInterval interval = end-start;
  XCTAssert(interval >= (CFTimeInterval)3.0, @"value deref delayed execution");
  XCTAssertEqualObjects(@(1), n, @"future value");
}

@end
