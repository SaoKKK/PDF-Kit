//
//  MergePDFWin.m
//  Sao's PDF Kit
//
//  Created by 河野 さおり on 2016/02/15.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "MergePDFWin.h"
#import "AppDelegate.h"
#import <Quartz/Quartz.h>
#import "MyWindowController.h"

#define MyTVDragNDropPboardType @"MyTVDragNDropPboardType"
#define APPD (AppDelegate *)[NSApp delegate]

@interface MergePDFWin (){
    IBOutlet NSWindow *window;
    IBOutlet NSWindow *errSheet;
    IBOutlet NSWindow *progressWin;
    IBOutlet NSProgressIndicator *progressBar;
}

@end

@implementation MergePDFWin{
    NSArray *langAllPages;
    NSString *errMsgTxt,*errInfoTxt;
    double outputPDFTotalPg;
    NSArray *comboData;
}

#pragma mark - initialize method

- (id)init{
    self = [super init];
    if (self) {
        langAllPages = [NSArray arrayWithObjects:@"All Pages",@"全ページ",nil];
    }
    return self;
}

- (id)initWithWindow:(NSWindow *)win{
    self = [super initWithWindow:win];
    if (self){
        //既存のPDFリストがなく、開かれているドキュメントがある場合は開かれているドキュメントをリストに取り込む
        NSDocumentController *docC = [NSDocumentController sharedDocumentController];
        NSArray *docs = [docC documents];
        if ([APPD PDFLst].count == 0 && docs.count > 0) {
            for (NSDocument *doc in docs){
                if (doc.fileURL != nil) {
                    [self addToPDFLst:doc.fileURL atIndex:[APPD PDFLst].count];
                }
            }
            [mergePDFtable reloadData];
        }
        //ノーティフィケーションを設定
        [self setUpNotification];
        //コンボボックスのデータソース用配列を作成
        comboData = [NSArray arrayWithObjects:NSLocalizedString(@"ALL_PAGES", @""),@"e.g. 1-2,5,10",nil];
        //スクリーンモード保持用変数を初期化
        bFullscreen = NO;
    }
    return self;
}

//ドラッグを受け付けるファイルタイプを設定
- (void)awakeFromNib{
    [mergePDFtable registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,MyTVDragNDropPboardType,nil]];
    //他アプリケーションからのドラッグアンドドロップを許可
    [mergePDFtable setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
    [self setEnabledButtons];
}

//ボタンのEnabledを変更
- (void)setEnabledButtons{
    if ([APPD PDFLst].count == 0) {
        [btnClear setEnabled:NO];
        [btnMerge setEnabled:NO];
        [btnStoreWS setEnabled:NO];
    } else {
        [btnClear setEnabled:YES];
        [btnMerge setEnabled:YES];
        [btnStoreWS setEnabled:YES];
    }
}

//スクリーンモード変更メニューのタイトルを変更
- (void)mnFullScreenSetTitle{
    if (bFullscreen) {
        [[APPD mnFullScreen]setTitle:NSLocalizedString(@"MnTitleExitFullScreen", @"")];
    } else {
        [[APPD mnFullScreen]setTitle:NSLocalizedString(@"MnTitleEnterFullScreen", @"")];
    }
}

#pragma mark - set up notification

