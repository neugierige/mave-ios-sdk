//
//  MAVEMerkleTreeTests.m
//  MaveSDK
//
//  Created by Danny Cosson on 1/26/15.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "MAVEMerkleTree.h"
#import "MAVEMerkleTreeInnerNode.h"
#import "MAVEMerkleTreeLeafNode.h"
#import "MAVEMerkleTreeDataEnumerator.h"
#import "MAVEMerkleTreeDataDemo.h"
#import "MAVEHashingUtils.h"

@interface MAVEMerkleTreeTests : XCTestCase

@end

@implementation MAVEMerkleTreeTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

// split a range that's a power of 2
- (void)testSplitRangeHelperFunction {
    NSRange range = NSMakeRange(0, 4);
    NSRange leftRange, rightRange;
    BOOL ok = [MAVEMerkleTree splitRange:range
                               lowerHalf:&leftRange
                               upperHalf:&rightRange];
    XCTAssertTrue(ok);
    XCTAssertEqual(leftRange.location, 0);
    XCTAssertEqual(leftRange.length, 2);
    XCTAssertEqual(rightRange.location, 2);
    XCTAssertEqual(rightRange.length, 2);

    // Now split one of them again
    NSRange newLeftRange, newRightRange;
    ok = [MAVEMerkleTree splitRange:rightRange
                          lowerHalf:&newLeftRange
                          upperHalf:&newRightRange];
    XCTAssertTrue(ok);
    XCTAssertEqual(newLeftRange.location, 2);
    XCTAssertEqual(newLeftRange.length, 1);
    XCTAssertEqual(newRightRange.location, 3);
    XCTAssertEqual(newRightRange.length, 1);

    // Split the max range
    NSRange newLeftRange2, newRightRange2;
    NSRange newRange = NSMakeRange(0, UINT64_MAX);
    NSUInteger halfSize = pow(2, 63);
    ok = [MAVEMerkleTree splitRange:newRange
                          lowerHalf:&newLeftRange2
                          upperHalf:&newRightRange2];
    XCTAssertTrue(ok);
    XCTAssertEqual(newLeftRange2.location, 0);
    XCTAssertEqual(newLeftRange2.length, halfSize);
    XCTAssertEqual(newRightRange2.location, halfSize);
    XCTAssertEqual(newRightRange2.length, halfSize);
}

- (void)testSplitRangeInvalidValues {
    // can't split length 0 or 1
    NSRange range = NSMakeRange(4, 0);
    BOOL ok = [MAVEMerkleTree splitRange:range
                               lowerHalf:nil
                               upperHalf:nil];
    XCTAssertFalse(ok);
    range = NSMakeRange(0, 1);
    ok = [MAVEMerkleTree splitRange:range
                          lowerHalf:nil
                          upperHalf:nil];
    XCTAssertFalse(ok);

    // won't split a non power of 2 or power of 2 -1 length range
    range = NSMakeRange(0, 6);
    ok = [MAVEMerkleTree splitRange:range
                          lowerHalf:nil
                          upperHalf:nil];
    XCTAssertFalse(ok);

}

