//
//  MAVEMerkleTreeInnerNode.m
//  MaveSDK
//
//  Created by Danny Cosson on 1/25/15.
//
//

#import "MAVEMerkleTreeInnerNode.h"
#import "MAVEHashingUtils.h"


@implementation MAVEMerkleTreeInnerNode {
    NSData *_hashValue;
}

- (instancetype)initWithLeftChild:(id<MAVEMerkleTreeNode>)leftChild rightChild:(id<MAVEMerkleTreeNode>)rightChild {
    if (self = [super init]) {
        self.leftChild = leftChild;
        self.rightChild = rightChild;
    }
    return self;
}

- (instancetype)initWithJSONObject:(NSDictionary *)jsonObject {
    if (self = [super init]) {

    }
    return self;
}

- (NSUInteger)treeHeight {
    // since tree is always fixed size and full/balanced, we can take left height and that's tree height
    return [self.leftChild treeHeight] + 1 ;
}

- (NSData *)hashValue {
    if (!_hashValue) {
        NSMutableData *data = [[self.leftChild hashValue] mutableCopy];
        [data appendData:[self.rightChild hashValue]];
        _hashValue = [MAVEHashingUtils md5Hash:data];
    }
    return _hashValue;
}

- (NSDictionary *)serializeToJSONObject {
    return @{@"k": [MAVEHashingUtils hexStringFromData:self.hashValue],
             @"l": [self.leftChild serializeToJSONObject],
             @"r": [self.rightChild serializeToJSONObject],
    };
}

@end