- (void)setUpNotification{
    //PDF挿入開始
    [[NSNotificationCenter defaultCenter] addObserverForName:@"PDFDidBeginCreate" object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        //プログレスバーのステータスを設定
        [progressBar setMaxValue:outputPDFTotalPg];
        [progressBar setDoubleValue: 0.0];
        //プログレス・パネルをシート表示
        [self.window beginSheet:progressWin completionHandler:^(NSInteger returnCode){}];
    }];
    //PDF挿入過程
    [[NSNotificationCenter defaultCenter] addObserverForName:@"PDFDidEndPageInsert" object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        //プログレスバーの値を更新
        NSNumber *page = [[notif userInfo] objectForKey:@"page"];
        [progressBar setDoubleValue:page.doubleValue];
        [progressBar displayIfNeeded];
    }];
    //PDF挿入終了
    [[NSNotificationCenter defaultCenter] addObserverForName:@"PDFDidEndCreate" object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        //プログレス・パネルを終了させる
        [self.window endSheet:progressWin returnCode:0];
    }];
    //キーウインドウになった
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification object:self.window queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        //メニューの有効/無効の切り替え
        [APPD mergeMenuSetEnabled];
        //ページ移動ボタンの有効/無効の切り替え
        [self updateGoButtonEnabled];
        //スクリーンモード変更メニューのタイトルを変更
        [self mnFullScreenSetTitle];
    }];
    //ウインドウが閉じられた
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification object:self.window queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        NSDocumentController *docCtr = [NSDocumentController sharedDocumentController];
        if (docCtr.documents.count == 0) {
            [APPD documentMenuSetEnabled:NO];
        }
    }];
    //ページ移動
    [[NSNotificationCenter defaultCenter] addObserverForName:PDFViewPageChangedNotification object:_pdfView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        //ページ移動ボタンの有効/無効の切り替え
        [self updateGoButtonEnabled];
        //ページ表示テキストフィールドの値を変更
        [self updateTxtPage];
    }];
    //表示ドキュメント変更
    [[NSNotificationCenter defaultCenter] addObserverForName:PDFViewDocumentChangedNotification object:_pdfView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        PDFDocument *doc = _pdfView.document;
        if (doc) {
            NSUInteger totalPg = doc.pageCount;
            [txtTotalPg setStringValue:[NSString stringWithFormat:@"%li",totalPg]];
            [txtPageFormatter setMaximum:[NSNumber numberWithInteger:totalPg]];
            //ページ表示テキストフィールドの値を変更
            [self updateTxtPage];
            //ページ移動ボタンの有効/無効の切り替え
            [self updateGoButtonEnabled];
        } else {
            [txtTotalPg setStringValue:@""];
            [txtPage setStringValue:@""];
            [txtPageFormatter setMaximum:nil];
            [APPD documentMenuSetEnabled:NO];
        }
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

- (void) updateTxtPage {
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

# pragma mark - NSComboBox data source

//コンボボックスのデータソースのアイテム数を返す
- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox{
    return comboData.count;
}

//各インデクスのオブジェクトバリューを返す
- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index{
    return [comboData objectAtIndex:index];
}

# pragma mark - NSTableView data source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return [APPD PDFLst].count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    NSString *identifier = [tableColumn identifier];
    NSDictionary *data = [[APPD PDFLst] objectAtIndex:row];
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:identifier owner:self];
    cellView.objectValue = [data objectForKey:identifier];
    return cellView;
}

//行の選択状態の変化
- (void)tableViewSelectionDidChange:(NSNotification *)notification{
    if ([[mergePDFtable selectedRowIndexes]count] != 0) {
        [btnRemove setEnabled:YES];
        if ([[mergePDFtable selectedRowIndexes]count] == 1){
            //PDFViewにPDFドキュメントを設定
            NSDictionary *data = [[APPD PDFLst] objectAtIndex:[mergePDFtable selectedRow]];
            NSFileManager *fileMgr = [NSFileManager defaultManager];
            NSString *fPath = [data objectForKey:@"fPath"];
            if ([fileMgr fileExistsAtPath:fPath]) {
                NSURL *url = [NSURL fileURLWithPath:fPath];
                PDFDocument *document = [[PDFDocument alloc]initWithURL:url];
                [_pdfView setDocument:document];
            } else {
                //テーブルのデータが実在しない場合
                [_pdfView setDocument:nil];
                NSRect rect = NSMakeRect(self.window.frame.origin.x + _pdfView.frame.origin.x + (_pdfView.frame.size.width - [APPD statusWin].frame.size.width)*0.5, self.window.frame.origin.y + (self.window.frame.size.height - [APPD statusWin].frame.size.height)*0.5, [APPD statusWin].frame.size.width, [APPD statusWin].frame.size.height);
                [APPD showStatusWin:rect messageText:NSLocalizedString(@"PDF_READ_ERROR_MESSAGETEXT", @"") infoText:NSLocalizedString(@"PDF_READ_ERROR_INFOTEXT", @"")];
            }
        } else {
            [_pdfView setDocument:nil];
        }
    } else {
        [btnRemove setEnabled:NO];
        [_pdfView setDocument:nil];
    }
}