- (void)testBuildMerkleTreeWithInnerAndRoot {
    NSRange range = NSMakeRange(0, 8);
    MAVEMerkleTreeDataDemo *o1 = [[MAVEMerkleTreeDataDemo alloc] initWithValue:0];
    MAVEMerkleTreeDataDemo *o2 = [[MAVEMerkleTreeDataDemo alloc] initWithValue:1];
    MAVEMerkleTreeDataDemo *o3 = [[MAVEMerkleTreeDataDemo alloc] initWithValue:2];
    MAVEMerkleTreeDataDemo *o4 = [[MAVEMerkleTreeDataDemo alloc] initWithValue:4];
    MAVEMerkleTreeDataDemo *o5 = [[MAVEMerkleTreeDataDemo alloc] initWithValue:6];
    NSArray *array = @[o1, o2, o3, o4, o5];

    MAVEMerkleTreeDataEnumerator *enumer = [[MAVEMerkleTreeDataEnumerator alloc] initWithEnumerator:[array objectEnumerator]];

    MAVEMerkleTreeInnerNode *root = [MAVEMerkleTree buildMerkleTreeOfHeight:3 withKeyRange:range dataEnumerator:enumer];

    XCTAssertEqual(root.treeHeight, 3);
    MAVEMerkleTreeInnerNode *left = root.leftChild;
    MAVEMerkleTreeInnerNode *right = root.rightChild;
    MAVEMerkleTreeLeafNode *first = left.leftChild;
    MAVEMerkleTreeLeafNode *second = left.rightChild;
    MAVEMerkleTreeLeafNode *third = right.leftChild;
    MAVEMerkleTreeLeafNode *fourth = right.rightChild;
    NSArray *expected;

    XCTAssertEqual(first.dataKeyRange.location, 0);
    XCTAssertEqual(first.dataKeyRange.length, 2);
    expected = @[o1, o2];
    XCTAssertEqualObjects(first.dataBucket, expected);

    XCTAssertEqual(second.dataKeyRange.location, 2);
    XCTAssertEqual(second.dataKeyRange.length, 2);
    expected = @[o3];
    XCTAssertEqualObjects(second.dataBucket, expected);

    XCTAssertEqual(third.dataKeyRange.location, 4);
    XCTAssertEqual(third.dataKeyRange.length, 2);
    expected = @[o4];
    XCTAssertEqualObjects(third.dataBucket, expected);

    XCTAssertEqual(fourth.dataKeyRange.location, 6);
    XCTAssertEqual(fourth.dataKeyRange.length, 2);
    expected = @[o5];
    XCTAssertEqualObjects(fourth.dataBucket, expected);
}

- (void)testBuildBigTreeWithMaxRange {
    NSRange range = NSMakeRange(0, UINT64_MAX);
    MAVEMerkleTreeDataDemo *o1 = [[MAVEMerkleTreeDataDemo alloc] initWithValue:0];
    MAVEMerkleTreeDataDemo *o2 = [[MAVEMerkleTreeDataDemo alloc] initWithValue:UINT64_MAX];
    NSArray *array = @[o1, o2];

    MAVEMerkleTreeDataEnumerator *enumer = [[MAVEMerkleTreeDataEnumerator alloc] initWithEnumerator:[array objectEnumerator]];

    MAVEMerkleTreeInnerNode *root = [MAVEMerkleTree buildMerkleTreeOfHeight:11 withKeyRange:range dataEnumerator:enumer];
    XCTAssertEqual(root.treeHeight, 11);
    NSUInteger expectedRangeSize = pow(2, 64 - (11-1));

    // check leftmost node
    MAVEMerkleTreeInnerNode *node = root;
    for (NSInteger i = 1; i < 11 - 1; ++i) {
        node = node.leftChild;
    }
    MAVEMerkleTreeLeafNode *leftLeaf = node.leftChild;
    XCTAssertEqual(leftLeaf.dataKeyRange.location, 0);
    XCTAssertEqual(leftLeaf.dataKeyRange.length, expectedRangeSize);
    XCTAssertEqualObjects(leftLeaf.dataBucket, @[o1]);

    // check rightmost node
    node = root;
    for (NSInteger i = 1; i < 11 - 1; ++i) {
        node = node.rightChild;
    }
    MAVEMerkleTreeLeafNode *rightLeaf = node.rightChild;
    XCTAssertEqual(rightLeaf.dataKeyRange.location, UINT64_MAX - expectedRangeSize + 1);
    XCTAssertEqual(rightLeaf.dataKeyRange.length, expectedRangeSize);
    XCTAssertEqualObjects(rightLeaf.dataBucket, @[o2]);
}

