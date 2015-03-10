//
//  MAVEInvitePageChooserTests.m
//  MaveSDK
//
//  Created by Danny Cosson on 1/8/15.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "MAVEDisplayOptionsFactory.h"
#import "MaveSDK.h"
#import "MAVEABUtils.h"
#import "MAVEInvitePageChooser.h"
#import "MAVERemoteConfiguration.h"
#import "MAVERemoteConfigurationContactsInvitePage.h"
#import "MAVEInvitePageViewController.h"
#import "MAVECustomSharePageViewController.h"

@interface MaveSDK(Testing)
+ (void)resetSharedInstanceForTesting;
@end

@interface MAVEInvitePageChooserTests : XCTestCase

@end

@implementation MAVEInvitePageChooserTests

- (void)setUp {
    [super setUp];
    [MaveSDK resetSharedInstanceForTesting];
    [MaveSDK setupSharedInstanceWithApplicationID:@"foo123"];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInitForModalPresent {
    MAVEInvitePageDismissBlock dismissBlock = ^(UIViewController *controller, NSUInteger numberOfInvitesSent) {};
    MAVEInvitePageChooser *ipc = [[MAVEInvitePageChooser alloc] initForModalPresentWithCancelBlock:dismissBlock];

    XCTAssertEqualObjects(ipc.navigationPresentedFormat, MAVEInvitePagePresentFormatModal);
    XCTAssertEqualObjects(ipc.navigationCancelBlock, dismissBlock);
    XCTAssertNil(ipc.navigationBackBlock);
    XCTAssertNil(ipc.navigationForwardBlock);
}

- (void)testInitForPushPresent {
    MAVEInvitePageDismissBlock backBlock = ^(UIViewController *controller, NSUInteger numberOfInvitesSent) {};
    MAVEInvitePageDismissBlock nextBlock = ^(UIViewController *controller, NSUInteger numberOfInvitesSent) {};
    MAVEInvitePageChooser *ipc = [[MAVEInvitePageChooser alloc] initForPushPresentWithForwardBlock:nextBlock
                                                                                         backBlock:backBlock];

    XCTAssertEqualObjects(ipc.navigationPresentedFormat, MAVEInvitePagePresentFormatPush);
    XCTAssertEqualObjects(ipc.navigationBackBlock, backBlock);
    XCTAssertEqualObjects(ipc.navigationForwardBlock, nextBlock);
    XCTAssertNil(ipc.navigationCancelBlock);
}

#pragma mark - Test the choose and create method in different states

- (void)testChooseAndCreateUsingContactsInvitePagePrimary {
    id maveMock = OCMPartialMock([MaveSDK sharedInstance]);
    MAVERemoteConfiguration *remoteConfig = [[MAVERemoteConfiguration alloc] initWithDictionary:[MAVERemoteConfiguration defaultJSONData]];
    remoteConfig.invitePage.primaryPageType = MAVEInvitePageTypeContactsInvitePage;
    OCMStub([maveMock remoteConfiguration]).andReturn(remoteConfig);

    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    id chooserMock = OCMPartialMock(chooser);
    UIViewController *expectedVC = [[UIViewController alloc] init];
    OCMExpect([chooserMock createContactsInvitePageIfAllowed]).andReturn(expectedVC);

    UIViewController *vc = [chooser chooseAndCreateInvitePageViewController];
    XCTAssertEqualObjects(vc, expectedVC);
    XCTAssertEqualObjects(chooser.activeViewController, expectedVC);
    OCMVerifyAll(chooserMock);
}

- (void)testChooseAndCreateUsingSharePagePrimary {
    id maveMock = OCMPartialMock([MaveSDK sharedInstance]);
    MAVERemoteConfiguration *remoteConfig = [[MAVERemoteConfiguration alloc] initWithDictionary:[MAVERemoteConfiguration defaultJSONData]];
    remoteConfig.invitePage.primaryPageType = MAVEInvitePageTypeSharePage;
    OCMStub([maveMock remoteConfiguration]).andReturn(remoteConfig);

    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    UIViewController *vc = [chooser chooseAndCreateInvitePageViewController];
    XCTAssertNotNil(vc);
    XCTAssertEqualObjects(NSStringFromClass([vc class]),
                          @"MAVECustomSharePageViewController");
    XCTAssertEqualObjects(vc, chooser.activeViewController);
}

- (void)testChooseAndCreateUsingClientSMSSecondaryWhenContactsPageFails {
    id maveMock = OCMPartialMock([MaveSDK sharedInstance]);
    MAVERemoteConfiguration *remoteConfig = [[MAVERemoteConfiguration alloc] initWithDictionary:[MAVERemoteConfiguration defaultJSONData]];
    remoteConfig.invitePage.primaryPageType = MAVEInvitePageTypeContactsInvitePage;
    remoteConfig.invitePage.fallbackPageType = MAVEInvitePageTypeClientSMS;
    OCMStub([maveMock remoteConfiguration]).andReturn(remoteConfig);

    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    id chooserMock = OCMPartialMock(chooser);
    OCMExpect([chooserMock createContactsInvitePageIfAllowed]).andReturn(nil);
    // Use a mock b/c we can't use the client sms view controller on simulator
    UIViewController *expectedVC = [[UIViewController alloc] init];
    OCMExpect([chooserMock createClientSMSInvitePage]).andReturn(expectedVC);
    UIViewController *vc = [chooser chooseAndCreateInvitePageViewController];
    XCTAssertNotNil(vc);
    XCTAssertEqualObjects(vc, expectedVC);
    XCTAssertEqualObjects(vc, chooser.activeViewController);
    [maveMock stopMocking];
}

- (void)testReplaceActiveViewControllerWithFallbackWhenModalPresentationMode {
    // Mock remote config to use fallback type client sms
    id maveMock = OCMPartialMock([MaveSDK sharedInstance]);
    MAVERemoteConfiguration *remoteConfig = [[MAVERemoteConfiguration alloc] initWithDictionary:[MAVERemoteConfiguration defaultJSONData]];
    remoteConfig.invitePage.fallbackPageType = MAVEInvitePageTypeClientSMS;
    OCMStub([maveMock remoteConfiguration]).andReturn(remoteConfig);

    id navVCMock = OCMClassMock([UINavigationController class]);
    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    chooser.navigationPresentedFormat = MAVEInvitePagePresentFormatModal;
    id chooserMock = OCMPartialMock(chooser);
    OCMExpect([chooserMock activeNavigationController]).andReturn(navVCMock);
    [[navVCMock reject] popViewControllerAnimated:NO];

    UIViewController *expectedVC = [[UIViewController alloc] init];
    OCMExpect([chooserMock createClientSMSInvitePage]).andReturn(expectedVC);
    OCMExpect([navVCMock pushViewController:expectedVC animated:NO]);

    [chooser replaceActiveViewControllerWithFallbackPage];
    OCMVerifyAll(navVCMock);
    OCMVerifyAll(chooserMock);
    XCTAssertEqualObjects(chooser.activeViewController, expectedVC);
}

- (void)testReplaceActiveViewControllerWithFallbackWhenPushPresentationMode {
    // Mock remote config to use fallback type client sms
    id maveMock = OCMPartialMock([MaveSDK sharedInstance]);
    MAVERemoteConfiguration *remoteConfig = [[MAVERemoteConfiguration alloc] initWithDictionary:[MAVERemoteConfiguration defaultJSONData]];
    remoteConfig.invitePage.fallbackPageType = MAVEInvitePageTypeClientSMS;
    OCMStub([maveMock remoteConfiguration]).andReturn(remoteConfig);

    id navVCMock = OCMClassMock([UINavigationController class]);
    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    chooser.navigationPresentedFormat = MAVEInvitePagePresentFormatPush;
    id chooserMock = OCMPartialMock(chooser);
    OCMExpect([chooserMock activeNavigationController]).andReturn(navVCMock);
    OCMExpect([navVCMock popViewControllerAnimated:NO]);

    UIViewController *expectedVC = [[UIViewController alloc] init];
    OCMExpect([chooserMock createClientSMSInvitePage]).andReturn(expectedVC);
    OCMExpect([navVCMock pushViewController:expectedVC animated:NO]);

    [chooser replaceActiveViewControllerWithFallbackPage];
    OCMVerifyAll(navVCMock);
    OCMVerifyAll(chooserMock);
    XCTAssertEqualObjects(chooser.activeViewController, expectedVC);
}

#pragma mark - Create contacts invite page if allowed, test in different states

- (void)testCreateContactsInvitePageIfAllowed {
    NSLog(@"got to beginning");
    id abUtilsMock = OCMClassMock([MAVEABUtils class]);
    NSLog(@"got here");
    OCMStub([abUtilsMock addressBookPermissionStatus]).andReturn(MAVEABPermissionStatusAllowed);
    NSLog(@"got here 2");

    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    id chooserMock = OCMPartialMock(chooser);
    OCMStub([chooserMock isInSupportedRegionForServerSideSMSInvites]).andReturn(YES);
    OCMStub([chooserMock isContactsInvitePageEnabledServerSide]).andReturn(YES);
    MAVEUserData *okUserData = [[MAVEUserData alloc] init];
    okUserData.userID = @"1234"; okUserData.firstName = @"Foo";
    [MaveSDK sharedInstance].userData = okUserData;

    MAVEInvitePageViewController *vc = [chooser createContactsInvitePageIfAllowed];
    XCTAssertNotNil(vc);
    NSLog(@"got to end");
}

- (void)testCreateContactsInvitePageNotAllowedWhenABPermissionStatusDenied {
    id abUtilsMock = OCMClassMock([MAVEABUtils class]);
    OCMStub([abUtilsMock addressBookPermissionStatus]).andReturn(MAVEABPermissionStatusDenied);

    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];

    MAVEInvitePageViewController *vc = [chooser createContactsInvitePageIfAllowed];
    XCTAssertNil(vc);
}

