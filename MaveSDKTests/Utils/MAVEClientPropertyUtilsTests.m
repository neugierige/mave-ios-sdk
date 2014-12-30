//
//  MAVEClientPropertyUtilsTests.m
//  MaveSDK
//
//  Created by Danny Cosson on 12/30/14.
//
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "MAVEClientPropertyUtils.h"
#import "MAVEConstants.h"
#import "MAVEIDUtils.h"

@interface MAVEClientPropertyUtilsTests : XCTestCase

@end

@implementation MAVEClientPropertyUtilsTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testEncodedAutomaticClientProperties {
    NSString *encProperties = [MAVEClientPropertyUtils encodedAutomaticClientProperties];
    NSDictionary *properties = [MAVEClientPropertyUtils base64DecodeJSONString:encProperties];
    // All properties should exist
    XCTAssertEqual([properties count], 11);
}

- (void)testBase64EncodeDictionary {
    NSDictionary *dict = @{@"foo": @YES};
    NSString *b64 = [MAVEClientPropertyUtils base64EncodeDictionary:dict];
    XCTAssertEqualObjects([MAVEClientPropertyUtils base64DecodeJSONString:b64], dict);
}


///
/// Test inidividual properties are rereasonable values
///

- (void)testAppRelease {
    NSString *appRelease = [MAVEClientPropertyUtils appRelease];
    XCTAssertNotNil(appRelease);
    NSRegularExpression *regex = [[NSRegularExpression alloc]
                                  initWithPattern:@"^[0-9]+\\.[0-9]+\\.[0-9]$" options:0 error:nil];
    NSArray *matches = [regex matchesInString:appRelease options:0 range:NSMakeRange(0, [appRelease length])];
    XCTAssertEqual([matches count], 1);
}

- (void)testAppVersion {
    XCTAssertGreaterThan([[MAVEClientPropertyUtils appVersion] intValue], 0);
}

- (void)testCountryCode {
    XCTAssertEqualObjects([MAVEClientPropertyUtils countryCode], @"US");
}

- (void)testLanguage {
    XCTAssertEqualObjects([MAVEClientPropertyUtils language], @"en");
}

- (void)testCarrier {
    // on simulator carrier will be null which we turn to unknown
    XCTAssertEqualObjects([MAVEClientPropertyUtils carrier], @"Unknown");
}

- (void)testAppDeviceID {
    id idUtilsMock = OCMClassMock([MAVEIDUtils class]);
    OCMStub([idUtilsMock loadOrCreateNewAppDeviceID]).andReturn(@"foobarid");
    XCTAssertEqualObjects([MAVEClientPropertyUtils appDeviceID], @"foobarid");
}

- (void)testManufacturer {
    XCTAssertEqualObjects([MAVEClientPropertyUtils manufacturer], @"Apple");
}

- (void)testModel {
    // Simulator model for whatever reason is just the architecture
    XCTAssertEqualObjects([MAVEClientPropertyUtils model], @"x86_64");
}

- (void)testOS {
    XCTAssertEqualObjects([MAVEClientPropertyUtils os], @"iPhone OS");
}

- (void)testOSVersion {
    NSString *osVersion = [MAVEClientPropertyUtils osVersion];
    NSRegularExpression *regex = [[NSRegularExpression alloc]
                                  initWithPattern:@"^[7-8]+\\.[0-1]$" options:0 error:nil];
    NSArray *matches = [regex matchesInString:osVersion options:0 range:NSMakeRange(0, [osVersion length])];
    XCTAssertEqual([matches count], 1);
}

@end
