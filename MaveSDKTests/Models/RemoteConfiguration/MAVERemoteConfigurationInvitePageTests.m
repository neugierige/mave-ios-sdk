//
//  MAVERemoteConfigurationInvitePageTests.m
//  MaveSDK
//
//  Created by Danny Cosson on 3/9/15.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MAVERemoteConfigurationInvitePageChoice.h"

@interface MAVERemoteConfigurationInvitePageTests : XCTestCase

@end

@implementation MAVERemoteConfigurationInvitePageTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testDefaultJSON {
    NSDictionary *defaults = [MAVERemoteConfigurationInvitePageChoice defaultJSONData];
    XCTAssertEqual([defaults count], 2);
    XCTAssertEqualObjects([defaults objectForKey:@"primary_page"], @"contacts_invite_page");
    XCTAssertEqualObjects([defaults objectForKey:@"fallback_page"], @"share_page");
}

- (void)testInitWithDefaultData {
    MAVERemoteConfigurationInvitePageChoice *invitePage = [[MAVERemoteConfigurationInvitePageChoice alloc] initWithDictionary:[MAVERemoteConfigurationInvitePageChoice defaultJSONData]];

    XCTAssertEqual(invitePage.primaryPageType, MAVEInvitePageTypeContactsInvitePage);
    XCTAssertEqual(invitePage.fallbackPageType, MAVEInvitePageTypeSharePage);
}

- (void)testInitWithOtherPageOptions {
    NSDictionary *options = @{@"primary_page": @"share_page",
                              @"fallback_page": @"client_sms"};

    MAVERemoteConfigurationInvitePageChoice *invitePage = [[MAVERemoteConfigurationInvitePageChoice alloc] initWithDictionary:options];

    XCTAssertEqual(invitePage.primaryPageType, MAVEInvitePageTypeSharePage);
    XCTAssertEqual(invitePage.fallbackPageType, MAVEInvitePageTypeClientSMS);
}

- (void)testInitWithInvalidOptions {
    NSDictionary *options = @{@"primary_page": @"foo",
                              @"fallback_page": @"bar"};
    MAVERemoteConfigurationInvitePageChoice *invitePage = [[MAVERemoteConfigurationInvitePageChoice alloc] initWithDictionary:options];
    XCTAssertEqual(invitePage.primaryPageType, MAVEInvitePageTypeContactsInvitePage);
    XCTAssertEqual(invitePage.fallbackPageType, MAVEInvitePageTypeSharePage);

    // or init with nil, same thing
    invitePage = [[MAVERemoteConfigurationInvitePageChoice alloc] initWithDictionary:nil];
    XCTAssertEqual(invitePage.primaryPageType, MAVEInvitePageTypeContactsInvitePage);
    XCTAssertEqual(invitePage.fallbackPageType, MAVEInvitePageTypeSharePage);
}

@end
