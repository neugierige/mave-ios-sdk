//
//  MAVEAPIInterface.m
//  MaveSDK
//
//  Created by Danny Cosson on 1/2/15.
//
//

#import "MAVEAPIInterface.h"
#import "MaveSDK.h"
#import "MAVEUserData.h"
#import "MAVEConstants.h"
#import "MAVEClientPropertyUtils.h"
#import "MAVECompressionUtils.h"


NSString * const MAVERouteTrackSignup = @"/events/signup";
NSString * const MAVERouteTrackAppLaunch = @"/events/launch";
NSString * const MAVERouteTrackInvitePageOpen = @"/events/invite_page_open";
NSString * const MAVERouteTrackInvitePageSelectedContact = @"/events/selected_contact_on_invite_page";
NSString * const MAVERouteTrackShareActionClick = @"/events/share_action_click";
NSString * const MAVERouteTrackShare = @"/events/share";

NSString * const MAVERouteTrackContactsPrePermissionPromptView = @"/events/contacts_pre_permission_prompt_view";
NSString * const MAVERouteTrackContactsPrePermissionGranted = @"/events/contacts_pre_permission_granted";
NSString * const MAVERouteTrackContactsPrePermissionDenied = @"/events/contacts_pre_permission_denied";
NSString * const MAVERouteTrackContactsPermissionPromptView = @"/events/contacts_permission_prompt_view";
NSString * const MAVERouteTrackContactsPermissionGranted = @"/events/contacts_permission_granted";
NSString * const MAVERouteTrackContactsPermissionDenied = @"/events/contacts_permission_denied";

NSString * const MAVEAPIParamPrePromptTemplateID = @"contacts_pre_permission_prompt_template_id";
NSString * const MAVEAPIParamInvitePageType = @"invite_page_type";
NSString * const MAVEAPIParamContactSelectedFromList = @"from_list";
NSString * const MAVEAPIParamShareMedium = @"medium";
NSString * const MAVEAPIParamShareToken = @"share_token";
NSString * const MAVEAPIParamShareAudience = @"audience";


NSString * const MAVEAPIHeaderContextPropertiesInviteContext = @"invite_context";


@implementation MAVEAPIInterface

- (instancetype)init {
    if (self = [super init]) {
        NSString *baseURL = [MAVEAPIBaseURL stringByAppendingString:MAVEAPIVersion];
        self.httpStack = [[MAVEHTTPStack alloc] initWithAPIBaseURL:baseURL];
        MAVEInfoLog(@"Initialized on domain: %@", baseURL);
    }
    return self;
}

- (NSString *)applicationID {
    return [MaveSDK sharedInstance].appId;
}

- (NSString *)applicationDeviceID {
    return [MaveSDK sharedInstance].appDeviceID;
}

- (MAVEUserData *)userData {
    return [MaveSDK sharedInstance].userData;
}

///
/// Specific Tracking Events
///
- (void)trackAppOpen {
    [self trackGenericUserEventWithRoute:MAVERouteTrackAppLaunch
                        additionalParams:nil];
}

- (void)trackSignup {
    [self trackGenericUserEventWithRoute:MAVERouteTrackSignup additionalParams:nil];
}

- (void)trackInvitePageOpenForPageType:(NSString *)invitePageType {
    if ([invitePageType length] == 0) {
        invitePageType = @"unknown";
    }
    NSDictionary *params = @{MAVEAPIParamInvitePageType: invitePageType};
    [self trackGenericUserEventWithRoute:MAVERouteTrackInvitePageOpen
                        additionalParams:params];
}

- (void)trackInvitePageSelectedContactFromList:(NSString *)listType {
    if ([listType length] == 0) {
        listType = @"unknown";
    }
    NSDictionary *params = @{MAVEAPIParamContactSelectedFromList: listType};
    [self trackGenericUserEventWithRoute:MAVERouteTrackInvitePageSelectedContact
                        additionalParams:params];
}

- (void)trackShareActionClickWithShareType:(NSString *)shareType {
    if ([shareType length] == 0) {
        shareType = @"unknown";
    }
    [self trackGenericUserEventWithRoute:MAVERouteTrackShareActionClick
                        additionalParams:@{MAVEAPIParamShareMedium: shareType}];
}