- (void)testCreateContactsInvitePageNotAllowedWhenNotInSupportedRegion {
    id abUtilsMock = OCMClassMock([MAVEABUtils class]);
    OCMStub([abUtilsMock addressBookPermissionStatus]).andReturn(MAVEABPermissionStatusAllowed);

    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    id chooserMock = OCMPartialMock(chooser);
    OCMStub([chooserMock isInSupportedRegionForServerSideSMSInvites]).andReturn(NO);

    MAVEInvitePageViewController *vc = [chooser createContactsInvitePageIfAllowed];
    XCTAssertNil(vc);
}

- (void)testCreateContactsInvitePageNotAllowedWhenDisabledServerSide {
    id abUtilsMock = OCMClassMock([MAVEABUtils class]);
    OCMStub([abUtilsMock addressBookPermissionStatus]).andReturn(MAVEABPermissionStatusAllowed);

    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    id chooserMock = OCMPartialMock(chooser);
    OCMStub([chooserMock isInSupportedRegionForServerSideSMSInvites]).andReturn(YES);
    OCMStub([chooserMock isContactsInvitePageEnabledServerSide]).andReturn(NO);

    MAVEInvitePageViewController *vc = [chooser createContactsInvitePageIfAllowed];
    XCTAssertNil(vc);
}

