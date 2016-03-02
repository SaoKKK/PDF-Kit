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

#define kMinTocAreaSplit	200.0f

@interface MyWindowController ()

@end

@implementation MyWindowController

#pragma mark - Window Controller Method

- (void)windowDidLoad {
    [super windowDidLoad];
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
    //ページ移動
    [[NSNotificationCenter defaultCenter] addObserverForName:PDFViewPageChangedNotification object:_pdfView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        //ページ移動ボタンの有効/無効の切り替え
        if (_pdfView.canGoToFirstPage) {
            [btnGoToFirstPage setEnabled:YES];
        } else {
            [btnGoToFirstPage setEnabled:NO];
        }
        if (_pdfView.canGoToPreviousPage) {
            [btnGoToPrevPage setEnabled:YES];
        } else {
            [btnGoToPrevPage setEnabled:NO];
        }
        if (_pdfView.canGoToNextPage){
            [btnGoToNextPage setEnabled:YES];
        } else {
            [btnGoToNextPage setEnabled:NO];
        }
        if (_pdfView.canGoToLastPage){
            [btnGoToLastPage setEnabled:YES];
        } else {
            [btnGoToLastPage setEnabled:NO];
        }
        if (_pdfView.canGoBack) {
            [btnGoBack setEnabled:YES];
        } else {
            [btnGoBack setEnabled:NO];
        }
        if (_pdfView.canGoForward) {
            [btnGoFoward setEnabled:YES];
        } else {
            [btnGoFoward setEnabled:NO];
        }
        //ページ表示テキストフィールドの値を変更
        [self updateTxtPg];
    }];
}

- (void) updateTxtPg {
    PDFDocument *doc = _pdfView.document;
    NSUInteger index = [doc indexForPage:[_pdfView currentPage]] + 1;
    [txtPage setStringValue:[NSString stringWithFormat:@"%li",index]];
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
- (IBAction)displayModeMatrix:(id)sender {
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

- (IBAction)test:(id)sender {
    NSLog (@"%@",[thumbView selectedPages]);
}

@end
