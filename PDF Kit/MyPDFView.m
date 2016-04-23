//
//  MyPDFView.m
//  Sao's PDF Kit
//
//  Created by 河野 さおり on 2016/02/21.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "MyPDFView.h"

#define APPD (AppDelegate *)[NSApp delegate]
#define WINC (MyWinC *)self.window.windowController

static CGFloat HandleWidth = 6.0f;

enum UNDEROBJ_TYPE{
    //選択範囲の外
    OUT_AREA,
    //選択範囲
    INSIDE_AREA,
    //選択範囲のハンドル
    HANDLE_TOP_LEFT, HANDLE_TOP_MIDDLE, HANDLE_TOP_RIGHT,
    HANDLE_MIDDLE_LEFT, HANDLE_MIDDLE_RIGHT,
    HANDLE_BOTTOM_LEFT, HANDLE_BOTTOM_MIDDLE, HANDLE_BOTTOM_RIGHT
};

@implementation MyPDFView{
    NSPoint startPoint;
    NSPoint endPoint;
    NSTrackingArea *track;
    NSRect pgRect;
    NSRect vPgRect;
    int mouseLocation;
}
@synthesize handScrollView,zoomView,selRect,targetPg;

#pragma mark - initialize

- (void)awakeFromNib{
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidResizeNotification object:self.window queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        //ウインドウのリサイズ時→サブビューをリサイズする
        [handScrollView setFrame:self.bounds];
        [zoomView setFrame:self.bounds];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:PDFViewSelectionChangedNotification object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        //選択が変更された時
        if (self.currentSelection) {
            (APPD).isSelection = YES;
        } else {
            (APPD).isSelection = NO;
        }
    }];
    //documentViewのvisibleRectに変更があったら再描画
    NSClipView *cView = self.enclosingScrollView.contentView;
    [cView setPostsBoundsChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSViewBoundsDidChangeNotification object:cView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        [self setNeedsDisplay:YES];
    }];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self createTrackingArea];
    }
    return self;
}

#pragma mark - set trackingArea

- (void)updateTrackingAreas {
    [self removeTrackingArea:track];
    track = nil;
    [self createTrackingArea];
}

//トラッキング・エリアを設定
-(void)createTrackingArea{
    NSTrackingAreaOptions trackOption = NSTrackingCursorUpdate;
    trackOption |= NSTrackingMouseEnteredAndExited;
    trackOption |= NSTrackingEnabledDuringMouseDrag;
    trackOption |= NSTrackingActiveInActiveApp;
    track = [[NSTrackingArea alloc] initWithRect:self.bounds options:trackOption owner:self userInfo:nil];
    [self addTrackingArea:track];
}

#pragma mark - sub view control

- (void)loadHandScrollView{
    [self removeSubView];
    handScrollView = [[HandScrollView alloc]initWithFrame:self.bounds];
    [self addSubview:handScrollView];
}

- (void)loadZoomView{
    [self removeSubView];
    zoomView = [[ZoomView alloc]initWithFrame:self.bounds];
    [self addSubview:zoomView];
}

- (void)removeSubView{
    [handScrollView removeFromSuperview];
    [zoomView removeFromSuperview];
}

#pragma mark - cursor control

//ページ領域によるカーソル変更
- (void)setCursorForAreaOfInterest:(PDFAreaOfInterest)area{
    [self.window makeFirstResponder:self];
    if ([(WINC).segTool selectedSegment] == 0){
        //テキスト選択ツール選択時は通常カーソル
        [super setCursorForAreaOfInterest:area];
    }
}