- (void)testCreateContactsInvitePageNotAllowedWhenUserDataNotOK {
    id abUtilsMock = OCMClassMock([MAVEABUtils class]);
    OCMStub([abUtilsMock addressBookPermissionStatus]).andReturn(MAVEABPermissionStatusAllowed);

    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    id chooserMock = OCMPartialMock(chooser);
    OCMStub([chooserMock isInSupportedRegionForServerSideSMSInvites]).andReturn(YES);
    OCMStub([chooserMock isContactsInvitePageEnabledServerSide]).andReturn(YES);
    MAVEUserData *notOKUserData = [[MAVEUserData alloc] init]; //
    [MaveSDK sharedInstance].userData = notOKUserData;

    MAVEInvitePageViewController *vc = [chooser createContactsInvitePageIfAllowed];
    XCTAssertNil(vc);
}

- (void)testChooseAndCreateFallsBackToShareSheetIfNoUserData {
    id maveMock = OCMPartialMock([MaveSDK sharedInstance]);
    OCMStub([maveMock userData]).andReturn(nil);
    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    UIViewController *vc = [chooser chooseAndCreateInvitePageViewController];
    XCTAssertEqualObjects(NSStringFromClass([vc class]), @"MAVECustomSharePageViewController");
}


# pragma mark - Tests for logic that determines which page to show

