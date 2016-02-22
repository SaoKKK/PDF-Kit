//
//  ErrLstController.m
//  Sao's PDF Kit
//
//  Created by 河野 さおり on 2016/02/13.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "ErrLstController.h"
#import "AppDelegate.h"

@implementation ErrLstController

# pragma mark - NSTableView data source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    AppDelegate *appD = [[NSApplication sharedApplication]delegate];
    return appD.errLst.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    AppDelegate *appD = [[NSApplication sharedApplication]delegate];
    NSString *identifier = [tableColumn identifier];
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:identifier owner:self];
    cellView.textField.stringValue = [appD.errLst objectAtIndex:row];
    return cellView;
}

@end
