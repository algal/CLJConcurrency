//
//  CLJConcurrencyTests.m
//  CLJConcurrencyTests
//
//  Created by Alexis Gallagher on 2014-03-30.
//  Copyright (c) 2014 Bloom FIlter. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "CLJFuture.h"
#import "CLJDelay.h"

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

#pragma mark - tests of CLJFuture

- (void) testFutureValue
{
  CLJFuture * futureSum = [CLJFuture futureWithValueFromBlock:^id{
    return @(40 +2);
  }];
  XCTAssertEqualObjects(@(42), futureSum.value, @"sums");
}

- (void) testIsRealized
{
  CLJFuture * futureValue = [CLJFuture futureWithValueFromBlock:^id{
    sleep(1);
    return @(1);
  }];
  XCTAssertEqual(NO, futureValue.isRealized, @"not realized");
  sleep(2);
  XCTAssertEqual(YES, futureValue.isRealized, @"not realized");
  XCTAssertEqualObjects(@(1),futureValue.value,@"sums2");
}

- (void) testAsyncOrdering
{
  __block NSMutableArray * results = [NSMutableArray array];
  CLJFuture * delayedSum = [CLJFuture futureWithValueFromBlock:^id{
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
  
  CLJFuture *  v = [CLJFuture futureWithValueFromBlock:^id{
    sleep(3);
    return @(1);
  }];
  
  NSNumber * n = v.value;
  CFAbsoluteTime const end = CFAbsoluteTimeGetCurrent();
  CFTimeInterval interval = end-start;
  XCTAssert(interval >= (CFTimeInterval)3.0, @"value deref delayed execution");
  XCTAssertEqualObjects(@(1), n, @"future value");
}

- (void) testDerefBlocksWithTimeout
{
  NSString * const computedValue = @"computed value";
  NSString * const timeoutValue = @"timeout value";
  
  CFAbsoluteTime const start = CFAbsoluteTimeGetCurrent();
  CLJFuture *  v = [CLJFuture futureWithValueFromBlock:^id{
    sleep(5); // compute for 5 seconds
    return computedValue;
  }];
  
  // timeout after 2 seconds
  id result = [v valueUnlessTimeout:2.0f timeoutValue:timeoutValue];
  CFAbsoluteTime const end = CFAbsoluteTimeGetCurrent();
  CFTimeInterval interval = end-start;
  XCTAssert(interval >= (CFTimeInterval)2.0, @"value deref delayed execution");
  XCTAssert(interval < (CFTimeInterval)5.0, @"value deref delayed execution");
  XCTAssertEqualObjects(timeoutValue, result, @"future value is not timeout value");
  sleep(4); // wait 4 more seconds for computation to finish
  XCTAssertEqualObjects(timeoutValue, result, @"far future value is not computed value");
}

#pragma mark - tests of CLJDelay

- (void) testDelay
{
  CLJDelay * futureSum = [CLJDelay delayWithValueFromBlock:^id{
    return @(40 +2);
  }];
  XCTAssertEqualObjects(@(42), futureSum.value, @"sums");
  XCTAssertTrue(futureSum.isRealized, @"delay not reporting as realized");
}

- (void) testDelayIsNotRealized
{
  CLJDelay * futureSum = [CLJDelay delayWithValueFromBlock:^id{
    return @(40 +2);
  }];
  XCTAssertFalse(futureSum.isRealized, @"delay is incorreectly reporting itself realized");
}

@end