- (void)testUSIsInSupportedRegionForServerSideSMSInvites {
    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    NSDictionary *fakeCurrentLocale = @{NSLocaleCountryCode: @"US"};

    id localeClassMock = OCMClassMock([NSLocale class]);
    OCMExpect([localeClassMock autoupdatingCurrentLocale])
        .andReturn(fakeCurrentLocale);

    XCTAssertTrue([chooser isInSupportedRegionForServerSideSMSInvites]);
    OCMVerifyAll(localeClassMock);
    [localeClassMock stopMocking];

}
- (void)testOtherCountriesNotInSupportedRegion {
    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    NSDictionary *fakeCurrentLocale = @{NSLocaleCountryCode: @"Fr"};

    id localeClassMock = OCMClassMock([NSLocale class]);
    OCMExpect([localeClassMock autoupdatingCurrentLocale])
    .andReturn(fakeCurrentLocale);

    XCTAssertFalse([chooser isInSupportedRegionForServerSideSMSInvites]);
    OCMVerifyAll(localeClassMock);
}

- (void)testIsContactsInvitePageEnabledServerSide {
    // Setup objects
    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    MAVERemoteConfiguration *remoteConfig = [[MAVERemoteConfiguration alloc] init];
    remoteConfig.contactsInvitePage = [[MAVERemoteConfigurationContactsInvitePage alloc] init];

    // Setup mock, test when enabled NO
    id configBuilderMock = OCMPartialMock([MaveSDK sharedInstance].remoteConfigurationBuilder);
    OCMExpect([configBuilderMock createObjectSynchronousWithTimeout:0]).andReturn(remoteConfig);
    remoteConfig.contactsInvitePage.enabled = NO;
    XCTAssertFalse([chooser isContactsInvitePageEnabledServerSide]);

    OCMVerifyAll(configBuilderMock);
    [configBuilderMock stopMocking];

    // Reset mock, test when enabled YES
    configBuilderMock = OCMPartialMock([MaveSDK sharedInstance].remoteConfigurationBuilder);
    remoteConfig.contactsInvitePage.enabled = YES;
    OCMExpect([configBuilderMock createObjectSynchronousWithTimeout:0]).andReturn(remoteConfig);
    XCTAssertTrue([chooser isContactsInvitePageEnabledServerSide]);

    OCMVerifyAll(configBuilderMock);
}

#pragma mark - Navigation controller setup logic

- (void)testSetupNavigationBarForActiveViewControllerModal {
    // If presented modal, should do modal button setup
    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    chooser.navigationPresentedFormat = MAVEInvitePagePresentFormatModal;
    UIViewController *vc = [[UIViewController alloc] init];
    chooser.activeViewController = vc;
    XCTAssertNil(chooser.activeViewController.navigationController);

    id chooserMock = OCMPartialMock(chooser);
    OCMExpect([chooserMock _embedActiveViewControllerInNewNavigationController]);
    OCMExpect([chooserMock _styleNavigationItemForActiveViewController]);
    OCMExpect([chooserMock _setupNavigationBarButtonsModalStyle]);

    [chooser setupNavigationBarForActiveViewController];

    OCMVerifyAll(chooserMock);
}

- (void)testSetupNavigationBarForActiveViewControllerPush {
    // If presented push, should do push button setup
    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    chooser.navigationPresentedFormat = MAVEInvitePagePresentFormatPush;
    UIViewController *vc = [[UIViewController alloc] init];
    chooser.activeViewController = vc;

    id chooserMock = OCMPartialMock(chooser);
    OCMExpect([chooserMock _embedActiveViewControllerInNewNavigationController]);
    OCMExpect([chooserMock _styleNavigationItemForActiveViewController]);
    OCMExpect([chooserMock _setupNavigationBarButtonsPushStyle]);

    [chooser setupNavigationBarForActiveViewController];

    OCMVerifyAll(chooserMock);
}

- (void)testEmbedInNavigationController {
    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    chooser.activeViewController = [[UIViewController alloc] init];
    XCTAssertNil(chooser.activeViewController.navigationController);

    [chooser _embedActiveViewControllerInNewNavigationController];

    XCTAssertNotNil(chooser.activeViewController.navigationController);
}