- (void)closeStatusWin{
    [[APPD statusWin] orderOut:self];
}

#pragma mark - Actions

//コンボボックス・アクション/データ更新
- (IBAction)comboPageRange:(id)sender {
    if ([sender indexOfSelectedItem] == 0) {
        [sender setStringValue:NSLocalizedString(@"ALL_PAGES", @"")];
        [self.window makeFirstResponder:nil];
        [sender setEditable:NO];
    } else if ([sender indexOfSelectedItem] == 1){
        [sender setStringValue:@""];
        [sender setEditable:YES];
        [self.window makeFirstResponder:sender];
    }
    NSInteger row = [mergePDFtable rowForView:sender];
    NSDictionary *data = [[APPD PDFLst] objectAtIndex:row];
    [data setValue:[sender stringValue] forKey:@"pageRange"];
    [[APPD PDFLst] replaceObjectAtIndex:row withObject:data];
}

//行追加
- (IBAction)btnAdd:(id)sender{
    [self.window makeFirstResponder:self];
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    NSArray *fileTypes = [NSArray arrayWithObjects:@"pdf", nil];
    [openPanel setAllowedFileTypes:fileTypes];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            for (NSURL *url in [openPanel URLs]) {
                [self addToPDFLst:url atIndex:[APPD PDFLst].count];
            }
            [mergePDFtable reloadData];
            [btnRemove setEnabled:NO];
            [self setEnabledButtons];
        }
    }];
}

//行削除
- (IBAction)btnRemove:(id)sender{
    [window makeFirstResponder:self];
    NSIndexSet *selectedRows = [mergePDFtable selectedRowIndexes];
    [[APPD PDFLst] removeObjectsAtIndexes:selectedRows];
    [mergePDFtable reloadData];
    [_pdfView setDocument:nil];
    [btnRemove setEnabled:NO];
    [self setEnabledButtons];
}

//テーブル・クリア
- (IBAction)btnClear:(id)sender {
    [window makeFirstResponder:self];
    [[APPD PDFLst] removeAllObjects];
    [mergePDFtable reloadData];
    [btnRemove setEnabled:NO];
    [self setEnabledButtons];
}

- (IBAction)btnOpenData:(id)sender {
    [window makeFirstResponder:self];
    [APPD restorePDFLst];
    for (int i = 0; i < [APPD PDFLst].count; i++) {
        NSMutableDictionary *data = [[APPD PDFLst] objectAtIndex:i];
        if ([langAllPages containsObject:[data objectForKey:@"pageRange"]]) {
            [data setObject:NSLocalizedString(@"ALL_PAGES", @"") forKey:@"pageRange"];
            [[APPD PDFLst] replaceObjectAtIndex:i withObject:data];
        }
    }
    [mergePDFtable reloadData];
    [self setEnabledButtons];
}

- (IBAction)btnSaveData:(id)sender {
    [window makeFirstResponder:self];
    [[APPD PDFLst] writeToFile:[[NSBundle mainBundle] pathForResource:@"PDFLst" ofType: @"array"] atomically:YES];
    //終了ダイアログ表示
    NSRect rect = NSMakeRect(self.window.frame.origin.x + (mergePDFtable.frame.size.width - [APPD statusWin].frame.size.width)*0.5, self.window.frame.origin.y + (self.window.frame.size.height - [APPD statusWin].frame.size.height)*0.5, [APPD statusWin].frame.size.width, [APPD statusWin].frame.size.height);
    [APPD showStatusWin:rect messageText:NSLocalizedString(@"SAVE_FILELIST_MESSAGETEXT", @"SAVE_FILELIST_MESSAGETEXT") infoText:NSLocalizedString(@"SAVE_FILELIST_INFOTEXT", @"SAVE_FILELIST_INFOTEXT")];
}

