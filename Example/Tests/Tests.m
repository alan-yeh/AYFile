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

- (void)testExample{
//    NSString *dataStr = @"testString";
//    AYFile *file = [[AYFile tmp] write:[dataStr dataUsingEncoding:NSUTF8StringEncoding] withName:@"test.txt"];
//    NSString *resultStr = [NSString stringWithContentsOfURL:file.url encoding:NSUTF8StringEncoding error:nil];
//    
//    XCTAssert([resultStr isEqualToString:dataStr]);
//    
//    AYFile *result = [AYFile fileWithURL:file.url];
//    NSData *data = result.data;
//    NSString *resultStr2 = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    XCTAssert([resultStr2 isEqualToString:dataStr]);
}

@end