- (void)testStyleNavigationController {
    // Uses display options from the singleton
    [MaveSDK setupSharedInstanceWithApplicationID:@"appid1"];
    MAVEDisplayOptions *displayOpts = [MAVEDisplayOptionsFactory generateDisplayOptions];
    [MaveSDK sharedInstance].displayOptions = displayOpts;

    // set up view controller & chooser
    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    UIViewController *vc = [[UIViewController alloc] init];
    chooser.activeViewController = vc;
    [chooser _embedActiveViewControllerInNewNavigationController];

    [chooser _styleNavigationItemForActiveViewController];

    XCTAssertEqualObjects(vc.navigationItem.title, displayOpts.navigationBarTitleCopy);
    XCTAssertEqualObjects(vc.navigationController.navigationBar.barTintColor,
                          displayOpts.navigationBarBackgroundColor);
    NSDictionary *expectedTitleTextAttrs = @{
                                             NSForegroundColorAttributeName: displayOpts.navigationBarTitleTextColor,
                                             NSFontAttributeName: displayOpts.navigationBarTitleFont,
                                             };
    XCTAssertEqualObjects(vc.navigationController.navigationBar.titleTextAttributes,
                          expectedTitleTextAttrs);
}

- (void)testSetupNavigationButtonsModalWhenCustom {
    [MaveSDK sharedInstance].displayOptions.navigationBarCancelButton = [[UIBarButtonItem alloc] init];
    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    chooser.activeViewController = [[UIViewController alloc] init];

    [chooser _setupNavigationBarButtonsModalStyle];

    UIBarButtonItem *cancelButton = chooser.activeViewController.navigationItem.leftBarButtonItem;
    XCTAssertEqualObjects(cancelButton,
                          [MaveSDK sharedInstance].displayOptions.navigationBarCancelButton);
    XCTAssertEqualObjects(cancelButton.target, chooser);
    XCTAssertEqual(cancelButton.action, @selector(dismissOnCancel));
}

- (void)testSetupNavigationButtonsModalDefaults {
    [MaveSDK sharedInstance].displayOptions.navigationBarCancelButton = nil;
    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    chooser.activeViewController = [[UIViewController alloc] init];

    [chooser _setupNavigationBarButtonsModalStyle];

    UIBarButtonItem *cancelButton = chooser.activeViewController.navigationItem.leftBarButtonItem;
    XCTAssertEqualObjects(cancelButton.title, @"Cancel");
    XCTAssertEqual(cancelButton.style, UIBarButtonItemStylePlain);
    XCTAssertEqualObjects(cancelButton.target, chooser);
    XCTAssertEqual(cancelButton.action, @selector(dismissOnCancel));
}

- (void)testSetupNavigationButtonsPushWhenCustom {
    [MaveSDK sharedInstance].displayOptions.navigationBarBackButton = [[UIBarButtonItem alloc] init];
    [MaveSDK sharedInstance].displayOptions.navigationBarForwardButton = [[UIBarButtonItem alloc] init];
    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    chooser.activeViewController = [[UIViewController alloc] init];

    [chooser _setupNavigationBarButtonsPushStyle];

    UIBarButtonItem *backButton = chooser.activeViewController.navigationItem.leftBarButtonItem;
    UIBarButtonItem *forwardButton = chooser.activeViewController.navigationItem.rightBarButtonItem;
    XCTAssertEqualObjects(backButton,
                          [MaveSDK sharedInstance].displayOptions.navigationBarBackButton);
    XCTAssertEqualObjects(backButton.target, chooser);
    XCTAssertEqual(backButton.action, @selector(dismissOnBack));

    XCTAssertEqualObjects(forwardButton, [MaveSDK sharedInstance].displayOptions.navigationBarForwardButton);
    XCTAssertEqualObjects(forwardButton.target, chooser);
    XCTAssertEqual(forwardButton.action, @selector(dismissOnForward));
}

- (void)testsetupnavigationButtonsPushDefaults {
    [MaveSDK sharedInstance].displayOptions.navigationBarBackButton = nil;
    [MaveSDK sharedInstance].displayOptions.navigationBarForwardButton = nil;
    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    chooser.activeViewController = [[UIViewController alloc] init];

    [chooser _setupNavigationBarButtonsPushStyle];

    UIBarButtonItem *backButton = chooser.activeViewController.navigationItem.leftBarButtonItem;
    UIBarButtonItem *forwardButton = chooser.activeViewController.navigationItem.rightBarButtonItem;

    // Back button not build yet
    XCTAssertNil(backButton);
    XCTAssertNotNil(forwardButton);
    XCTAssertEqualObjects(forwardButton.title, @"Skip");
    XCTAssertEqual(forwardButton.style, UIBarButtonItemStylePlain);
    XCTAssertEqualObjects(forwardButton.target, chooser);
    XCTAssertEqual(forwardButton.action, @selector(dismissOnForward));
}