- (IBAction)txtJumpPg:(id)sender {
    PDFDocument *doc = [_pdfView document];
    PDFPage *page = [doc pageAtIndex:[[sender stringValue]integerValue]-1];
    [_pdfView goToPage:page];
}

#pragma mark - menu action
//移動メニュー
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

#pragma mark - Drag Operation Method

//ドラッグを開始（ペーストボードに書き込む）
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
    dragRows = rowIndexes;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:MyTVDragNDropPboardType] owner:self];
    [pboard setData:data forType:MyTVDragNDropPboardType];
    return YES;
}

//ドロップを確認
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op {
    //間へのドロップのみ認証
    [tv setDropRow:row dropOperation:NSTableViewDropAbove];
    if ([info draggingSource] == tv) {
        return NSDragOperationMove;
    }
    return NSDragOperationEvery;
}

//ドロップ受付開始
- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op {
    if (dragRows) {
        //テーブル内の行の移動
        NSUInteger index = [dragRows firstIndex];
        while(index != NSNotFound) {
            //ドロップ先にドラッグ元のオブジェクトを挿入する
            if (row > [APPD PDFLst].count) {
                [[APPD PDFLst] addObject:[[APPD PDFLst] objectAtIndex:index]];
            }else{
                [[APPD PDFLst] insertObject:[[APPD PDFLst] objectAtIndex:index] atIndex:row];
            }
            //ドラッグ元のオブジェクトを削除する
            if (index > row) {
                //indexを後ろにずらす
                [[APPD PDFLst] removeObjectAtIndex:index + 1];
            }else{
                [[APPD PDFLst] removeObjectAtIndex:index];
            }
            index = [dragRows indexGreaterThanIndex:index];
            row ++;
        }
        dragRows = nil;
    } else {
        //ファインダからのドロップオブジェクトからPDFファイル情報を取得
        NSPasteboard *pasteboard = [info draggingPasteboard];
        NSArray *dropDataList = [pasteboard propertyListForType:NSFilenamesPboardType];
        NSWorkspace *workSpc = [NSWorkspace sharedWorkspace];
        [[APPD errLst] removeAllObjects];
        for (id path in dropDataList) {
            NSString *uti = [workSpc typeOfFile:path error:nil];
            NSString *fName = [path lastPathComponent];
            if ([uti isEqualToString:@"com.adobe.pdf"]) {
                [self addToPDFLst:[NSURL fileURLWithPath:path] atIndex:row];
                row ++;
            } else {
                [[APPD errLst] addObject:fName];
            }
        }
    }
    [tv reloadData];
    [self setEnabledButtons];
    if ([APPD errLst].count > 0) {
        [self showErrLst];
    }
    return YES;
}

//PDFファイル情報を配列に追加
- (void)addToPDFLst:(NSURL*)url atIndex:(NSInteger)row{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSDictionary *fInfo = [NSDictionary dictionaryWithDictionary:[fileMgr attributesOfItemAtPath:[url path] error:nil]];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject:[url path] forKey:@"fPath"];
    [data setObject:[[url path]lastPathComponent] forKey:@"fName"];
    [data setObject:[fInfo objectForKey:NSFileSize] forKey:@"fSize"];
    [data setObject:NSLocalizedString(@"ALL_PAGES", @"") forKey:@"pageRange"];
    //PDF情報を取得
    PDFDocument *document = [[PDFDocument alloc]initWithURL:url];
    NSUInteger totalPage = [document pageCount];
    [data setObject:[NSNumber numberWithUnsignedInteger:totalPage] forKey:@"totalPage"];
    [[APPD PDFLst] insertObject:data atIndex:row];
}

