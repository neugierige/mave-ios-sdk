//
//  MAVESharer.h
//  MaveSDK
//
//  Created by Danny Cosson on 3/6/15.
//
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
#import "MAVERemoteConfiguration.h"

extern NSString * const MAVESharePageShareTypeClientSMS;
extern NSString * const MAVESharePageShareTypeClientEmail;
extern NSString * const MAVESharePageShareTypeFacebook;
extern NSString * const MAVESharePageShareTypeTwitter;
extern NSString * const MAVESharePageShareTypeClipboard;

@interface MAVESharer : NSObject <MFMessageComposeViewControllerDelegate>

@property (nonatomic, strong) MAVESharer *retainedSelf;
@property (nonatomic, strong) void(^completionBlockClientSMS)(MessageComposeResult composeResult);

- (instancetype)initAndRetainSelf;
- (void)releaseSelf;

//
// Methods to compose and share, they return UIViewControllers that need to be presented to display the compose views
//
+ (MFMessageComposeViewController *)composeClientSMSInviteToRecipientPhones:(NSArray *)recipientPhones
                                              completionBlock:(void(^)(MessageComposeResult result))completionBlock;
//
// Helpers
//
- (MAVERemoteConfiguration *)remoteConfiguration;
- (NSString *)shareToken;
- (NSString *)shareCopyFromCopy:(NSString *)shareCopy
      andLinkWithSubRouteLetter:(NSString *)letter;
// Build a link of the format: http://appjoin.us/<subRoute>/SHARE-TOKEN
- (NSString *)shareLinkWithSubRouteLetter:(NSString *)subRoute;
- (void)resetShareToken;

@end


@interface MAVESharerViewControllerBuilder : NSObject

+ (MAVESharer *)sharerInstanceRetained;
+ (MFMessageComposeViewController *)MFMessageComposeViewController;

@end