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

- (void)testZip{
    AYFile *file = [[AYFile home] child:@"test.txt"];
    [file writeText:@"hello world"];
    
    AYFile *zip = [file zip];
    
    XCTAssert(zip.isExists);
    [zip delete];
    [file delete];
}

- (void)testZip2{
    AYFile *file = [[AYFile home] child:@"test.txt"];
    [file writeText:@"hello world"];
    
    AYFile *zip = [file zipWithPassword:@"123456"];
    
    XCTAssert(zip.isExists);
    [zip delete];
    [file delete];
}

- (void)testZipFolder{
    AYFile *zip = [[AYFile tmp] zip];
    
    XCTAssert(zip.isExists);
}

- (void)testUnZipFolder{
    AYFile *zip = [[AYFile tmp] zip];
    [zip unZip];
}

- (void)testUnZip{
    AYFile *file = [[AYFile home] child:@"test.txt"];
    [file writeText:@"hello world"];
    
    AYFile *zip = [file zip];
    
    AYFile *unZip = [zip unZip];
    XCTAssert(unZip.isDirectory);
}

- (void)testUnZip2{
    AYFile *file = [[AYFile home] child:@"test.txt"];
    [file writeText:@"hello world"];
    
    AYFile *zip = [file zipWithPassword:@"123456"];
    
    AYFile *unZip = [zip unZipWithPassword:@"123456"];
    
    XCTAssert(unZip.isDirectory);
}

- (void)testUnZip3{
    AYFile *file = [[AYFile home] child:@"test.txt"];
    [file writeText:@"hello world"];
    
    AYFile *zip = [file zip];
    [file delete];
    
    [zip unZipToPath:zip.parent];
    XCTAssert(file.isExists);
}
@end

