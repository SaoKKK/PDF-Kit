//
//  MyWindowController.m
//  Sao's PDF Kit
//
//  Created by 河野 さおり on 2016/02/19.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "MyWindowController.h"
#import "Document.h"
#import "MyPDFView.h"
#import "AppDelegate.h"

#define kMinTocAreaSplit	200.0f
#define APPD (AppDelegate *)[NSApp delegate]

@interface MyWindowController ()

@end

@implementation MyWindowController

#pragma mark - Window Controller Method

- (void)windowDidLoad {
    [super windowDidLoad];
    //スクリーンモード保持用変数を初期化
    bFullscreen = NO;
    //ファイルから読み込まれたPDFドキュメントをビューに表示
    docURL = [[self document] fileURL];
    PDFDocument *doc = [[PDFDocument alloc]initWithURL:docURL];
    [_pdfView setDocument:doc];
    //ノーティフィケーションを設定
    [self setupNotification];
    //デリゲートを設定
    [[_pdfView document] setDelegate: self];
    //オート・スケールをオフにする
    [_pdfView setAutoScales:NO];
    //ページ表示テキストフィールドを更新
    NSUInteger totalPg = _pdfView.document.pageCount;
    [txtTotalPg setStringValue:[NSString stringWithFormat:@"%li",totalPg]];
    [txtPageFormatter setMaximum:[NSNumber numberWithInteger:totalPg]];
    //ページ表示テキストフィールドの値を変更
    [self updateTxtPg];
    //目次エリア幅保持用変数に初期値を保存
    oldTocWidth = 165.0F;
    //サムネイルビューの設定
    [thumbView setAllowsMultipleSelection:YES];
}

#pragma mark - document save/open support

- (NSData *)pdfViewDocumentData{
    return [[_pdfView document]dataRepresentation];
}

- (void)revertDocumentToSaved{
    PDFDocument *doc = [[PDFDocument alloc]initWithURL:docURL];
    [_pdfView setDocument:doc];
}

#pragma mark - setup notification

- (void)setupNotification{
    //ドキュメント保存開始
    [[NSNotificationCenter defaultCenter] addObserverForName:@"PDFDidBeginDocumentWrite" object:[_pdfView document] queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        double pgCnt = [[_pdfView document] pageCount];
        [savingProgBar setMaxValue:pgCnt];
        [savingProgBar setDoubleValue: 0.0];
        //プログレス・パネルをシート表示
        [self.window beginSheet:progressWin completionHandler:^(NSInteger returnCode){}];
    }];
    //ドキュメント保存中
    [[NSNotificationCenter defaultCenter] addObserverForName:@"PDFDidEndDocumentWrite" object:[_pdfView document] queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        //プログレス・バーの値を更新
        double currentPg = [[notif.userInfo objectForKey: @"PDFDocumentPageIndex"] floatValue];
        [savingProgBar setDoubleValue:currentPg];
        [savingProgBar displayIfNeeded];
    }];
    //ドキュメント保存完了
    [[NSNotificationCenter defaultCenter] addObserverForName:@"PDFDidEndPageWrite" object:[_pdfView document] queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        //プログレス・パネルを終了させる
        [self.window endSheet:progressWin returnCode:0];
    }];
    //メインウインドウ変更
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeMainNotification object:self.window queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        [APPD documentMenuSetEnabled:YES];
        //ページ移動メニューの有効/無効の切り替え
        [self updateGoButtonEnabled];
        //倍率変更メニューの有効／無効の切り替え
        [self updateSizingBtnEnabled];
        //ディスプレイ・モード変更メニューのステータス変更
        [self updateDisplayModeMenuStatus];
        //スクリーンモード変更メニューのタイトルを変更
        [self mnFullScreenSetTitle];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification object:self.window queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        NSDocumentController *docCtr = [NSDocumentController sharedDocumentController];
        if (docCtr.documents.count == 1) {
            [APPD documentMenuSetEnabled:NO];
        }
    }];
    //ページ移動
    [[NSNotificationCenter defaultCenter] addObserverForName:PDFViewPageChangedNotification object:_pdfView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        //ページ移動ボタンの有効/無効の切り替え
        [self updateGoButtonEnabled];
        //ページ表示テキストフィールドの値を変更
        [self updateTxtPg];
    }];
    //表示倍率変更
    [[NSNotificationCenter defaultCenter]addObserverForName:PDFViewScaleChangedNotification object:_pdfView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        //倍率変更ボタン／メニューの有効／無効の切り替え
        [self updateSizingBtnEnabled];
    }];
    //ディスプレイモード変更
    [[NSNotificationCenter defaultCenter]addObserverForName:PDFViewDisplayBoxChangedNotification object:_pdfView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        //ディスプレイ・モード変更メニューのステータス変更
        [self updateDisplayModeMenuStatus];
    }];
    //スクリーンモード変更
    [[NSNotificationCenter defaultCenter]addObserverForName:NSWindowDidEnterFullScreenNotification object:self.window queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        bFullscreen = YES;
        [self mnFullScreenSetTitle];
    }];
    [[NSNotificationCenter defaultCenter]addObserverForName:NSWindowDidExitFullScreenNotification object:self.window queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        bFullscreen = NO;
        [self mnFullScreenSetTitle];
    }];
}

