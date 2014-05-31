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
#import "CLJPromise.h"
#import "CLJChan.h"

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

- (void) testFutureDerefBlocksWithTimeout
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

#pragma mark - tests of CLJPromise

- (void) testPromise
{
  CLJPromise * p = [CLJPromise promise];
  p.value = @1;
  XCTAssertEqualObjects(p.value, @1, @"promise mangled value");
}

- (void) testPromiseDerefBlocksWithTimeout
{
  NSString * const timeoutValue = @"timeout value";
  CLJPromise * p = [CLJPromise promise];
  CFAbsoluteTime const start = CFAbsoluteTimeGetCurrent();
  id result = [p valueUnlessTimeout:1.5f timeoutValue:timeoutValue];
  CFAbsoluteTime const end = CFAbsoluteTimeGetCurrent();
  XCTAssertEqualObjects(timeoutValue, result, @"promise value is not timeout value");
  XCTAssert(end-start > 1.0f, @"promise timeout deref did not wait");
}

- (void) testDoubleDelivery
{
  CLJPromise * p = [CLJPromise promise];
  p.value = @1;
  p.value = @2;
  XCTAssertEqualObjects(p.value, @1, @"promise not ignoring second deliver");
}

- (void) testPromiseBlocksOnDeref
{
  NSString * const kValueUnset = @"unset";
  NSString * const kValueSet = @"set";
  CLJPromise * p = [CLJPromise promise];
  __block id valueFromPromise = kValueUnset;
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    // try to dereference the promise in a background task
    valueFromPromise = p.value;
  });
  
  XCTAssertEqualObjects(valueFromPromise, kValueUnset, @"promise returned prematurely");
  // deliver the promise
  p.value = kValueSet;
  // (the background task to read the promise should now complete on its own. give it a sec)
  sleep(1);
  XCTAssertEqualObjects(valueFromPromise, kValueSet, @"promise did not delivery correctly");
}

#pragma mark - tests of CLJChane

- (void) testZeroBoundedChan
{
  id firstInserted = @1;
  CLJChan * chan = [CLJChan channelWithBufferType:CLJChannelBufferTypeFixed size:0];

  __block id item = nil;
  __block BOOL putCompleted= NO;
  __block BOOL takeCompleted= NO;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // should block
    [chan put:firstInserted];
    putCompleted = YES;
  });
  
//  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // should not block
    item = [chan take];
    takeCompleted = YES;
//  });

  XCTAssertEqualObjects(item, firstInserted, @"first inserted does not equal first removed");
}



- (void) testBoundedChan
{
  id firstInserted = @1;
  CLJChan * chan = [CLJChan channelWithBufferType:CLJChannelBufferTypeFixed size:3];
  [chan put:firstInserted];
  [chan put:@2];
  id firstTaken = [chan take];
  XCTAssertEqualObjects(firstTaken, firstInserted, @"first inserted does not equal first removed");
}

- (void) testDroppingChan
{
  id firstInserted = @1;
  CLJChan * chan = [CLJChan channelWithBufferType:CLJChannelBufferTypeDropping size:3];
  [chan put:firstInserted];
  for (NSUInteger i = 0; i < 10; ++i) {
    [chan put:@2];
  }
  id firstTaken = [chan take];
  XCTAssertEqualObjects(firstTaken, firstInserted, @"first inserted does not equal first removed");
}

- (void) testSlidingChan
{
  id firstInserted = @1;
  id otherItem = @2;
  CLJChan * chan = [CLJChan channelWithBufferType:CLJChannelBufferTypeSliding size:3];
  [chan put:firstInserted];
  for (NSUInteger i = 0; i < 10; ++i) {
    [chan put:otherItem];
  }
  id firstTaken = [chan take];
  XCTAssertEqualObjects(firstTaken, otherItem, @"first inserted does not equal later removed");
}

- (void) testBlockingPut
{
  CLJChan * chan = [CLJChan channelWithBufferType:CLJChannelBufferTypeFixed size:2];
  [chan put:@1];
  [chan put:@2];

  __block BOOL thirdPutProcessed = NO;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // will block until take
    [chan put:@3];
    thirdPutProcessed = YES;
  });

  XCTAssert(thirdPutProcessed==NO, @"channel did not block put");
  [chan take];

  sleep(1);

  XCTAssert(thirdPutProcessed==YES, @"take channel did not unblock channel");
  
}

- (void) testBlockingTake
{
  CLJChan * chan = [CLJChan channelWithBufferType:CLJChannelBufferTypeFixed size:1];
  
  __block id val=nil;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // will block
    val = [chan take];
  });
  
  [chan put:@1];
  sleep(1);
  // take should be processed by now
  XCTAssertEqual(val, @1, @"take not unblocked");
}

- (void) testCreateDestroyChan
{
  CLJChan * chan = [CLJChan channelWithBufferType:CLJChannelBufferTypeFixed size:1];
  chan = nil;
}

- (void) testSemaphore
{
  dispatch_semaphore_t sema = dispatch_semaphore_create(5);
  dispatch_semaphore_signal(sema);
  dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
  sema = nil;
}

- (void) testChanClose
{
  CLJChan * chan = [CLJChan channelWithBufferType:CLJChannelBufferTypeFixed size:2];
 
  // fill the channel
  [chan put:@1];
  [chan put:@2];
  
  // close the channel
  [chan close];
  
  // do no-op puts, which should not block
  for (NSUInteger i = 0; i < 50; ++i) {
    [chan put:@(i)];
  }
  
  XCTAssertEqualObjects([chan take], @1, @"unexpected value from take");
  XCTAssertEqualObjects([chan take], @2, @"unexpected value from take");
  
  XCTAssert(nil==[chan take], @"did not get nil from closed empty channel");
}
@end
