//
//  MAVESharer.m
//  MaveSDK
//
//  Created by Danny Cosson on 3/6/15.
//
//

#import "MAVESharer.h"
#import "MaveSDK.h"
#import "MAVEConstants.h"
#import "MAVERemoteConfiguration.h"
#import "MaveShareToken.h"
#import "MAVEClientPropertyUtils.h"

NSString * const MAVESharePageShareTypeClientSMS = @"client_sms";
NSString * const MAVESharePageShareTypeClientEmail = @"client_email";
NSString * const MAVESharePageShareTypeFacebook = @"facebook";
NSString * const MAVESharePageShareTypeTwitter = @"twitter";
NSString * const MAVESharePageShareTypeClipboard = @"clipboard";

@implementation MAVESharer

- (instancetype)initAndRetainSelf {
    if (self = [super init]) {
        self.retainedSelf = self;
    }
    return self;
}

- (void)releaseSelf {
    self.retainedSelf = nil;
    self.completionBlockClientSMS = nil;
}

+ (MFMessageComposeViewController *)composeClientSMSInviteToRecipientPhones:(NSArray *)recipientPhones completionBlock:(void (^)(MessageComposeResult))completionBlock {
    if (![MFMessageComposeViewController canSendText]) {
        MAVEErrorLog(@"Tried to do compose client sms but canSendText is false");
        return nil;
    }
    MAVESharer *ownInstance = [MAVESharerViewControllerBuilder sharerInstanceRetained];
    ownInstance.completionBlockClientSMS = completionBlock;

    MFMessageComposeViewController *composeVC = [MAVESharerViewControllerBuilder MFMessageComposeViewController];
    NSString *message = [ownInstance shareCopyFromCopy:ownInstance.remoteConfiguration.clientSMS.text andLinkWithSubRouteLetter:@"s"];

    composeVC.messageComposeDelegate = ownInstance;
    composeVC.body = message;

    if (recipientPhones && [recipientPhones count] > 0) {
        composeVC.recipients = recipientPhones;
    }

    [[MaveSDK sharedInstance].APIInterface trackShareActionClickWithShareType:MAVESharePageShareTypeClientSMS];
    return composeVC;
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {

}

#pragma mark - Helpers for building share content
- (MAVERemoteConfiguration *)remoteConfiguration {
    return [MaveSDK sharedInstance].remoteConfiguration;
}

- (NSString *)shareToken {
    MAVEShareToken *tokenObject = [[MaveSDK sharedInstance].shareTokenBuilder createObjectSynchronousWithTimeout:0];
    return tokenObject.shareToken;
}

- (NSString *)shareCopyFromCopy:(NSString *)shareCopy
      andLinkWithSubRouteLetter:(NSString *)letter {
    NSString* link = [self shareLinkWithSubRouteLetter:letter];
    NSString *outputText = shareCopy;
    if ([outputText length] == 0) {
        outputText = link;
    } else {
        // if string doesn't end in a whitespace char, append a regular space
        NSString *lastLetter = [outputText substringFromIndex:([outputText length] - 1)];
        if (![@[@" ", @"\n"] containsObject:lastLetter]) {
            outputText = [outputText stringByAppendingString:@" "];
        }
        outputText = [outputText stringByAppendingString:link];
    }
    return outputText;
}

- (NSString *)shareLinkWithSubRouteLetter:(NSString *)subRoute {
    NSString *shareToken = [self shareToken];
    NSString *output;// = MAVEShortLinkBaseURL;

    if ([shareToken length] > 0) {
        NSString *shareToken = [self shareToken];
        output = [NSString stringWithFormat:@"%@%@/%@",
                  MAVEShortLinkBaseURL, subRoute, shareToken];
    } else {
        NSString * base64AppID = [MAVEClientPropertyUtils urlSafeBase64ApplicationID];
        output = [NSString stringWithFormat:@"%@o/%@/%@",
                  MAVEShortLinkBaseURL, subRoute, base64AppID];
    }
    return output;
}

- (void)resetShareToken {
    MAVEDebugLog(@"Resetting share token after share, was: %@", [self shareToken]);
    [MAVEShareToken clearUserDefaults];
    [MaveSDK sharedInstance].shareTokenBuilder = [MAVEShareToken remoteBuilder];
}

@end


// Builder to allow mocking for testing, it just returns the different types
// of share view controllers we'll need to present after calling alloc init
@implementation MAVESharerViewControllerBuilder

+ (MAVESharer *)sharerInstanceRetained {
    return [[MAVESharer alloc] initAndRetainSelf];
}
+ (MFMessageComposeViewController *)MFMessageComposeViewController {
    return [[MFMessageComposeViewController alloc] init];
}

@end
