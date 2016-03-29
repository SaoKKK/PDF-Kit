//
//  ZoomView.m
//  Document-based2
//
//  Created by 河野 さおり on 2016/03/23.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "ZoomView.h"

#define APPD (AppDelegate *)[NSApp delegate]
#define WINC (MyWindowController *)self.window.windowController

@implementation ZoomView{
    NSPoint startPoint;
    CAShapeLayer *shapeLayer;
    PDFPage *page;
    NSRect pageRect;
}

- (void)drawRect:(NSRect)dirtyRect {
    [self setLayer:[CALayer new]];
    [self setWantsLayer:YES];
}

- (void)mouseDown:(NSEvent *)theEvent{
    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    //下にある最も近いページの領域をNSView座標系で取得
    page = [(WINC)._pdfView pageForPoint:point nearest:YES];
    pageRect = [(WINC)._pdfView convertRect:[page boundsForBox:kPDFDisplayBoxArtBox] fromPage:page];
    if ([(WINC)._pdfView pageForPoint:point nearest:NO]) {
        //マウスダウンの座標がページ領域内であればその座標をstartPointに格納
        startPoint = point;
    } else {
        startPoint = [self areaPointFromOutPoint:point];
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
    NSPoint dragPoint;
    if (NSPointInRect(point, pageRect)) {
        //ドラッグ座標がページ領域内であればその座標をstartPointに格納
        dragPoint = point;
    } else {
        //ドラッグ座標がページ領域外だった場合
        dragPoint = [self areaPointFromOutPoint:point];
    }
    //shape layerのパスを作成
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, startPoint.x, startPoint.y);
    CGPathAddLineToPoint(path, NULL, startPoint.x, dragPoint.y);
    CGPathAddLineToPoint(path, NULL, dragPoint.x, dragPoint.y);
    CGPathAddLineToPoint(path, NULL, dragPoint.x, startPoint.y);
    CGPathCloseSubpath(path);
    shapeLayer.path = path;
    
    CGPathRelease(path);
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent{
    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    if (point.x == startPoint.x && point.y == startPoint.y){
        //シングルクリックの場合
        if ([NSEvent modifierFlags] & NSAlternateKeyMask){
            [WINC zoomOut:nil];
        } else {
            if ((WINC)._pdfView.scaleFactor <= 5.0) {
                [WINC zoomIn:nil];
            }
        }
    } else {
        NSPoint endPoint;
        if (NSPointInRect(point, pageRect)) {
            //マウスアップの座標がページ領域内であればその座標をendPointに格納
            endPoint = point;
        } else {
            endPoint = [self areaPointFromOutPoint:point];
        }
        //拡大エリアが作成された場合
        NSRect expArea = NSMakeRect(MIN(startPoint.x,endPoint.x), MIN(startPoint.y,endPoint.y), fabs(startPoint.x-endPoint.x), fabs(startPoint.y-endPoint.y));
        if (expArea.size.width != 0 && expArea.size.height != 0) {
            //拡大率を決定(縦横で倍率を出して小さい方を採用)
            float enlargementFactorFromWidth = (WINC)._pdfView.bounds.size.width/expArea.size.width;
            float enlargementFactorFromHeight = (WINC)._pdfView.bounds.size.height/expArea.size.height;
            float enlargementFactor = (WINC)._pdfView.scaleFactor * MIN(enlargementFactorFromWidth,enlargementFactorFromHeight);
            if (enlargementFactor > 5.0) {
                enlargementFactor = 5.0;
            }
            //拡大エリアをPDF座標系に変換
            NSRect expPDFArea = [(WINC)._pdfView convertRect:expArea toPage:page];
            //拡大実行
            [(WINC)._pdfView setScaleFactor:enlargementFactor];
            //拡大後の移動エリアを作成
            NSRect viewArea = [(WINC)._pdfView convertRect:(WINC)._pdfView.bounds toPage:page];
            if (expPDFArea.size.width < viewArea.size.width) {
                expPDFArea.origin.x = expPDFArea.origin.x - (viewArea.size.width - expPDFArea.size.width)/2;
            }
            if (expPDFArea.size.height < viewArea.size.height) {
                expPDFArea.origin.y = expPDFArea.origin.y + (viewArea.size.height - expPDFArea.size.height)/2;
            }
            //拡大エリアに移動
            [(WINC)._pdfView goToRect:expPDFArea onPage:page];
        }
    }
    [shapeLayer removeFromSuperlayer];
    shapeLayer = nil;
}

//マウス座標がページ領域外だった場合の拡大領域作成のための座標を返す
- (NSPoint)areaPointFromOutPoint:(NSPoint)point{
    NSPoint areaPoint;
    if (point.x < pageRect.origin.x) {
        //x座標がページの左側の場合
        areaPoint.x = pageRect.origin.x;
    } else if (point.x > pageRect.origin.x + pageRect.size.width){
        //x座標がページの右側の場合
        areaPoint.x = pageRect.origin.x + pageRect.size.width;
    } else {
        //x座標がページの領域内の場合
        areaPoint.x = point.x;
    }
    if (point.y < pageRect.origin.y){
        //y座標がページの下側の場合
        areaPoint.y = pageRect.origin.y;
    } else if (point.y > pageRect.origin.y + pageRect.size.height){
        //y座標がページの上側の場合
        areaPoint.y = pageRect.origin.y + pageRect.size.height;
    } else {
        //y座標がページの領域内の場合
        areaPoint.y = point.y;
    }
    return areaPoint;
}

@end
