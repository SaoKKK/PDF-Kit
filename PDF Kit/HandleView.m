//
//  HandleView.m
//  Document-based2
//
//  Created by 河野 さおり on 2016/03/17.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "HandleView.h"

#define APPD (AppDelegate *)[NSApp delegate]
#define WINC (MyWindowController *)self.window.windowController

@implementation HandleView{
    NSPoint startPoint;
    CAShapeLayer *shapeLayer;
}

- (void)drawRect:(NSRect)dirtyRect {
    [self setLayer:[CALayer new]];
    [self setWantsLayer:YES];
    [self.layer setBackgroundColor:CGColorCreateGenericRGB(0.5, 0.0, 0.0, 0.2)];
}

- (void)mouseDown:(NSEvent *)theEvent{
    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    //マウスダウンの座標がページ領域内であればその座標をstartPointに格納
    if ([(WINC)._pdfView pageForPoint:point nearest:NO]) {
        startPoint = point;
    } else {
        //下にある最も近いページの領域をNSView座標系で取得
        PDFPage *page = [(WINC)._pdfView pageForPoint:point nearest:YES];
        NSRect pageRect = [(WINC)._pdfView convertRect:[page boundsForBox:kPDFDisplayBoxArtBox] fromPage:page];
        if (point.x < pageRect.origin.x) {
            //マウスダウンのx座標がページの左側の場合
            startPoint.x = pageRect.origin.x;
        } else if (point.x > pageRect.origin.x + pageRect.size.width){
            //マウスダウンのx座標がページの右側の場合
            startPoint.x = pageRect.origin.x + pageRect.size.width;
        } else {
            //マウスダウンのx座標がページの領域内の場合
            startPoint.x = point.x;
        }
        if (point.y < pageRect.origin.y){
            //マウスダウンのy座標がページの下側の場合
            startPoint.y = pageRect.origin.y;
        } else if (point.y > pageRect.origin.y + pageRect.size.height){
            //マウスダウンのy座標がページの上側の場合
            startPoint.y = pageRect.origin.y + pageRect.size.height;
        } else {
            //マウスダウンのy座標がページの領域内の場合
            startPoint.y = point.y;
        }
    }
    //shape layerを作成
    shapeLayer = [CAShapeLayer layer];
    shapeLayer.lineWidth = 1.0;
    shapeLayer.strokeColor = [[NSColor blackColor] CGColor];
    shapeLayer.fillColor = [[NSColor clearColor] CGColor];
    shapeLayer.lineDashPattern = @[@6, @4];
    [self.layer addSublayer:shapeLayer];
    //アニメーションを作成
    CABasicAnimation *dashAnimation;
    dashAnimation = [CABasicAnimation animationWithKeyPath:@"lineDashPhase"];
    [dashAnimation setFromValue:@0.0f];
    [dashAnimation setToValue:@15.0f];
    [dashAnimation setDuration:0.75f];
    [dashAnimation setRepeatCount:HUGE_VALF];
    [shapeLayer addAnimation:dashAnimation forKey:@"linePhase"];
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent{
    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    PDFPage *page = [(WINC)._pdfView pageForPoint:point nearest:NO];
    NSLog(@"%@",page);
    //shape layerのパスを作成
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, startPoint.x, startPoint.y);
    CGPathAddLineToPoint(path, NULL, startPoint.x, point.y);
    CGPathAddLineToPoint(path, NULL, point.x, point.y);
    CGPathAddLineToPoint(path, NULL, point.x, startPoint.y);
    CGPathCloseSubpath(path);
    shapeLayer.path = path;
    
    CGPathRelease(path);
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent{
    NSPoint endPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    if (endPoint.x == startPoint.x && endPoint.y == startPoint.y){
        //シングルクリックの場合
        if ([NSEvent modifierFlags] & NSAlternateKeyMask){
            [WINC zoomOut:nil];
        } else {
            if ((WINC)._pdfView.scaleFactor <= 5.0) {
                [WINC zoomIn:nil];
            }
        }
    } else {
        //拡大エリアが作成された場合
        NSRect expArea = NSMakeRect(MIN(startPoint.x,endPoint.x), MIN(startPoint.y,endPoint.y), fabs(startPoint.x-endPoint.x), fabs(startPoint.y-endPoint.y));
        //拡大率を決定(縦横で倍率を出して小さい方を採用)
        float enlargementFactorFromWidth = (WINC)._pdfView.bounds.size.width/expArea.size.width;
        float enlargementFactorFromHeight = (WINC)._pdfView.bounds.size.height/expArea.size.height;
        float enlargementFactor = MIN(enlargementFactorFromWidth,enlargementFactorFromHeight);
        if (enlargementFactor > 5.0) {
            enlargementFactor = 5.0;
        }
    }
    [shapeLayer removeFromSuperlayer];
    shapeLayer = nil;
}

@end
