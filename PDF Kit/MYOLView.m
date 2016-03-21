//
//  MYOLView.m
//  Document-based2
//
//  Created by 河野 さおり on 2016/03/21.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "MYOLView.h"

#define APPD (AppDelegate *)[NSApp delegate]

@implementation MYOLView
@synthesize winC;

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)keyDown:(NSEvent *)theEvent{
    NSLog(@"KeyDown pressed[%d]", [theEvent keyCode]);
    winC = self.window.windowController;
    switch ([theEvent keyCode]) {
        case 125: //下矢印
            [self selectNextRow];
            break;
        case 126: //上矢印
            break;
        case 123: //左矢印
            break;
        case 124: //右矢印
            break;
        case 36: //リターンキー(book)
            break;
        case 76: //エンターキー
            break;
        case 52: //リターンキー
            break;
        case 49: //スペースキー
           [self selectNextRow];
           break;
        default:
            break;
    }
}

- (void)selectNextRow{
    if (self.selectedRow != self.numberOfRows-1) {
        //最終行でなければ下に移動
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:self.selectedRow+1] byExtendingSelection:NO];
        [winC outlineViewRowClicked:nil];
    }
}

@end
