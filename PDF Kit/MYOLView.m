//
//  MYOLView.m
//  Document-based2
//
//  Created by 河野 さおり on 2016/03/21.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "MYOLView.h"

#define APPD (AppDelegate *)[NSApp delegate]

@implementation MYOLView{
    DocWinC *winC;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)keyDown:(NSEvent *)theEvent{
    winC = self.window.windowController;
    switch ([theEvent keyCode]) {
        case 125: //下矢印
            [self selectNextRow:theEvent];
            break;
        case 126: //上矢印
            if (self.selectedRow != 0) {
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
        case 123: //左矢印
            //展開している場合は閉じる
            [self collapseItem:[self itemAtRow:self.selectedRow]];
            break;
        case 124: //右矢印
            //閉じている場合は展開する
            [self expandItem:[self itemAtRow:self.selectedRow]];
            break;
        case 36: //リターンキー(book)
            [self acceptInput];
            break;
        case 76: //エンターキー
            [self acceptInput];
            break;
        case 52: //リターンキー
            [self acceptInput];
            break;
        case 49: //スペースキー
            [self selectNextRow:theEvent];
            break;
        default:
            
            break;
    }
}

- (void)selectNextRow:(NSEvent *)theEvent{
    if (self.selectedRow != self.numberOfRows-1) {
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
}

//行を編集状態にする
- (void)acceptInput{
    [self editColumn:0 row:self.selectedRow withEvent:nil select:YES];
}

@end