- (void)trackShareWithShareType:(NSString *)shareType
                     shareToken:(NSString *)shareToken
                       audience:(NSString *)audience {
    if ([shareType length] == 0) {
        shareType = @"unknown";
    }
    if ([shareToken length] == 0) {
        shareToken = @"";
    }
    if ([audience length] == 0) {
        audience = @"unknown";
    }
    NSDictionary *params = @{MAVEAPIParamShareMedium: shareType,
                             MAVEAPIParamShareToken: shareToken,
                             MAVEAPIParamShareAudience: audience};
    [self trackGenericUserEventWithRoute:MAVERouteTrackShare additionalParams:params];
}

///
/// Other remote calls
///
- (void)sendInvitesWithPersons:(NSArray *)persons
                       message:(NSString *)messageText
                        userId:(NSString *)userId
      inviteLinkDestinationURL:(NSString *)inviteLinkDestinationURL
               completionBlock:(MAVEHTTPCompletionBlock)completionBlock {
    NSString *invitesRoute = @"/invites/sms";
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:persons forKey:@"recipients"];
    [params setObject:messageText forKey:@"sms_copy"];
    [params setObject:userId forKey:@"sender_user_id"];
    if ([inviteLinkDestinationURL length] > 0) {
        [params setObject:inviteLinkDestinationURL forKey:@"link_destination"];
    }
    
    [self sendIdentifiedJSONRequestWithRoute:invitesRoute
                                  methodName:@"POST"
                                      params:params
                            gzipCompressBody:NO
                             completionBlock:completionBlock];
}

- (void)identifyUser {
    NSString *launchRoute = @"/users";
    NSDictionary *params = [self.userData toDictionary];
    [self sendIdentifiedJSONRequestWithRoute:launchRoute
                                  methodName:@"PUT"
                                      params:params
                            gzipCompressBody:NO
                             completionBlock:nil];
}

- (void)sendContactsMerkleTree:(MAVEMerkleTree *)merkleTree {
    NSString *route = @"/me/contacts/merkle_tree/full";
    NSDictionary *params = [merkleTree serializable];
    if (!params) {
        MAVEErrorLog(@"Error serializing merkle tree, not sending contacts to server");
        return;
    }
    [self sendIdentifiedJSONRequestWithRoute:route
                                  methodName:@"PUT"
                                      params:params
                            gzipCompressBody:YES
                             completionBlock:nil];
}

- (void)sendContactsChangeset:(NSArray *)changeset
            isFullInitialSync:(BOOL)isFullInitialSync
            ownMerkleTreeRoot:(NSString *)ownMerkleTreeRoot
        returnClosestContacts:(BOOL)returnClosestContacts
              completionBlock:(void (^)(NSArray *closestContacts))closestContactsBlock {
    NSString *route = @"/me/contacts/sync_changesets";
    NSDictionary *params = @{@"changeset_list": changeset,
                             @"is_full_initial_sync": @(isFullInitialSync),
                             @"own_merkle_tree_root": ownMerkleTreeRoot,
                             @"return_closest_contacts": @(returnClosestContacts)};
    [self sendIdentifiedJSONRequestWithRoute:route methodName:@"POST" params:params gzipCompressBody:YES completionBlock:^(NSError *error, NSDictionary *responseData) {
        NSArray *returnVal;
        if (returnClosestContacts && !error) {
            returnVal = [responseData objectForKey:@"closest_contacts"];
            if (!returnVal || (id)returnVal == [NSNull null]) {
                returnVal = @[];
            }
        } else {
            returnVal = @[];
        }
        closestContactsBlock(returnVal);
    }];
}


//
// GET Requests
// We generally want to pre-fetch them so that when we actually want to access
// the data it's already here and there's no latency.
- (void)getReferringData:(MAVEHTTPCompletionBlock)completionBlock {
    NSString *route = @"/referring_data";

    [self sendIdentifiedJSONRequestWithRoute:route
                                  methodName:@"GET"
                                      params:nil
                            gzipCompressBody:NO
                             completionBlock:completionBlock];
}

- (void)getClosestContactsHashedRecordIDs:(void (^)(NSArray *))closestContactsBlock {
    NSString *route = @"/me/contacts/closest";
    NSArray *emptyValue = @[];
    [self sendIdentifiedJSONRequestWithRoute:route methodName:@"GET" params:nil gzipCompressBody:NO completionBlock:^(NSError *error, NSDictionary *responseData) {
        if (error) {
            closestContactsBlock(emptyValue);
        } else {
            NSArray *val = [responseData objectForKey:@"closest_contacts"];
            if (!val) {
                val = emptyValue;
            }
            closestContactsBlock(val);
        }
    }];
}