//ビュー領域によるカーソル変更
- (void)resetCursorRects{
    switch ([(WINC).segTool selectedSegment]){
        case 1:{
            [self addCursorRect:self.bounds cursor:[NSCursor crosshairCursor]];
            [self addCursorRect:[self convertRect:selRect fromPage:targetPg] cursor:[NSCursor arrowCursor]];
            [self addCursorRect:[self makeHandleRect:NSMakePoint(NSMinX(selRect), NSMinY(selRect))] cursor:[[NSCursor alloc]initWithImage:[NSImage imageNamed:@"resizeb"] hotSpot:NSMakePoint(7, 7)]];
            [self addCursorRect:[self makeHandleRect:NSMakePoint(NSMidX(selRect), NSMinY(selRect))] cursor:[NSCursor resizeUpDownCursor]];
            [self addCursorRect:[self makeHandleRect:NSMakePoint(NSMaxX(selRect), NSMinY(selRect))] cursor:[[NSCursor alloc]initWithImage:[NSImage imageNamed:@"resizef"] hotSpot:NSMakePoint(7, 7)]];
            [self addCursorRect:[self makeHandleRect:NSMakePoint(NSMinX(selRect), NSMidY(selRect))] cursor:[NSCursor resizeLeftRightCursor]];
            [self addCursorRect:[self makeHandleRect:NSMakePoint(NSMaxX(selRect), NSMidY(selRect))] cursor:[NSCursor resizeLeftRightCursor]];
            [self addCursorRect:[self makeHandleRect:NSMakePoint(NSMinX(selRect), NSMaxY(selRect))] cursor:[[NSCursor alloc]initWithImage:[NSImage imageNamed:@"resizef"] hotSpot:NSMakePoint(7, 7)]];
            [self addCursorRect:[self makeHandleRect:NSMakePoint(NSMidX(selRect), NSMaxY(selRect))] cursor:[NSCursor resizeUpDownCursor]];
            [self addCursorRect:[self makeHandleRect:NSMakePoint(NSMaxX(selRect), NSMaxY(selRect))] cursor:[[NSCursor alloc]initWithImage:[NSImage imageNamed:@"resizeb"] hotSpot:NSMakePoint(7, 7)]];
        }
            break;
        case 3:{ //ズームツール選択時
            [self addCursorRect:self.bounds cursor:[self updateZoomCursor]];
        }
            break;
    }
}

//選択エリアのハンドル領域をビュー座標系に変換して返す
- (NSRect)makeHandleRect:(NSPoint)point{
    float sf = self.scaleFactor;
    NSRect handleRect = NSMakeRect(point.x-(HandleWidth/sf)/2.0, point.y-(HandleWidth/sf)/2.0, HandleWidth/sf, HandleWidth/sf);
    return [self convertRect:handleRect fromPage:targetPg];
}

//ズームカーソルになっている時にoptionキーが押されたら縮小カーソルに変更
- (void)flagsChanged:(NSEvent *)theEvent{
    if ((WINC).segTool.selectedSegment == 3){
        [[self updateZoomCursor] set];
    } else {
        [super flagsChanged:theEvent];
    }
}

//ズームカーソル更新
- (NSCursor*)updateZoomCursor{
    [self discardCursorRects];
    NSCursor *cursor;
    if ([NSEvent modifierFlags] & NSAlternateKeyMask) {
        if (self.canZoomOut) {
            cursor = [[NSCursor alloc]initWithImage:[NSImage imageNamed:@"cZoomOut"] hotSpot:NSMakePoint(7, 7)];
        } else {
            cursor = [[NSCursor alloc]initWithImage:[NSImage imageNamed:@"cZoom"] hotSpot:NSMakePoint(7, 7)];
        }
    } else {
        if (self.scaleFactor < 5) {
            cursor = [[NSCursor alloc]initWithImage:[NSImage imageNamed:@"cZoomIn"] hotSpot:NSMakePoint(7, 7)];
        } else {
            cursor = [[NSCursor alloc]initWithImage:[NSImage imageNamed:@"cZoom"] hotSpot:NSMakePoint(7, 7)];
        }
    }
    return cursor;
}

#pragma mark - menu action

- (IBAction)selectAll:(id)sender{
    if ((WINC).segTool.selectedSegment == 1){
        targetPg = self.currentPage;
        selRect = [self.currentPage boundsForBox:kPDFDisplayBoxArtBox];
        [self setNeedsDisplay:YES];
        (APPD).isSelection = YES;
    } else {
       [super selectAll:nil];
    }
}

- (void)copy:(id)sender{
    if (!self.document.allowsCopying){
        (APPD).parentWin = self.window;
        (APPD).pwTxtPass.stringValue = @"";
        (APPD).pwMsgTxt.stringValue = NSLocalizedString(@"UnlockCopyMsg", @"");
        (APPD).pwInfoTxt.stringValue = NSLocalizedString(@"UnlockCopyInfo", @"");
        [self.window beginSheet:(APPD).passWin completionHandler:^(NSInteger returnCode){
            if (returnCode == NSModalResponseOK) {
                [self performCopy];
            }
        }];
    } else {
        [self performCopy];
    }
}

