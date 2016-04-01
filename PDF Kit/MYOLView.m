//
//  MyOLView.m
//  Document-based2
//
//  Created by 河野 さおり on 2016/03/21.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "MyOLView.h"

#define APPD (AppDelegate *)[NSApp delegate]

@implementation MyOLView

- (void)keyDown:(NSEvent *)theEvent{
    MyWinC *winC = self.window.windowController;
    switch ([theEvent keyCode]) {
        case 125: //下矢印
            if (self.selectedRowIndexes.lastIndex != self.numberOfRows-1) {
                //現在の選択が最終行でなければ
                if ([theEvent modifierFlags]==NSShiftKeyMask||[theEvent modifierFlags]==10617090){
                    //下方向に選択を広げる
                    NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc]initWithIndexSet:self.selectedRowIndexes];
                    [indexes addIndex:self.selectedRowIndexes.lastIndex+1];
                    [self selectRowIndexes:indexes byExtendingSelection:YES];
                    
                } else {
                    //下に移動
                    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:self.selectedRow+1] byExtendingSelection:NO];
                    [winC outlineViewRowClicked:nil];
                }
            }
            break;
        case 126: //上矢印
            if (self.selectedRowIndexes.firstIndex != 0) {
                //現在の選択が最初の行でなければ
                if ([theEvent modifierFlags]==NSShiftKeyMask||[theEvent modifierFlags]==10617090) {
                    //上方向に選択を広げる
                    NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc]initWithIndexSet:self.selectedRowIndexes];
                    [indexes addIndex:self.selectedRowIndexes.firstIndex-1];
                    [self selectRowIndexes:indexes byExtendingSelection:YES];
                } else {
                    //上へ移動
                    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:self.selectedRowIndexes.firstIndex-1] byExtendingSelection:NO];
                    [winC outlineViewRowClicked:nil];
                }
            }
            break;
        default:
            [super keyDown:theEvent];
            break;
    }
}

@end
