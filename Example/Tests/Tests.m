//
//  AYFileTests.m
//  AYFileTests
//
//  Created by Alan Yeh on 07/22/2016.
//  Copyright (c) 2016 Alan Yeh. All rights reserved.
//

@import XCTest;
#import <AYFile/AYFile.h>

@interface Tests : XCTestCase

@end

@implementation Tests

- (void)setUp{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAppendData{
    AYFile *file = [[AYFile home] child:@"test.txt"];
    [file appendData:[@"hello, " dataUsingEncoding:NSUTF8StringEncoding]];
    [file appendData:[@"world" dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSString *result = file.text;
    XCTAssert([result isEqualToString:@"hello, world"]);
    [file delete];
}

- (void)testMD5{
    AYFile *file = [[AYFile home] child:@"test.txt"];
    [file writeText:@"测试写入"];
    
    NSLog(@"%@", file.md5);
}
@end