- (void)performCopy{
    if ((WINC).segTool.selectedSegment == 1) {
        PDFSelection *sel = [targetPg selectionForRect:selRect];
        [self setCurrentSelection:sel];
        [super copy:nil];
        [self clearSelection];
    } else {
        [super copy:nil];
    }
}

#pragma mark - draw page

- (void)drawPage:(PDFPage *)page{
    [super drawPage: page];
    
    //選択範囲を描画
    if ((WINC).segTool.selectedSegment != 0 && page == targetPg) {
        if (selRect.size.width != 0 || selRect.size.height != 0) {
            //アンチエイリアスを切る
            NSGraphicsContext *gc = [NSGraphicsContext currentContext];
            [gc saveGraphicsState];
            [gc setShouldAntialias:NO];
            
            float sf = self.scaleFactor;
            NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(selRect.origin.x+1.5/sf, selRect.origin.y+1.5/sf, selRect.size.width-3/sf, selRect.size.height-3/sf)];
            [[NSColor colorWithDeviceRed: 0.35 green: 0.55 blue: 0.75 alpha: 0.2] set];
            [path fill];
            [path setLineWidth:1.5/sf];
            [[NSColor whiteColor] set];
            [path stroke];
            path = [NSBezierPath bezierPathWithRect: selRect];
            [path setLineWidth:1.0/sf];
            [[NSColor colorWithDeviceRed: 0.47 green: 0.55 blue: 0.78 alpha: 1.0] set];
            [path stroke];
            
            [gc restoreGraphicsState];
            [self drawHandle];
        }
    }
}

- (void)drawHandle{
    [self drawHandleAtPoint:NSMakePoint(NSMinX(selRect), NSMinY(selRect))];
    [self drawHandleAtPoint:NSMakePoint(NSMidX(selRect), NSMinY(selRect))];
    [self drawHandleAtPoint:NSMakePoint(NSMaxX(selRect), NSMinY(selRect))];
    [self drawHandleAtPoint:NSMakePoint(NSMinX(selRect), NSMidY(selRect))];
    [self drawHandleAtPoint:NSMakePoint(NSMaxX(selRect), NSMidY(selRect))];
    [self drawHandleAtPoint:NSMakePoint(NSMinX(selRect), NSMaxY(selRect))];
    [self drawHandleAtPoint:NSMakePoint(NSMidX(selRect), NSMaxY(selRect))];
    [self drawHandleAtPoint:NSMakePoint(NSMaxX(selRect), NSMaxY(selRect))];
}

- (void)drawHandleAtPoint:(NSPoint)point{
    float sf = self.scaleFactor;
    NSRect handleRect = NSMakeRect(point.x-(HandleWidth/sf)/2.0, point.y-(HandleWidth/sf)/2.0, HandleWidth/sf, HandleWidth/sf);
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path appendBezierPath:[NSBezierPath bezierPathWithOvalInRect:handleRect]];
    [path setLineWidth:3/sf];
    [[NSColor colorWithDeviceRed: 0.47 green: 0.55 blue: 0.78 alpha: 1.0] set];
    [path stroke];
    [[NSColor colorWithCalibratedRed:0.66 green:0.66 blue:0.9 alpha:1.0] set];
    [path fill];
}

#pragma mark - mouse event