- (void)testDifferencesHeight1Tree {
    MAVEMerkleTreeDataDemo *obj1 = [[MAVEMerkleTreeDataDemo alloc] initWithValue:10];
    MAVEMerkleTreeDataDemo *obj2 = [[MAVEMerkleTreeDataDemo alloc] initWithValue:20];
    MAVEMerkleTreeLeafNode *node1 = [[MAVEMerkleTreeLeafNode alloc] init];
    MAVEMerkleTreeLeafNode *node2 = [[MAVEMerkleTreeLeafNode alloc] init];
    node1.dataBucket = @[obj1];
    node2.dataBucket = @[obj2];
    NSString *node1HashHex = [MAVEHashingUtils hexStringValue:[node1 hashValue]];
    NSString *node2HashHex = [MAVEHashingUtils hexStringValue:[node2 hashValue]];

    // When they're the same
    NSArray *diff1 = [MAVEMerkleTree differencesToMakeTree:node1 matchTree:node1 currentPathToNode:100];
    XCTAssertEqualObjects(diff1, @[]);

    // When different
    NSArray *diff2 = [MAVEMerkleTree differencesToMakeTree:node2 matchTree:node1 currentPathToNode:100];
    NSArray *expected2 = @[@[@(100), node1HashHex, [node1 serializeableData]]];
    XCTAssertEqualObjects(diff2, expected2);
    // reverse order
    diff2 = [MAVEMerkleTree differencesToMakeTree:node1 matchTree:node2 currentPathToNode:100];
    expected2 = @[@[@(100), node2HashHex, [node2 serializeableData]]];
    XCTAssertEqualObjects(diff2, expected2);
}

- (void)testDifferencesHeight2Trees {
    MAVEMerkleTreeDataDemo *obj1 = [[MAVEMerkleTreeDataDemo alloc] initWithValue:10];
    MAVEMerkleTreeDataDemo *obj2 = [[MAVEMerkleTreeDataDemo alloc] initWithValue:20];
    NSString *obj1HashHex = @"2a30f5f3b7d1a97cb6132480b992d984";
    NSString *obj2HashHex = @"baa9a061c77c119b99e6a82b1e741fdc";

    MAVEMerkleTreeLeafNode *left = [[MAVEMerkleTreeLeafNode alloc] init];
    left.dataBucket = @[obj1];
    MAVEMerkleTreeLeafNode *right = [[MAVEMerkleTreeLeafNode alloc] init];
    right.dataBucket = @[obj2];

    MAVEMerkleTreeInnerNode *node1 = [[MAVEMerkleTreeInnerNode alloc] initWithLeftChild:left rightChild:right];
    MAVEMerkleTreeInnerNode *node2 = [[MAVEMerkleTreeInnerNode alloc] initWithLeftChild:left rightChild:right];
    MAVEMerkleTreeInnerNode *node3 = [[MAVEMerkleTreeInnerNode alloc] initWithLeftChild:left rightChild:left];
    MAVEMerkleTreeInnerNode *node4 = [[MAVEMerkleTreeInnerNode alloc] initWithLeftChild:right rightChild:right];

    // Same trees
    NSArray *diff1 = [MAVEMerkleTree differencesToMakeTree:node1 matchTree:node2 currentPathToNode:0];
    XCTAssertEqualObjects(diff1, @[]);

    // Right child different
    NSArray *diff2 = [MAVEMerkleTree differencesToMakeTree:node3 matchTree:node1 currentPathToNode:0];
    NSArray *expected2 = @[@[@(1), obj2HashHex, @[@20]]];
    XCTAssertEqualObjects(diff2, expected2);
    // reverse order
    diff2 = [MAVEMerkleTree differencesToMakeTree:node1 matchTree:node3 currentPathToNode:0];
    expected2 = @[@[@(1), obj1HashHex, @[@10]]];
    XCTAssertEqualObjects(diff2, expected2);

    // Left child different
    NSArray *diff3 = [MAVEMerkleTree differencesToMakeTree:node4 matchTree:node1 currentPathToNode:0];
    NSArray *expected3 = @[@[@(0), obj1HashHex, @[@10]]];
    XCTAssertEqualObjects(diff3, expected3);
    // reverse order
    diff3 = [MAVEMerkleTree differencesToMakeTree:node1 matchTree:node4 currentPathToNode:0];
    expected3 = @[@[@(0), obj2HashHex, @[@20]]];
    XCTAssertEqualObjects(diff3, expected3);

    // When initial count is higher
}

@end