- (void) updateTxtPg {
    PDFDocument *doc = _pdfView.document;
    NSUInteger index = [doc indexForPage:[_pdfView currentPage]] + 1;
    [txtPage setStringValue:[NSString stringWithFormat:@"%li",index]];
}

//ページ移動ボタン／メニューの有効/無効の切り替え
- (void)updateGoButtonEnabled{
    if (_pdfView.canGoToFirstPage) {
        [btnGoToFirstPage setEnabled:YES];
        [[APPD mnGoToFirstPg]setEnabled:YES];
    } else {
        [btnGoToFirstPage setEnabled:NO];
        [[APPD mnGoToFirstPg]setEnabled:NO];
    }
    if (_pdfView.canGoToPreviousPage) {
        [btnGoToPrevPage setEnabled:YES];
        [[APPD mnGoToPrevPg]setEnabled:YES];
    } else {
        [btnGoToPrevPage setEnabled:NO];
        [[APPD mnGoToPrevPg]setEnabled:NO];
    }
    if (_pdfView.canGoToNextPage){
        [btnGoToNextPage setEnabled:YES];
        [[APPD mnGoToNextPg]setEnabled:YES];
    } else {
        [btnGoToNextPage setEnabled:NO];
        [[APPD mnGoToNextPg]setEnabled:NO];
    }
    if (_pdfView.canGoToLastPage){
        [btnGoToLastPage setEnabled:YES];
        [[APPD mnGoToLastPg]setEnabled:YES];
    } else {
        [btnGoToLastPage setEnabled:NO];
        [[APPD mnGoToLastPg]setEnabled:NO];
    }
    if (_pdfView.canGoBack) {
        [btnGoBack setEnabled:YES];
        [[APPD mnGoBack]setEnabled:YES];
    } else {
        [btnGoBack setEnabled:NO];
        [[APPD mnGoBack]setEnabled:NO];
    }
    if (_pdfView.canGoForward) {
        [btnGoForward setEnabled:YES];
        [[APPD mnGoForward]setEnabled:YES];
    } else {
        [btnGoForward setEnabled:NO];
        [[APPD mnGoForward]setEnabled:NO];
    }
}

//倍率変更ボタン／メニューの有効／無効の切り替え
- (void)updateSizingBtnEnabled{
    if (_pdfView.scaleFactor < 5.0) {
        [segZoom setEnabled:YES forSegment:0];
        [[APPD mnZoomIn]setEnabled:YES];
    } else {
        [segZoom setEnabled:NO forSegment:0];
        [[APPD mnZoomIn]setEnabled:NO];
    }
    if (_pdfView.canZoomOut) {
        [segZoom setEnabled:YES forSegment:1];
        [[APPD mnZoomOut]setEnabled:YES];
    } else {
        [segZoom setEnabled:NO forSegment:1];
        [[APPD mnZoomOut]setEnabled:NO];
    }
}

//ディスプレイ・モード変更ボタン／メニューのステータス変更
- (void)updateDisplayModeMenuStatus{
    [APPD setMnPageDisplayState:[matrixDisplayMode selectedColumn]];
}

//スクリーンモード変更メニューのタイトルを変更
- (void)mnFullScreenSetTitle{
    if (bFullscreen) {
        [[APPD mnFullScreen]setTitle:NSLocalizedString(@"MnTitleExitFullScreen", @"")];
    } else {
        [[APPD mnFullScreen]setTitle:NSLocalizedString(@"MnTitleEnterFullScreen", @"")];
    }
}

#pragma mark - make new document

- (void)makeNewDocWithPDF:(PDFDocument*)pdf{
    [_pdfView setDocument:pdf];
}