- (void)mouseDown:(NSEvent *)theEvent{
    if ((WINC).segTool.selectedSegment == 1) {
        NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        //カーソル座標に最も近いページの領域をNSView座標系で取得
        PDFPage *oldPg = targetPg;
        targetPg = [self pageForPoint:point nearest:YES];
        //違うページにマウスダウンされた場合はselRectをクリア
        if (targetPg != oldPg) {
            selRect = NSZeroRect;
            [self setNeedsDisplay:YES];
        }
        pgRect = [targetPg boundsForBox:kPDFDisplayBoxArtBox];
        vPgRect = [self convertRect:pgRect fromPage:targetPg];
        if ([self pageForPoint:point nearest:NO]) {
            //マウスダウンの座標がページ領域内であればその座標をページ座標系に変換してstartPointに格納
            startPoint = [self convertPoint:point toPage:targetPg];
        } else {
            //マウスダウンの座標がページ領域外だった場合
            startPoint = [self convertPoint:[self areaPointFromOutPoint:point] toPage:targetPg];
        }
        
        //カーソル座標にあるオブジェクトを調べる
        mouseLocation = [self whatsUnderPoint:point];
        switch (mouseLocation) {
            case OUT_AREA: //新しく選択範囲を作成
                selRect = NSMakeRect(startPoint.x, startPoint.y, 0, 0);
                break;
            case HANDLE_TOP_LEFT:
                startPoint.x = selRect.origin.x + selRect.size.width;
                startPoint.y = selRect.origin.y;
                break;
            case HANDLE_TOP_MIDDLE:
                startPoint.y = selRect.origin.y;
                break;
            case HANDLE_TOP_RIGHT:
                startPoint.x = selRect.origin.x;
                startPoint.y = selRect.origin.y;
                break;
            case HANDLE_MIDDLE_LEFT:
                startPoint.x = selRect.origin.x + selRect.size.width;
                break;
            case HANDLE_MIDDLE_RIGHT:
                startPoint.x = selRect.origin.x;
                break;
            case HANDLE_BOTTOM_LEFT:
                startPoint.x = selRect.origin.x + selRect.size.width;
                startPoint.y = selRect.origin.y + selRect.size.height;
                break;
            case HANDLE_BOTTOM_MIDDLE:
                startPoint.y = selRect.origin.y + selRect.size.height;
                break;
            case HANDLE_BOTTOM_RIGHT:
                startPoint.x = selRect.origin.x;
                startPoint.y = selRect.origin.y + selRect.size.height;
                break;
        }
    } else {
        [super mouseDown:theEvent];
    }
}

- (void)mouseDragged:(NSEvent *)theEvent{
    if ((WINC).segTool.selectedSegment == 1) {
        [self.documentView autoscroll:theEvent];
        NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        if (! NSPointInRect(point, self.bounds)) {
            vPgRect = [self convertRect:[targetPg boundsForBox:kPDFDisplayBoxArtBox] fromPage:targetPg];
        }
        if (NSPointInRect(point, vPgRect)) {
            //ドラッグ座標がページ領域内であればその座標をページ座標系に変換して使用
            endPoint = [self convertPoint:point toPage:targetPg];
        } else {
            //ドラッグ座標がページ領域外だった場合
            endPoint = [self convertPoint:[self areaPointFromOutPoint:point] toPage:targetPg];
        }
        if (mouseLocation == INSIDE_AREA) {
            //選択エリアを移動
            float dx = endPoint.x - startPoint.x;
            float dy = endPoint.y - startPoint.y;
            if (endPoint.x >= startPoint.x - selRect.origin.x && endPoint.x <= pgRect.size.width - ((selRect.size.width + selRect.origin.x) - startPoint.x)){
                selRect.origin.x = selRect.origin.x + dx;
            }
            if (endPoint.y >= startPoint.y - selRect.origin.y && endPoint.y <= pgRect.size.height - ((selRect.size.height + selRect.origin.y) - startPoint.y)){
                selRect.origin.y = selRect.origin.y + dy;
            }
            startPoint = endPoint;
        } else if (mouseLocation == OUT_AREA) {
            [self expandSelRectX];
            [self expandSelRectY];
        } else if (mouseLocation == HANDLE_TOP_LEFT || mouseLocation == HANDLE_BOTTOM_RIGHT) {
            [[[NSCursor alloc]initWithImage:[NSImage imageNamed:@"resizef"] hotSpot:NSMakePoint(7, 7)]set];
            [self expandSelRectX];
            [self expandSelRectY];
        } else if (mouseLocation == HANDLE_TOP_RIGHT || mouseLocation == HANDLE_BOTTOM_LEFT) {
            [[[NSCursor alloc]initWithImage:[NSImage imageNamed:@"resizeb"] hotSpot:NSMakePoint(7, 7)]set];
            [self expandSelRectX];
            [self expandSelRectY];
        } else if (mouseLocation == HANDLE_TOP_MIDDLE || mouseLocation == HANDLE_BOTTOM_MIDDLE) {
            [[NSCursor resizeUpDownCursor]set];
            [self expandSelRectY];
        } else {
            [[NSCursor resizeLeftRightCursor]set];
            [self expandSelRectX];
        }
        [self setNeedsDisplay:YES];
    } else {
        [super mouseDragged:theEvent];
    }
}

