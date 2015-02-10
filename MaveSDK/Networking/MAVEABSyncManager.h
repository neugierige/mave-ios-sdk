//
//  MAVEABSyncManager.h
//  MaveSDK
//
//  Created by Danny Cosson on 1/23/15.
//
//

#import <Foundation/Foundation.h>
#import "MAVEMerkleTree.h"

@interface MAVEABSyncManager : NSObject

// pass it an array of MAVEABPerson objects, it will do the full process
//   of syncing the contacts to the server
- (void)syncContactsInBackground:(NSArray *)contacts;
- (void)doSyncContacts:(NSArray *)contacts;
- (BOOL)shouldSkipSyncCompareRemoteTreeRootToTree:(MAVEMerkleTree *)merkleTree;
- (NSArray *)changesetComparingFullRemoteTreeToTree:(MAVEMerkleTree *)merkleTree;

// OLD METHOD - now we should send the merkle tree & changesets, even if user
// has never synced address book before
// Helper to serialize the address book and gzip compress
// addressBook is an array of MAVEABPerson records
- (NSData *)serializeAndCompressAddressBook:(NSArray *)addressBook;

@end