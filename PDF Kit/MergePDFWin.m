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
    double outputPDFPageIndex,outputPDFTotalPg;
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
        AppDelegate *appD = [NSApp delegate];
        NSDocumentController *docC = [NSDocumentController sharedDocumentController];
        NSArray *docs = [docC documents];
        if (appD.PDFLst.count == 0 && docs.count > 0) {
            for (NSDocument *doc in docs){
                if (doc.fileURL != nil) {
                    [self addToPDFLst:doc.fileURL atIndex:appD.PDFLst.count];
                }
            }
            [mergePDFtable reloadData];
        }
        //ノーティフィケーションを設定
        [self setUpNotification];
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
    AppDelegate *appD = [NSApp delegate];
    if (appD.PDFLst.count == 0) {
        [btnClear setEnabled:NO];
        [btnMerge setEnabled:NO];
        [btnStoreWS setEnabled:NO];
    } else {
        [btnClear setEnabled:YES];
        [btnMerge setEnabled:YES];
        [btnStoreWS setEnabled:YES];
    }
}

# pragma mark - NSTableView data source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    AppDelegate *appD = [NSApp delegate];
    return appD.PDFLst.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    AppDelegate *appD = [NSApp delegate];
    NSString *identifier = [tableColumn identifier];
    NSDictionary *data = [appD.PDFLst objectAtIndex:row];
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
            AppDelegate *appD = [NSApp delegate];
            NSDictionary *data = [appD.PDFLst objectAtIndex:[mergePDFtable selectedRow]];
            NSFileManager *fileMgr = [NSFileManager defaultManager];
            NSString *fPath = [data objectForKey:@"fPath"];
            if ([fileMgr fileExistsAtPath:fPath]) {
                NSURL *url = [NSURL fileURLWithPath:fPath];
                PDFDocument *document = [[PDFDocument alloc]initWithURL:url];
                [_pdfView setDocument:document];
            } else {
                //テーブルのデータが実在しない場合
                [_pdfView setDocument:nil];
                NSRect rect = NSMakeRect(self.window.frame.origin.x + _pdfView.frame.origin.x + (_pdfView.frame.size.width - appD.statusWin.frame.size.width)*0.5, self.window.frame.origin.y + (self.window.frame.size.height - appD.statusWin.frame.size.height)*0.5, appD.statusWin.frame.size.width, appD.statusWin.frame.size.height);
                [appD showStatusWin:rect messageText:NSLocalizedString(@"PDF_READ_ERROR_MESSAGETEXT", @"PDF_READ_ERROR_MESSAGETEXT") infoText:NSLocalizedString(@"PDF_READ_ERROR_INFOTEXT", @"PDF_READ_ERROR_INFOTEXT")];
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
    AppDelegate *appD = [NSApp delegate];
    [appD.statusWin orderOut:self];
}

#pragma mark - Button Action

//コンボボックス・アクション/データ更新
- (IBAction)comboPageRange:(id)sender {
    AppDelegate *appD = [NSApp delegate];
    if ([sender indexOfSelectedItem] == 0) {
        [sender setStringValue:NSLocalizedString(@"ALL_PAGES", @"ALL_PAGES")];
        [self.window makeFirstResponder:nil];
        [sender setEditable:NO];
    } else if ([sender indexOfSelectedItem] == 1){
        [sender setStringValue:@""];
        [sender setEditable:YES];
        [self.window makeFirstResponder:sender];
    }
    NSInteger row = [mergePDFtable rowForView:sender];
    NSDictionary *data = [appD.PDFLst objectAtIndex:row];
    [data setValue:[sender stringValue] forKey:@"pageRange"];
    [appD.PDFLst replaceObjectAtIndex:row withObject:data];
}

//行追加
- (IBAction)btnAdd:(id)sender{
    [self.window makeFirstResponder:self];
    AppDelegate *appD = [NSApp delegate];
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    NSArray *fileTypes = [NSArray arrayWithObjects:@"pdf", nil];
    [openPanel setAllowedFileTypes:fileTypes];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            for (NSURL *url in [openPanel URLs]) {
                [self addToPDFLst:url atIndex:appD.PDFLst.count];
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
    AppDelegate *appD = [NSApp delegate];
    NSIndexSet *selectedRows = [mergePDFtable selectedRowIndexes];
    [appD.PDFLst removeObjectsAtIndexes:selectedRows];
    [mergePDFtable reloadData];
    [_pdfView setDocument:nil];
    [btnRemove setEnabled:NO];
    [self setEnabledButtons];
}

//テーブル・クリア
- (IBAction)btnClear:(id)sender {
    [window makeFirstResponder:self];
    AppDelegate *appD = [NSApp delegate];
    [appD.PDFLst removeAllObjects];
    [mergePDFtable reloadData];
    [btnRemove setEnabled:NO];
    [self setEnabledButtons];
}


- (IBAction)btnOpenData:(id)sender {
    [window makeFirstResponder:self];
    AppDelegate *appD = [NSApp delegate];
    appD.PDFLst = [NSMutableArray arrayWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"PDFLst" ofType:@"array"]];
    for (int i = 0; i < appD.PDFLst.count; i++) {
        NSMutableDictionary *data = [appD.PDFLst objectAtIndex:i];
        if ([langAllPages containsObject:[data objectForKey:@"pageRange"]]) {
            [data setObject:NSLocalizedString(@"ALL_PAGES", @"ALL_PAGES") forKey:@"pageRange"];
            [appD.PDFLst replaceObjectAtIndex:i withObject:data];
        }
    }
    [mergePDFtable reloadData];
    [self setEnabledButtons];
}

