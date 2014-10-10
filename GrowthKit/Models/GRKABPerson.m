//
//  GRKABPerson.m
//  GrowthKitDevApp
//
//  Created by dannycosson on 9/25/14.
//  Copyright (c) 2014 Growthkit Inc. All rights reserved.
//

#import "GRKABPerson.h"

@implementation GRKABPerson

- (id)initFromABRecordRef:(ABRecordRef)record {
    self.firstName = (__bridge_transfer NSString *)ABRecordCopyValue(record, kABPersonFirstNameProperty);
    self.lastName = (__bridge_transfer NSString *)ABRecordCopyValue(record, kABPersonLastNameProperty);
    if (self.firstName == nil && self.lastName ==nil) {
        return nil;
    }
    [self setPhoneNumbersFromABRecordRef:record];
    if ([self.phoneNumbers count] == 0) {
        return nil;
    }
    self.emailAddresses = [[self class] emailAddressesFromABRecordRef:record];
    return self;
}

- (void)setPhoneNumbersFromABRecordRef:(ABRecordRef) record{
    ABMultiValueRef phoneMultiValue = ABRecordCopyValue(record, kABPersonPhoneProperty);
    NSUInteger numPhones = ABMultiValueGetCount(phoneMultiValue);
    NSMutableArray *phoneNumbers = [[NSMutableArray alloc] initWithCapacity:numPhones];
    NSMutableArray *phoneNumberLabels = [[NSMutableArray alloc] initWithCapacity:numPhones];
    
    NSString *pn;
    for (NSUInteger i=0; i < numPhones; i++) {
        pn = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phoneMultiValue, i);
        pn = [[self class] normalizePhoneNumber:pn];
        if (pn != nil) {
            [phoneNumbers insertObject:pn atIndex: i];
            [phoneNumberLabels
             insertObject:(__bridge_transfer NSString *)ABMultiValueCopyLabelAtIndex(phoneMultiValue, i)
             atIndex:i];
        }
    }
    if (phoneMultiValue != NULL) CFRelease(phoneMultiValue);
    self.phoneNumbers = phoneNumbers;
    self.phoneNumberLabels = phoneNumberLabels;
}

+ (NSArray *)emailAddressesFromABRecordRef:(ABRecordRef)record {
    ABMultiValueRef emailMultiValue = ABRecordCopyValue(record, kABPersonEmailProperty);
    NSUInteger numEmails = ABMultiValueGetCount(emailMultiValue);
    NSMutableArray *emailAddresses = [[NSMutableArray alloc] initWithCapacity:numEmails];
    for (NSUInteger i=0; i < numEmails; i++) {
        [emailAddresses
         insertObject:(__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(emailMultiValue, i)
         atIndex:i];
    }
    if (emailMultiValue != NULL) CFRelease(emailMultiValue);
    return (NSArray *)emailAddresses;
}

- (NSString *)firstLetter {
    NSString *compName = [self nameForCompareNames];
    NSString *letter = [compName substringToIndex:1];
    letter = [letter uppercaseString];
    return letter;
}

- (NSString *)fullName {
    NSString *name = nil;
    if (self.firstName != nil && self.lastName != nil) {
        name = [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
    } else if (self.firstName != nil) {
        name = self.firstName;
    } else if (self.lastName != nil) {
        name = self.lastName;
    }
    return name;
}

+ (NSString *)normalizePhoneNumber:(NSString *)phoneNumber {
    NSString * numOnly = [phoneNumber
                          stringByReplacingOccurrencesOfString:@"[^0-9]"
                          withString:@""
                          options:NSRegularExpressionSearch
                          range:NSMakeRange(0, [phoneNumber length])];
    if ([numOnly length] == 10) {
        numOnly = [@"1" stringByAppendingString:numOnly];
    }
    // the character "1"s unichar value is 49
    if (! ([numOnly length] == 11 && [numOnly characterAtIndex:0] == 49) ) {
        numOnly = nil;
    }
    return numOnly;
}

- (NSString *)bestPhone {
    NSString *val = nil;
    unsigned long numPhones = [self.phoneNumbers count];
    int i;
    // Check for mobile
    for (i=0; i < numPhones; i++) {
        if ([self.phoneNumberLabels[i] isEqual:@"_$!<Mobile>!$_"]) {
            val = self.phoneNumbers[i];
            break;
        }
    }
    // If not found check for Main
    if (val == nil) {
        for (i=0; i < numPhones; i++) {
            if ([self.phoneNumberLabels[i] isEqual:@"_$!<Main>!$_"]) {
                val = self.phoneNumbers[i];
                break;
            }
        }
    }
    // Otherwise use the first one
    if (val == nil && numPhones > 0) {
        val = self.phoneNumbers[0];
    }
    return val;
}

+ (NSString *)displayPhoneNumber:(NSString *)phoneNumber {
    NSString *areaCode = [phoneNumber substringWithRange:NSMakeRange(1, 3)];
    NSString *first3 = [phoneNumber substringWithRange:NSMakeRange(4, 3)];
    NSString *last4 = [phoneNumber substringWithRange:NSMakeRange(7, 4)];
    return [NSString stringWithFormat:@"(%@)\u00a0%@-%@", areaCode, first3, last4];
}


- (NSComparisonResult)compareNames:(GRKABPerson *)otherPerson {
    return [[self nameForCompareNames] compare:[otherPerson nameForCompareNames]];
}

- (NSString *)nameForCompareNames {
    NSString * fn = self.firstName;
    if (fn == nil) fn = @"";
    NSString *ln = self.lastName;
    if (ln == nil) ln = @"";
    return [NSString stringWithFormat:@"%@%@",ln,fn];
}

@end