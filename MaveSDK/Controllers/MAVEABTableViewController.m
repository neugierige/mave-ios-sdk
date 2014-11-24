//
//  MAVEABTableViewController.m
//  MaveSDKDevApp
//
//  Created by dannycosson on 9/25/14.
//  Copyright (c) 2014 Growthkit Inc. All rights reserved.
//

#import "MaveSDK.h"
#import "MAVEDisplayOptions.h"
#import "MAVEABTableViewController.h"
#import "MAVEInviteExplanationView.h"
#import "MAVEABCollection.h"
#import "MAVEABPersonCell.h"
#import "MAVEABPerson.h"

@interface MAVEABTableViewController ()

@end

@implementation MAVEABTableViewController {
    NSDictionary *tableData;
    NSArray *tableSections;
}

- (instancetype)initTableViewWithParent:(id<MAVEABTableViewAdditionalDelegate>)parent {
    if(self = [super init]) {
        MAVEDisplayOptions *displayOptions = [MaveSDK sharedInstance].displayOptions;
        self.parentViewController = parent;

        self.tableView = [[UITableView alloc] init];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.backgroundColor = displayOptions.contactCellBackgroundColor;
        self.tableView.separatorColor = displayOptions.contactSeparatorColor;
        self.tableView.sectionIndexColor = displayOptions.contactSectionIndexColor;
        self.tableView.sectionIndexBackgroundColor =
            displayOptions.contactSectionIndexBackgroundColor;
        [self.tableView registerClass:[MAVEABPersonCell class] forCellReuseIdentifier:@"InvitePageABPersonCell"];
        self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

        self.aboveTableContentView = [[UIView alloc] init];
        self.aboveTableContentView.backgroundColor = self.tableView.backgroundColor;

        self.selectedPhoneNumbers = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void) updateTableData:(NSDictionary *)data {
    tableData = data;
    tableSections = [[tableData allKeys]
                       sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    [self.tableView reloadData];
}

//
// Sections
//
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [tableSections count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    float labelMarginY = 0.0;
    float labelOffsetX = 14.0;
    MAVEDisplayOptions *displayOpts = [MaveSDK sharedInstance].displayOptions;
    NSString *labelText = [self tableView:tableView
                  titleForHeaderInSection:section];
    UIFont *labelFont = displayOpts.contactSectionHeaderFont;
    CGSize labelSize = [labelText sizeWithAttributes:@{NSFontAttributeName: labelFont}];
    CGRect labelFrame = CGRectMake(labelOffsetX,
                                   labelMarginY,
                                   labelSize.width,
                                   labelSize.height);
    UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
    label.text = labelText;
    label.textColor = displayOpts.contactSectionHeaderTextColor;
    label.font = labelFont;

    CGFloat sectionHeight = labelMarginY * 2 + label.frame.size.height;
    // section width gets ignored, always stretches to full width
    CGFloat sectionWidth = 0.0;
    CGRect viewFrame = CGRectMake(0, 0, sectionWidth, sectionHeight);
    UIView *view = [[UIView alloc] initWithFrame:viewFrame];
    view.backgroundColor = displayOpts.contactSectionHeaderBackgroundColor;

    [view addSubview:label];

    return view;
}

// Since we size the headers dynamically based on height of the text
// lable, this method needs to get the actual view and check its height
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    UIView *header = [self tableView:tableView viewForHeaderInSection:section];
    return header.frame.size.height;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [tableSections objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *sectionTitle = [tableSections objectAtIndex:section];
    return [[tableData objectForKey:sectionTitle] count];
}

//
// Data Source methods
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MAVEABPersonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InvitePageABPersonCell" forIndexPath:indexPath];
    [cell setupCellWithPerson: [self personAtIndexPath:indexPath]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MAVEABPerson *person = [self personAtIndexPath:indexPath];
    person.selected = !person.selected;
    if (person.selected) {
        [self.selectedPhoneNumbers addObject:person.bestPhone];
    } else {
        [self.selectedPhoneNumbers removeObject:person.bestPhone];
    }
    [self.parentViewController ABTableViewControllerNumberSelectedChanged:[self.selectedPhoneNumbers count]];
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return tableSections;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    NSLog(@"did scroll to top");
}

// Scroll delegate methods
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    //
    // If scrolling past top, reposition content within the explanation frame to stay
    //     vertically centered to make it look like the table header view is expanding
    //
    // shift coordinates of content offsetY so scrolled to top is offset 0
    CGFloat shiftedOffsetY = scrollView.contentOffset.y + scrollView.contentInset.top;

    // TODO: use a container view so this is 0
    CGFloat DEFAULT_INNER_EXPLANATION_OFFSET = 20;
    if (self.tableView.tableHeaderView && shiftedOffsetY < 0) {
        MAVEInviteExplanationView *explanationView =
            (MAVEInviteExplanationView *)self.tableView.tableHeaderView;
        CGRect explanationTextFrame = explanationView.messageCopy.frame;
        explanationTextFrame.origin.y =
            roundf(DEFAULT_INNER_EXPLANATION_OFFSET + (shiftedOffsetY / 2));
        explanationView.messageCopy.frame = explanationTextFrame;
    }

}

// Helpers
- (MAVEABPerson *)personAtIndexPath:(NSIndexPath *)indexPath {
    // TODO unit test
    NSString *sectionTitle = [tableSections objectAtIndex:indexPath.section];
    return [[tableData objectForKey:sectionTitle] objectAtIndex:indexPath.row];
}

@end
