//
//  MAVECustomContactInfoRowV3Tests.m
//  MaveSDK
//
//  Created by Danny Cosson on 5/27/15.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MAVECustomContactInfoRowV3.h"
#import "MAVEDisplayOptionsFactory.h"
#import <OCMock/OCMock.h>
#import "MAVEContactPhoneNumber.h"

@interface MAVECustomContactInfoRowV3Tests : XCTestCase

@end

@implementation MAVECustomContactInfoRowV3Tests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInitialSetup {
    UIFont *font1 = [MAVEDisplayOptionsFactory randomFont];
    UIColor *color1 = [MAVEDisplayOptionsFactory randomColor];
    UIColor *color2 = [MAVEDisplayOptionsFactory randomColor];
    MAVECustomContactInfoRowV3 *row = [[MAVECustomContactInfoRowV3 alloc] initWithFont:font1 selectedColor:color1 deselectedColor:color2];
    XCTAssertNotNil(row);
    XCTAssertNotNil(row.label);
    XCTAssertNotNil(row.checkmarkView);
    XCTAssertNotNil(row.checkmarkView.image);
    XCTAssertTrue([row.label isDescendantOfView:row]);
    XCTAssertTrue([row.checkmarkView isDescendantOfView:row]);
    XCTAssertEqual([row.gestureRecognizers count], 1);
}

- (void)testHeightGivenFont {
    UIFont *font = [UIFont systemFontOfSize:14];
    // hardcode the value we expect so test will notify us if it changes
    XCTAssertLessThan(ABS([MAVECustomContactInfoRowV3 heightGivenFont:font] - ceil(24.7f)), 0.1);
}

- (void)testSetIsSelected {
    UIFont *font1 = [MAVEDisplayOptionsFactory randomFont];
    UIColor *color1 = [MAVEDisplayOptionsFactory randomColor];
    UIColor *color2 = [MAVEDisplayOptionsFactory randomColor];
    MAVECustomContactInfoRowV3 *row = [[MAVECustomContactInfoRowV3 alloc] initWithFont:font1 selectedColor:color1 deselectedColor:color2];
    XCTAssertFalse(row.isSelected);
    XCTAssertTrue(row.checkmarkView.hidden);
    XCTAssertEqualObjects(row.label.textColor, color2);

    row.isSelected = YES;
    XCTAssertTrue(row.isSelected);
    XCTAssertFalse(row.checkmarkView.hidden);
    XCTAssertEqualObjects(row.label.textColor, color1);

    row.isSelected = NO;
    XCTAssertFalse(row.isSelected);
    XCTAssertTrue(row.checkmarkView.hidden);
    XCTAssertEqualObjects(row.label.textColor, color2);
}

- (void)testUpdateWithContactIdentifierRecord {
    MAVEContactPhoneNumber *phone = [[MAVEContactPhoneNumber alloc] initWithValue:@"+18085551234" andLabel:MAVEContactPhoneLabelHome];
    phone.selected = YES;

    UIFont *font1 = [MAVEDisplayOptionsFactory randomFont];
    UIColor *color1 = [MAVEDisplayOptionsFactory randomColor];
    UIColor *color2 = [MAVEDisplayOptionsFactory randomColor];
    MAVECustomContactInfoRowV3 *row = [[MAVECustomContactInfoRowV3 alloc] initWithFont:font1 selectedColor:color1 deselectedColor:color2];
    XCTAssertFalse(row.isSelected);

    [row updateWithContactIdentifierRecord:phone isOnlyContactIdentifier:YES];
    XCTAssertEqualObjects(row.contactIdentifierRecord, phone);
    XCTAssertEqualObjects(row.label.text, @"(808)\u00a0555-1234 (home)");
    XCTAssertTrue(row.isSelected);
}

- (void)testUpdatingContactIdentifierRecordIsSelectedAndDoLayoutUpdatesIsSelected {
    MAVEContactPhoneNumber *phone = [[MAVEContactPhoneNumber alloc] initWithValue:@"+18085551234" andLabel:MAVEContactPhoneLabelHome];
    phone.selected = NO;

    UIFont *font1 = [MAVEDisplayOptionsFactory randomFont];
    UIColor *color1 = [MAVEDisplayOptionsFactory randomColor];
    UIColor *color2 = [MAVEDisplayOptionsFactory randomColor];
    MAVECustomContactInfoRowV3 *row = [[MAVECustomContactInfoRowV3 alloc] initWithFont:font1 selectedColor:color1 deselectedColor:color2];
    [row updateWithContactIdentifierRecord:phone isOnlyContactIdentifier:YES];

    id rowMock = OCMPartialMock(row);
    OCMExpect([rowMock setIsSelected:YES]);

    phone.selected = YES;
    [row layoutIfNeeded];

    OCMVerifyAll(rowMock);
}

- (void)testTappedRow {
    UIFont *font1 = [MAVEDisplayOptionsFactory randomFont];
    UIColor *color1 = [MAVEDisplayOptionsFactory randomColor];
    UIColor *color2 = [MAVEDisplayOptionsFactory randomColor];
    MAVECustomContactInfoRowV3 *row = [[MAVECustomContactInfoRowV3 alloc] initWithFont:font1 selectedColor:color1 deselectedColor:color2];

    __block BOOL selectedStatus0 = NO;
    __block BOOL ran0 = NO;
    row.rowWasTappedBlock = ^void(BOOL isSelected) {
        selectedStatus0 = isSelected;
        ran0 = YES;
    };
    [row tappedRow];

    __block BOOL selectedStatus1 = NO;
    __block BOOL ran1 = NO;
    row.rowWasTappedBlock = ^void(BOOL isSelected) {
        selectedStatus1 = isSelected;
        ran1 = YES;
    };
    [row tappedRow];

    XCTAssertTrue(ran0);
    XCTAssertTrue(selectedStatus0);
    XCTAssertTrue(ran1);
    XCTAssertFalse(selectedStatus1);
}

@end