#pragma mark - Error list window controll

- (void)showErrLst{
    [errTable reloadData];
    [[NSApplication sharedApplication] beginSheet:errSheet modalForWindow:self.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)sheetDidEnd:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo{
    [sheet orderOut:self];
}

- (IBAction)pshOK:(id)sender {
    [[NSApplication sharedApplication] endSheet:errSheet returnCode:0];
}

#pragma mark - Merge PDF

- (IBAction)btnMerge:(id)sender {
    [self.window makeFirstResponder:self];
    double outputPDFPageIndex = 0;
    outputPDFTotalPg = 0;
    //PDFLstの内容をチェック
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSMutableArray *indexes = [NSMutableArray array];
    for (NSDictionary *data in [APPD PDFLst]) {
        if ([fileMgr fileExistsAtPath:[data objectForKey:@"fPath"]]) {
            //ページ範囲をインデックス・セットに変換
            NSMutableIndexSet *pageRange = [NSMutableIndexSet indexSet];
            NSString *indexString = [data objectForKey:@"pageRange"];
            NSUInteger totalPage = [[data objectForKey:@"totalPage"] integerValue];
            if ([indexString isEqualToString:NSLocalizedString(@"ALL_PAGES",@"")]) {
                //All Pagesが選択されている場合
                [pageRange addIndexesInRange:NSMakeRange(1, totalPage)];
            } else {
                //入力値に不正な文字列が含まれないかチェック
                NSCharacterSet *pgRangeChrSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789,-"];
                NSCharacterSet *inputChrSet = [NSCharacterSet characterSetWithCharactersInString:indexString];
                if (! [pgRangeChrSet isSupersetOfSet:inputChrSet]) {
                    //入力値が不正文字列を含む
                    [self setErrMessage:[data objectForKey:@"fName"]];
                    [self showErrorDialog];
                    return;
                } else {
                    //入力値をカンマで分割
                    NSArray *ranges = [indexString componentsSeparatedByString:@","];
                    for (NSString *range in ranges) {
                        //インデクス指定文字列を"-"で分割
                        NSArray *pages = [range componentsSeparatedByString:@"-"];
                        if (pages.count > 2) {
                            //"-"が2つ以上含まれる場合
                            [self setErrMessage:[data objectForKey:@"fName"]];
                            [self showErrorDialog];
                            return;
                        } else if (pages.count == 1) {
                            //"-"が含まれない場合
                            if ([range integerValue] <= totalPage && [range integerValue] > 0) {
                                [pageRange addIndex:[range integerValue]];
                            } else {
                                [self setErrMessage:[data objectForKey:@"fName"]];
                                [self showErrorDialog];
                                return;
                            }
                        } else if ([[pages objectAtIndex:0]isEqualToString:@""]) {
                            //"-"が先頭にある場合
                            [pageRange addIndexesInRange:NSMakeRange(1,[[pages objectAtIndex:1]integerValue])];
                        } else if ([[pages objectAtIndex:1]isEqualToString:@""]) {
                            //"-"が末尾にある場合
                            if ([[pages objectAtIndex:0]integerValue] > totalPage) {
                                [self setErrMessage:[data objectForKey:@"fName"]];
                                [self showErrorDialog];
                                return;
                            } else {
                                [pageRange addIndexes:[self indexFrom1stIndex:[[pages objectAtIndex:0]integerValue] toLastIndex:totalPage]];
                            }
                        } else {
                            //通常の範囲指定
                            if ([[pages objectAtIndex:0]integerValue] < 1 || [[pages objectAtIndex:0]integerValue] > totalPage || [[pages objectAtIndex:0]integerValue] > [[pages objectAtIndex:1]integerValue]) {
                                [self setErrMessage:[data objectForKey:@"fName"]];
                                [self showErrorDialog];
                                return;
                            } else {
                                [pageRange addIndexes:[self indexFrom1stIndex:[[pages objectAtIndex:0]integerValue] toLastIndex:[[pages objectAtIndex:1]integerValue]]];
                            }
                        }
                    }
                }
            }
            outputPDFTotalPg = outputPDFTotalPg + [pageRange count];
            [indexes addObject:pageRange];
        } else {
            //ファイルが実在しない場合
            NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
            if ([language isEqualToString:@"en"]){
                errMsgTxt = @"File Not Found Error:";
                errInfoTxt = [NSMutableString stringWithFormat:@"an error occurred in the file \"%@\" processing.\nThe file does not exist.",[data objectForKey:@"fName"]];
            } else {
                errMsgTxt = @"ファイルパスエラー:";
                errInfoTxt = [NSMutableString stringWithFormat:@"ファイル \"%@\" の処理でエラーが起こりました。\nファイルが見つかりません。",[data objectForKey:@"fName"]];
            }
            [self showErrorDialog];
            return;
        }
    }
    //PDF結合処理開始
    PDFDocument *outputDoc = [[PDFDocument alloc] init];
    NSUInteger pageIndex = 0;
    //PDF作成開始ノーティフィケーションを送信
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PDFDidBeginCreate" object:self];
    
    for (int i = 0; i < [APPD PDFLst].count; i++){
        NSDictionary *data = [[APPD PDFLst] objectAtIndex:i];
        NSURL *url = [NSURL fileURLWithPath:[data objectForKey:@"fPath"]];
        PDFDocument *inputDoc = [[PDFDocument alloc]initWithURL:url];
        NSIndexSet *pageRange = [indexes objectAtIndex:i];
        NSUInteger index = [pageRange firstIndex];
        while(index != NSNotFound) {
            //PDFページ挿入終了ノーティフィケーションを送信
            outputPDFPageIndex++;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PDFDidEndPageInsert" object:self userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:outputPDFPageIndex] forKey:@"page"]];
            PDFPage *page = [inputDoc pageAtIndex:index - 1];
            [outputDoc insertPage:page atIndex:pageIndex++];
            
            index = [pageRange indexGreaterThanIndex:index];
        }
    }
    //PDF作成終了ノーティフィケーションを送信
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PDFDidEndCreate" object:self];
    
    NSDocumentController *docC = [NSDocumentController sharedDocumentController];
    [docC openUntitledDocumentAndDisplay:YES error:nil];
    MyWindowController *newWC= [docC.currentDocument.windowControllers objectAtIndex:0];
    [newWC makeNewDocWithPDF:outputDoc];
}

//ページ範囲指定エラー用エラーメッセージを作成
- (void)setErrMessage:(NSString*)fileName{
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if ([language isEqualToString:@"en"]){
        errMsgTxt = @"Page Range Error:";
        errInfoTxt = [NSMutableString stringWithFormat:@"an error occurred in the file \"%@\" processing.\nThe value of the page range is not correct.",fileName];
    } else {
        errMsgTxt = @"ページ範囲指定エラー:";
        errInfoTxt = [NSMutableString stringWithFormat:@"ファイル \"%@\" の処理でエラーが起こりました。\nページ範囲の指定が不正です。",fileName];
    }
}

//エラーダイアログ表示
- (void)showErrorDialog{
    NSAlert *alert = [[NSAlert alloc]init];
    alert.messageText = errMsgTxt;
    [alert addButtonWithTitle:@"OK"];
    [alert setInformativeText:errInfoTxt];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode){}];
}

//最初と最後のインデクスを指定してインデクスセットを作成
- (NSMutableIndexSet *)indexFrom1stIndex:(NSUInteger)firstIndex toLastIndex:(NSUInteger)lastIndex{
    NSMutableIndexSet *indexset = [NSMutableIndexSet indexSet];
    for (NSUInteger i = firstIndex; i <= lastIndex; i++) {
        [indexset addIndex:i];
    }
    return indexset;
}

@end
