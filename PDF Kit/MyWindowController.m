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

#pragma mark - save document

//ドキュメントを保存
- (void)saveDocument:(id)sender{
    if (docURL){
        [_pdfView.document writeToURL:docURL];
    } else {
        [self saveDocumentAs:sender];
    }
}

//ドキュメントを別名で保存
- (void)saveDocumentAs:(id)sender{
    //savePanelの設定と表示
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    NSArray *fileTypes = [NSArray arrayWithObjects:@"pdf", nil];
    [savePanel setAllowedFileTypes:fileTypes]; //保存するファイルの種類
    //初期ファイル名をセット
    if (docURL){
        [savePanel setNameFieldStringValue:[[docURL path] lastPathComponent]];
    }
    [savePanel setCanSelectHiddenExtension:YES]; //拡張子を隠すチェックボックスの有無
    [savePanel setExtensionHidden:NO]; //拡張子を隠すチェックボックスの初期ステータス
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            docURL = [savePanel URL];
            [savePanel orderOut:self];
            [_pdfView.document writeToURL:docURL];
            Document *doc = [self document];
            //ドキュメントのURLを更新
            [doc setFileURL:docURL];
        }
    }];
}

#pragma mark - make new document

- (void)makeNewDocWithPDF:(PDFDocument*)pdf{
    [_pdfView setDocument:pdf];
}

#pragma mark - actions

- (IBAction)txtJumpPage:(id)sender {
    PDFDocument *doc = [_pdfView document];
    PDFPage *page = [doc pageAtIndex:[[sender stringValue]integerValue]-1];
    [_pdfView goToPage:page];
}

@end