- (void)expandSelRectX{
    if (endPoint.x < startPoint.x) {
        selRect.origin.x = endPoint.x;
        selRect.size.width = startPoint.x - endPoint.x;
    } else {
        selRect.size.width = endPoint.x - startPoint.x;
    }
}

- (void)expandSelRectY{
    if (endPoint.y < startPoint.y) {
        selRect.origin.y = endPoint.y;
        selRect.size.height = startPoint.y - endPoint.y;
    } else {
        selRect.size.height = endPoint.y - startPoint.y;
    }
}

- (void)mouseUp:(NSEvent *)theEvent{
    if ((WINC).segTool.selectedSegment == 1) {
        NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        NSPoint vStartP = [self convertPoint:startPoint fromPage:targetPg];
        if (mouseLocation == OUT_AREA && point.x ==  vStartP.x && point.y == vStartP.y) {
            //シングルクリックの場合は選択解除
            [self deselectArea];
        } else {
            //選択エリアが作成されている場合
            (APPD).isSelection = YES;
        }
        [self resetCursorRects];
    } else {
        [super mouseUp:theEvent];
    }
}

//マウス座標がページ領域外だった場合の選択領域作成のための座標を返す
- (NSPoint)areaPointFromOutPoint:(NSPoint)point{
    NSPoint areaPoint;
    if (point.x < vPgRect.origin.x) {
        //x座標がページの左側の場合
        areaPoint.x = vPgRect.origin.x;
    } else if (point.x > vPgRect.origin.x + vPgRect.size.width){
        //x座標がページの右側の場合
        areaPoint.x = vPgRect.origin.x + vPgRect.size.width;
    } else {
        //x座標がページの領域内の場合
        areaPoint.x = point.x;
    }
    if (point.y < vPgRect.origin.y){
        //y座標がページの下側の場合
        areaPoint.y = vPgRect.origin.y;
    } else if (point.y > vPgRect.origin.y + vPgRect.size.height){
        //y座標がページの上側の場合
        areaPoint.y = vPgRect.origin.y + vPgRect.size.height;
    } else {
        //y座標がページの領域内の場合
        areaPoint.y = point.y;
    }
    return areaPoint;
}

- (int)whatsUnderPoint:(NSPoint)point{
    int underObj_type = OUT_AREA;
    if (NSPointInRect(point, [self makeHandleRect:NSMakePoint(NSMinX(selRect),NSMaxY(selRect))])) {
        underObj_type = HANDLE_TOP_LEFT;
    } else if (NSPointInRect(point, [self makeHandleRect:NSMakePoint(NSMidX(selRect),NSMaxY(selRect))])) {
        underObj_type = HANDLE_TOP_MIDDLE;
    } else if (NSPointInRect(point, [self makeHandleRect:NSMakePoint(NSMaxX(selRect),NSMaxY(selRect))])) {
        underObj_type = HANDLE_TOP_RIGHT;
    } else if (NSPointInRect(point, [self makeHandleRect:NSMakePoint(NSMinX(selRect),NSMidY(selRect))])) {
        underObj_type = HANDLE_MIDDLE_LEFT;
    } else if (NSPointInRect(point, [self makeHandleRect:NSMakePoint(NSMaxX(selRect),NSMidY(selRect))])) {
        underObj_type = HANDLE_MIDDLE_RIGHT;
    } else if (NSPointInRect(point, [self makeHandleRect:NSMakePoint(NSMinX(selRect),NSMinY(selRect))])) {
        underObj_type = HANDLE_BOTTOM_LEFT;
    } else if (NSPointInRect(point, [self makeHandleRect:NSMakePoint(NSMidX(selRect),NSMinY(selRect))])) {
        underObj_type = HANDLE_BOTTOM_MIDDLE;
    } else if (NSPointInRect(point, [self makeHandleRect:NSMakePoint(NSMaxX(selRect),NSMinY(selRect))])) {
        underObj_type = HANDLE_BOTTOM_RIGHT;
    } else if (NSPointInRect(point, [self convertRect:selRect fromPage:targetPg])){
        underObj_type = INSIDE_AREA;
    }
    return underObj_type;
}

//選択領域の解除
- (void)deselectArea{
    selRect = NSZeroRect;
    [self setNeedsDisplay:YES];
    (APPD).isSelection = NO;
}

@end