#pragma mark - split view delegate

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex{
    return proposedMin + kMinTocAreaSplit;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex{
    return proposedMax - kMinTocAreaSplit;
}

- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize{
    NSRect newFrame = [splitView frame];    //新しいsplitView全体のサイズを取得
    NSView *leftView = [[splitView subviews]objectAtIndex:0];
    NSRect leftFrame = [leftView frame];
    NSView *rightView = [[splitView subviews]objectAtIndex:1];
    NSRect rightFrame = [rightView frame];
    CGFloat dividerThickness = [splitView dividerThickness];
    
    leftFrame.size.height = newFrame.size.height;
    rightFrame.size.width = newFrame.size.width - leftFrame.size.width - dividerThickness;
    rightFrame.size.height = newFrame.size.height;
    rightFrame.origin.x = leftFrame.size.width + dividerThickness;
    
    [leftView setFrame:leftFrame];
    [rightView setFrame:rightFrame];
}

#pragma mark - actions

- (IBAction)txtJumpPage:(id)sender {
    PDFDocument *doc = [_pdfView document];
    PDFPage *page = [doc pageAtIndex:[[sender stringValue]integerValue]-1];
    [_pdfView goToPage:page];
}

//コンテンツ・エリアのビューを切り替え
- (IBAction)segSelContentsView:(id)sender {
    [tabToc selectTabViewItemAtIndex:[sender selectedSegment]];
}

//コンテンツ・エリアの表示／非表示を切り替え
- (IBAction)showSideBar:(id)sender {
    CGFloat currentTocWidth = tocView.frame.size.width;
    if (currentTocWidth == 0) {
        //目次エリアを表示
        [tocView setFrame:NSMakeRect(0, 0, oldTocWidth, _splitView.frame.size.height)];
        [searchField setFrame:NSMakeRect(70, 4, oldTocWidth-77, 19)];
    } else {
        //目次エリアを非表示
        oldTocWidth = tocView.frame.size.width; //非表示前の目次エリア幅を保存
        [tocView setFrame:NSMakeRect(0, 0, 0, _splitView.frame.size.height)];
    }
}

//ディスプレイ・モードを切り替え
- (IBAction)matrixDisplayMode:(id)sender {
    switch ([sender selectedColumn]) {
        case 0:
            [_pdfView setDisplayMode:kPDFDisplaySinglePage];
            break;
        case 2:
            [_pdfView setDisplayMode:kPDFDisplayTwoUp];
            break;
        case 3:
            [_pdfView setDisplayMode:kPDFDisplayTwoUpContinuous];
            break;
        default:
            [_pdfView setDisplayMode:kPDFDisplaySinglePageContinuous];
            break;
    }
}

- (IBAction)segZoom:(id)sender {
    switch ([sender selectedSegment]) {
        case 0:
            [self zoomIn:nil];
            break;
        case 1:
            [self zoomOut:nil];
            break;
        default:
            [self zoomImageToFit:nil];
            break;
    }
}

#pragma mark - menu action

//表示メニュー
- (IBAction)zoomIn:(id)sender{
    [_pdfView zoomIn:nil];
}

- (IBAction)zoomOut:(id)sender{
    [_pdfView zoomOut:nil];
}

- (IBAction)zoomImageToFit:(id)sender{
    [_pdfView setAutoScales:YES];
    [_pdfView setAutoScales:NO];
}

- (IBAction)zoomImageToActualSize:(id)sender{
    [_pdfView setScaleFactor:1];
}

- (IBAction)mnSinglePage:(id)sender{
    [matrixDisplayMode selectCellWithTag:0];
    [APPD setMnPageDisplayState:0];
    [self matrixDisplayMode:matrixDisplayMode];
}

- (IBAction)mnSingleCont:(id)sender{
    [matrixDisplayMode selectCellWithTag:1];
    [APPD setMnPageDisplayState:1];
    [self matrixDisplayMode:matrixDisplayMode];
}

- (IBAction)mnTwoPages:(id)sender{
    [matrixDisplayMode selectCellWithTag:2];
    [APPD setMnPageDisplayState:2];
    [self matrixDisplayMode:matrixDisplayMode];
}

- (IBAction)mnTwoPagesCont:(id)sender{
    [matrixDisplayMode selectCellWithTag:3];
    [APPD setMnPageDisplayState:3];
    [self matrixDisplayMode:matrixDisplayMode];
}

//移動メニュー
- (IBAction)goToPreviousPage:(id)sender{
    [_pdfView goToPreviousPage:nil];
}

- (IBAction)goToNextPage:(id)sender{
    [_pdfView goToNextPage:nil];
}

- (IBAction)goToFirstPage:(id)sender{
    [_pdfView goToFirstPage:nil];
}

- (IBAction)goToLastPage:(id)sender{
    [_pdfView goToLastPage:nil];
}

- (IBAction)goBack:(id)sender{
    [_pdfView goBack:nil];
}

- (IBAction)goForward:(id)sender{
    [_pdfView goForward:nil];
}

- (IBAction)mnGoToPage:(id)sender{
    [self.window makeFirstResponder:txtPage];
}

@end