///
/// Forward and back/cancel actions
///
- (void)testDismissOnSuccessWhenModal {
    // When modal, dismiss on success calls the cancel block
    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    chooser.navigationPresentedFormat = MAVEInvitePagePresentFormatModal;
    chooser.activeViewController = [[UIViewController alloc] init];

    // with no back block, does nothing
    [chooser dismissOnSuccess:101];

    __block UIViewController *calledWithVC;
    __block NSUInteger numInvites;
    chooser.navigationCancelBlock = ^(UIViewController *controller, NSUInteger numberOfInvitesSent) {
        calledWithVC = controller;
        numInvites = numberOfInvitesSent;
    };

    [chooser dismissOnSuccess:102];

    XCTAssertEqualObjects(calledWithVC, chooser.activeViewController);
    XCTAssertEqual(numInvites, 102);
}

- (void)testDismissOnSuccessWhenPush {
    // When pushed, dismiss on success calls the forward block
    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    chooser.navigationPresentedFormat = MAVEInvitePagePresentFormatPush;
    chooser.activeViewController = [[UIViewController alloc] init];

    // with no back block, does nothing
    [chooser dismissOnSuccess:101];

    __block UIViewController *calledWithVC;
    __block NSUInteger numInvites;
    chooser.navigationForwardBlock = ^(UIViewController *controller, NSUInteger numberOfInvitesSent) {
        calledWithVC = controller;
        numInvites = numberOfInvitesSent;
    };

    [chooser dismissOnSuccess:102];

    XCTAssertEqualObjects(calledWithVC, chooser.activeViewController);
    XCTAssertEqual(numInvites, 102);
}

-(void)testDismissOnCancelNoBlock {
    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    chooser.activeViewController = [[UIViewController alloc] init];
    id viewMock = OCMClassMock([UIView class]);
    id vcMock = OCMPartialMock(chooser.activeViewController);
    OCMStub([vcMock view]).andReturn(viewMock);
    OCMExpect([viewMock endEditing:YES]);

    // with no back block just ends editing for the view
    [chooser dismissOnCancel];
    OCMVerifyAll(viewMock);
}

- (void)testDismissOnCancelWithBlock {
    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    chooser.activeViewController = [[UIViewController alloc] init];
    id viewMock = OCMClassMock([UIView class]);
    id vcMock = OCMPartialMock(chooser.activeViewController);
    OCMStub([vcMock view]).andReturn(viewMock);
    OCMExpect([viewMock endEditing:YES]);

    __block UIViewController *calledWithVC;
    __block NSUInteger numInvites;
    chooser.navigationCancelBlock = ^(UIViewController *controller, NSUInteger numberOfInvitesSent) {
        calledWithVC = controller;
        numInvites = numberOfInvitesSent;
    };

    [chooser dismissOnCancel];

    OCMVerifyAll(viewMock);
    XCTAssertEqualObjects(calledWithVC, chooser.activeViewController);
    XCTAssertEqual(numInvites, 0);
}

- (void)testDismissOnBack {
    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    chooser.activeViewController = [[UIViewController alloc] init];

    // with no back block, does nothing
    [chooser dismissOnBack];

    __block UIViewController *calledWithVC;
    __block NSUInteger numInvites;
    chooser.navigationBackBlock = ^(UIViewController *controller, NSUInteger numberOfInvitesSent) {
        calledWithVC = controller;
        numInvites = numberOfInvitesSent;
    };

    [chooser dismissOnBack];

    XCTAssertEqualObjects(calledWithVC, chooser.activeViewController);
    XCTAssertEqual(numInvites, 0);
}

- (void)testDismissOnForward {
    MAVEInvitePageChooser *chooser = [[MAVEInvitePageChooser alloc] init];
    chooser.activeViewController = [[UIViewController alloc] init];

    // with no back block, does nothing
    [chooser dismissOnForward];

    __block UIViewController *calledWithVC;
    __block NSUInteger numInvites;
    chooser.navigationForwardBlock = ^(UIViewController *controller, NSUInteger numberOfInvitesSent) {
        calledWithVC = controller;
        numInvites = numberOfInvitesSent;
    };

    [chooser dismissOnForward];

    XCTAssertEqualObjects(calledWithVC, chooser.activeViewController);
    XCTAssertEqual(numInvites, 0);
}

@end
