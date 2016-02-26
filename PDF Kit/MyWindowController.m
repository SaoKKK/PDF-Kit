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
    //ドキュメントの保存過程にノーティフィケーションを設定
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(documentBeginWrite:) name: @"PDFDidBeginDocumentWrite" object: [_pdfView document]];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(documentEndWrite:) name: @"PDFDidEndDocumentWrite" object: [_pdfView document]];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(documentEndPageWrite:) name: @"PDFDidEndPageWrite" object: [_pdfView document]];
    //デリゲートを設定
    [[_pdfView document] setDelegate: self];
}

#pragma mark - saving progress

- (void) documentBeginWrite: (NSNotification *) notification{
    double pgCnt = [[_pdfView document] pageCount];
    [savingProgBar setMaxValue:pgCnt];
    [savingProgBar setDoubleValue: 0.0];
    //プログレス・パネルをシート表示
    [self.window beginSheet:progressWin completionHandler:^(NSInteger returnCode){}];
}

- (void) documentEndWrite: (NSNotification *) notification{
    //プログレス・パネルを終了させる
    [self.window endSheet:progressWin returnCode:0];
}

- (void) documentEndPageWrite: (NSNotification *) notification{
    double currentPg = [[[notification userInfo] objectForKey: @"PDFDocumentPageIndex"] floatValue];
    [savingProgBar setDoubleValue:currentPg];
    [savingProgBar displayIfNeeded];
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

@end