- (IBAction)btnSaveData:(id)sender {
    [window makeFirstResponder:self];
    AppDelegate *appD = [NSApp delegate];
    [appD.PDFLst writeToFile:[[NSBundle mainBundle] pathForResource:@"PDFLst" ofType: @"array"] atomically:YES];
    //終了ダイアログ表示
    NSRect rect = NSMakeRect(self.window.frame.origin.x + (mergePDFtable.frame.size.width - appD.statusWin.frame.size.width)*0.5, self.window.frame.origin.y + (self.window.frame.size.height - appD.statusWin.frame.size.height)*0.5, appD.statusWin.frame.size.width, appD.statusWin.frame.size.height);
    [appD showStatusWin:rect messageText:NSLocalizedString(@"SAVE_FILELIST_MESSAGETEXT", @"SAVE_FILELIST_MESSAGETEXT") infoText:NSLocalizedString(@"SAVE_FILELIST_INFOTEXT", @"SAVE_FILELIST_INFOTEXT")];
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
    AppDelegate *appD = [NSApp delegate];
    if (dragRows) {
        //テーブル内の行の移動
        NSUInteger index = [dragRows firstIndex];
        while(index != NSNotFound) {
            //ドロップ先にドラッグ元のオブジェクトを挿入する
            if (row > appD.PDFLst.count) {
                [appD.PDFLst addObject:[appD.PDFLst objectAtIndex:index]];
            }else{
                [appD.PDFLst insertObject:[appD.PDFLst objectAtIndex:index] atIndex:row];
            }
            //ドラッグ元のオブジェクトを削除する
            if (index > row) {
                //indexを後ろにずらす
                [appD.PDFLst removeObjectAtIndex:index + 1];
            }else{
                [appD.PDFLst removeObjectAtIndex:index];
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
        [appD.errLst removeAllObjects];
        for (id path in dropDataList) {
            NSString *uti = [workSpc typeOfFile:path error:nil];
            NSString *fName = [path lastPathComponent];
            if ([uti isEqualToString:@"com.adobe.pdf"]) {
                [self addToPDFLst:[NSURL fileURLWithPath:path] atIndex:row];
                row ++;
            } else {
                [appD.errLst addObject:fName];
            }
        }
    }
    [tv reloadData];
    [self setEnabledButtons];
    if (appD.errLst.count > 0) {
        [self showErrLst];
    }
    return YES;
}

//PDFファイル情報を配列に追加
- (void)addToPDFLst:(NSURL*)url atIndex:(NSInteger)row{
    AppDelegate *appD = [NSApp delegate];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSDictionary *fInfo = [NSDictionary dictionaryWithDictionary:[fileMgr attributesOfItemAtPath:[url path] error:nil]];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject:[url path] forKey:@"fPath"];
    [data setObject:[[url path]lastPathComponent] forKey:@"fName"];
    [data setObject:[fInfo objectForKey:NSFileSize] forKey:@"fSize"];
    [data setObject:NSLocalizedString(@"ALL_PAGES", @"ALL_PAGES") forKey:@"pageRange"];
    //PDF情報を取得
    PDFDocument *document = [[PDFDocument alloc]initWithURL:url];
    NSUInteger totalPage = [document pageCount];
    [data setObject:[NSNumber numberWithUnsignedInteger:totalPage] forKey:@"totalPage"];
    [appD.PDFLst insertObject:data atIndex:row];
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
    outputPDFPageIndex = 0;
    outputPDFTotalPg = 0;
    AppDelegate *appD = [NSApp delegate];
    //PDFLstの内容をチェック
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSMutableArray *indexes = [NSMutableArray array];
    for (NSDictionary *data in appD.PDFLst) {
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
    
    for (int i = 0; i < appD.PDFLst.count; i++){
        NSDictionary *data = [appD.PDFLst objectAtIndex:i];
        NSURL *url = [NSURL fileURLWithPath:[data objectForKey:@"fPath"]];
        PDFDocument *inputDoc = [[PDFDocument alloc]initWithURL:url];
        NSIndexSet *pageRange = [indexes objectAtIndex:i];
        NSUInteger index = [pageRange firstIndex];
        while(index != NSNotFound) {
            //PDFページ挿入終了ノーティフィケーションを送信
            outputPDFPageIndex++;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PDFDidEndPageInsert" object:self];
            
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

#pragma mark - notification

//ノーティフィケーションを受け取った時の動作
- (void)PDFDidBeginCreate:(NSNotification*)note {
    //プログレスバーのステータスを設定
    [progressBar setMaxValue:outputPDFTotalPg];
    [progressBar setDoubleValue: 0.0];
    //プログレス・パネルをシート表示
   [self.window beginSheet:progressWin completionHandler:^(NSInteger returnCode){}];
}

- (void)PDFDidEndPageInsert:(NSNotification*)note {
    //プログレスバーの値を更新
    [progressBar setDoubleValue:outputPDFPageIndex];
    [progressBar displayIfNeeded];
}

- (void)PDFDidEndCreate:(NSNotification*)note {
   //プログレス・パネルを終了させる
    [self.window endSheet:progressWin returnCode:0];
    //[progressWin orderOut:self];
}

//ノーティフィケーションを設定
- (void)setUpNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(PDFDidBeginCreate:) name:@"PDFDidBeginCreate" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(PDFDidEndPageInsert:) name:@"PDFDidEndPageInsert" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(PDFDidEndCreate:) name:@"PDFDidEndCreate" object:nil];
}

@end
