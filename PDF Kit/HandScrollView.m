//
//  HandScrollView.m
//  Document-based2
//
//  Created by 河野 さおり on 2016/03/23.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "HandScrollView.h"

#define WINC (MyWinC *)self.window.windowController

@implementation HandScrollView{
    NSPoint movePoint;
    BOOL isDragging;
}

- (void)awakeFromNib{
    isDragging = NO;
}

- (void)resetCursorRects{
    if (isDragging) {
        [self addCursorRect:self.bounds cursor:[NSCursor closedHandCursor]];
    } else {
        [self addCursorRect:self.bounds cursor:[NSCursor openHandCursor]];
    }
}

- (void)mouseDown:(NSEvent *)theEvent{
    [[NSCursor closedHandCursor] set];
    movePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
}

- (void)mouseDragged:(NSEvent *)theEvent{
    isDragging = YES;
    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    float dx = movePoint.x - point.x;
    float dy = movePoint.y - point.y;
    NSView *documentView = (WINC)._pdfView.documentView;
    NSRect visibleRect = documentView.visibleRect;
    [documentView scrollPoint:NSMakePoint(visibleRect.origin.x+dx, visibleRect.origin.y+dy)];
    movePoint = point;
}

- (void)mouseUp:(NSEvent *)theEvent{
    isDragging = NO;
    [[NSCursor openHandCursor]set];
}

@end