- (void)getRemoteConfigurationWithCompletionBlock:(MAVEHTTPCompletionBlock)block {
    NSString *route = @"/remote_configuration/ios";
    [self sendIdentifiedJSONRequestWithRoute:route
                                  methodName:@"GET"
                                      params:nil
                            gzipCompressBody:NO
                             completionBlock:block];
}

- (void)getNewShareTokenWithCompletionBlock:(MAVEHTTPCompletionBlock)block {
    NSString *route = @"/remote_configuration/universal/share_token";
    [self sendIdentifiedJSONRequestWithRoute:route
                                  methodName:@"GET"
                                      params:nil
                            gzipCompressBody:NO
                             completionBlock:block];
}

- (void)getRemoteContactsMerkleTreeRootWithCompletionBlock:(MAVEHTTPCompletionBlock)block {
    NSString *route = @"/me/contacts/merkle_tree/root";
    [self sendIdentifiedJSONRequestWithRoute:route
                                  methodName:@"GET"
                                      params:nil
                            gzipCompressBody:NO
                             completionBlock:block];
}

- (void)getRemoteContactsFullMerkleTreeWithCompletionBlock:(MAVEHTTPCompletionBlock)block {
    NSString *route = @"/me/contacts/merkle_tree/full";
    [self sendIdentifiedJSONRequestWithRoute:route
                                  methodName:@"GET"
                                      params:nil
                            gzipCompressBody:NO
                             completionBlock:block];
}


///
/// Request Sending Helpers
///
- (void)addCustomUserHeadersToRequest:(NSMutableURLRequest *)request {
    if (!request) {
        return;
    }
    [request setValue:self.applicationID forHTTPHeaderField:@"X-Application-Id"];
    [request setValue:self.applicationDeviceID forHTTPHeaderField:@"X-App-Device-Id"];
    NSString *userAgent = [MAVEClientPropertyUtils userAgentDeviceString];
    NSString *screenSize = [MAVEClientPropertyUtils formattedScreenSize];
    NSString *clientProperties = [MAVEClientPropertyUtils encodedAutomaticClientProperties];
    NSString *contextProperties = [MAVEClientPropertyUtils encodedContextProperties];

    [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    [request setValue:screenSize forHTTPHeaderField:@"X-Device-Screen-Dimensions"];
    [request setValue:clientProperties forHTTPHeaderField:@"X-Client-Properties"];
    [request setValue:contextProperties forHTTPHeaderField:@"X-Context-Properties"];
}

- (void)sendIdentifiedJSONRequestWithRoute:(NSString *)relativeURL
                                methodName:(NSString *)methodName
                                    params:(id)params
                          gzipCompressBody:(BOOL)gzipCompressBody
                           completionBlock:(MAVEHTTPCompletionBlock)completionBlock {
    MAVEHTTPRequestContentEncoding contentEncoding = gzipCompressBody ? MAVEHTTPRequestContentEncodingGzip : MAVEHTTPRequestContentEncodingDefault;
    NSError *requestCreationError;
    NSMutableURLRequest *request = [self.httpStack prepareJSONRequestWithRoute:relativeURL
                                                                    methodName:methodName
                                                                        params:params
                                                               contentEncoding:contentEncoding
                                                              preparationError:&requestCreationError];
    if (requestCreationError) {
        completionBlock(requestCreationError, nil);
        return;
    }
    
    [self addCustomUserHeadersToRequest:request];
    
    [self.httpStack sendPreparedRequest:request completionBlock:completionBlock];
}

- (void)trackGenericUserEventWithRoute:(NSString *)relativeRoute
                      additionalParams:(NSDictionary *)params {
    NSMutableDictionary *fullParams = [[NSMutableDictionary alloc] init];
    MAVEUserData *userData = [MaveSDK sharedInstance].userData;
    if (userData.userID) {
        [fullParams setObject:userData.userID forKey:MAVEUserDataKeyUserID];
    }
    for (NSString *key in params) {
        [fullParams setObject:[params objectForKey:key] forKey:key];
    }
    
    [self sendIdentifiedJSONRequestWithRoute:relativeRoute
                                  methodName:@"POST"
                                      params:fullParams
                            gzipCompressBody:NO
                             completionBlock:nil];
}

@end
