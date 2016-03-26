//
//  SplitPanel.m
//  Sao's PDF Kit
//
//  Created by 河野 さおり on 2016/03/26.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "SplitPanel.h"

@interface SplitPanel ()

@end

@implementation SplitPanel{
    IBOutlet NSMatrix *mtxSplitKind;
    IBOutlet NSTextField *txtPgRange;
    IBOutlet NSWindow *progressWin;
    IBOutlet NSProgressIndicator *progressBar;
    NSString *saveFolder;
    NSString *savePath;
    double PDFCount;
}

#pragma mark - initialize

- (void)windowDidLoad {
    [super windowDidLoad];
    saveFolder = nil;
    [self setUpNotification];
}

#pragma mark - set up notification
- (IBAction)test:(id)sender {
}

- (void)setUpNotification{
    //PDF作成開始
    [[NSNotificationCenter defaultCenter] addObserverForName:@"PDFDidBeginCreate" object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        //プログレスバーのステータスを設定
        [progressBar setMaxValue:PDFCount];
        [progressBar setDoubleValue: 0.0];
        //プログレス・パネルをシート表示
        [self.window beginSheet:progressWin completionHandler:^(NSInteger returnCode){}];
    }];
    //PDF作成過程
    [[NSNotificationCenter defaultCenter] addObserverForName:@"PDFDidEndPageInsert" object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        //プログレスバーの値を更新
        NSNumber *page = [[notif userInfo] objectForKey:@"page"];
        [progressBar setDoubleValue:page.doubleValue];
        [progressBar displayIfNeeded];
    }];
    //PDF作成完了
    [[NSNotificationCenter defaultCenter] addObserverForName:@"PDFDidEndCreate" object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        //プログレス・パネルを終了させる
        [self.window endSheet:progressWin returnCode:0];
    }];
}

- (IBAction)mtxSplitKind:(id)sender {
    switch ([sender selectedRow]) {
        case 0:
            [txtPgRange setEnabled:YES];
            [self.window makeFirstResponder:txtPgRange];
            break;
        case 1:
            [txtPgRange setEnabled:NO];
            break;
    }
}

- (IBAction)splitPDF:(id)sender {
    MyWindowController *docWinC = self.window.sheetParent.windowController;
    PDFDocument *inputDoc = [[docWinC._pdfView document]copy];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    //保存先のパスを作成
    if (!saveFolder) {
        saveFolder = [[docWinC.document fileURL].path stringByDeletingLastPathComponent];
    }
    NSString *fName = [[docWinC.document fileURL].path.lastPathComponent stringByDeletingPathExtension];
    switch (mtxSplitKind.selectedRow) {
        case 0:{ //指定ページを抽出
            //ページ範囲をインデックス・セットに変換
            NSString *indexStr = txtPgRange.stringValue;
            NSMutableIndexSet *pageRange = [NSMutableIndexSet indexSet];
            NSUInteger totalPage = inputDoc.pageCount;
            //入力の有無をチェック
            if ([indexStr isEqualToString:@""]) {
                [self showPageRangeAllert:NSLocalizedString(@"PageEmpty",@"")];
                return;
            }
            //入力値に不正な文字列が含まれないかチェック
            NSCharacterSet *pgRangeChrSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789,-"];
            NSCharacterSet *inputChrSet = [NSCharacterSet characterSetWithCharactersInString:indexStr];
            if (! [pgRangeChrSet isSupersetOfSet:inputChrSet]) {
                [self showPageRangeAllert:NSLocalizedString(@"CharError",@"")];
                return;
            }
            //入力値をカンマで分割
            NSArray *ranges = [indexStr componentsSeparatedByString:@","];
            for (NSString *range in ranges) {
                //インデクス指定文字列を"-"で分割
                NSArray *pages = [range componentsSeparatedByString:@"-"];
                if (pages.count > 2) {
                    //"-"が2つ以上含まれる場合
                    [self showPageRangeAllert:NSLocalizedString(@"PageRangeInfo",@"")];
                    return;
                } else if (pages.count == 1) {
                    //"-"が含まれない場合
                    if ([range integerValue] <= totalPage && [range integerValue] > 0) {
                        [pageRange addIndex:[range integerValue]];
                    } else {
                        [self showPageRangeAllert:NSLocalizedString(@"PageRangeInfo",@"")];
                        return;
                    }
                } else if ([[pages objectAtIndex:0]isEqualToString:@""]) {
                    //"-"が先頭にある場合
                    [pageRange addIndexesInRange:NSMakeRange(1,[[pages objectAtIndex:1]integerValue])];
                } else if ([[pages objectAtIndex:1]isEqualToString:@""]) {
                    //"-"が末尾にある場合
                    if ([[pages objectAtIndex:0]integerValue] > totalPage) {
                        [self showPageRangeAllert:NSLocalizedString(@"PageRangeInfo",@"")];
                        return;
                    } else {
                        [pageRange addIndexes:[self indexFrom1stIndex:[[pages objectAtIndex:0]integerValue] toLastIndex:totalPage]];
                    }
                } else {
                    //通常の範囲指定
                    if ([[pages objectAtIndex:0]integerValue] < 1 || [[pages objectAtIndex:0]integerValue] > totalPage || [[pages objectAtIndex:0]integerValue] > [[pages objectAtIndex:1]integerValue]) {
                        [self showPageRangeAllert:NSLocalizedString(@"PageRangeInfo",@"")];
                        return;
                    } else {
                        [pageRange addIndexes:[self indexFrom1stIndex:[[pages objectAtIndex:0]integerValue] toLastIndex:[[pages objectAtIndex:1]integerValue]]];
                    }
                }
            }
            //出力PDFと保存先のパスを作成
            PDFDocument *outputDoc = [[PDFDocument alloc]init];
            savePath = [NSString stringWithFormat:@"%@/%@(%@).pdf",saveFolder,fName,indexStr];
            if ([fileMgr fileExistsAtPath:savePath]) {
                //同名ファイルが存在した場合
                NSInteger result = [self showFileExistsAllert];
                if (result == 1000) {
                    saveFolder = nil;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"PDFDidEndCreate" object:self];
                    return;
                }
            }
            //抽出処理開始
            //PDF作成開始ノーティフィケーションを送信
            PDFCount = pageRange.count;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PDFDidBeginCreate" object:self];

            NSUInteger index = [pageRange firstIndex];
            int indexCount = 0;
            while(index != NSNotFound) {
                PDFCount = pageRange.count;
                //PDF作成過程ノーティフィケーションを送信
                [[NSNotificationCenter defaultCenter] postNotificationName:@"PDFDidEndPageInsert" object:self userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:indexCount] forKey:@"page"]];
                [outputDoc insertPage:[inputDoc pageAtIndex:index-1] atIndex:outputDoc.pageCount];
                indexCount++;
                index = [pageRange indexGreaterThanIndex:index];
            }
            [outputDoc writeToFile:savePath];
            //PDF作成終了ノーティフィケーションを送信
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PDFDidEndCreate" object:self];
        }
            break;
            
        case 1:{ //単ページに分割
            //PDF作成開始ノーティフィケーションを送信
            PDFCount = inputDoc.pageCount;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PDFDidBeginCreate" object:self];

            for (int i = 0; i < PDFCount; i++) {
                //PDFページ作成過程ノーティフィケーションを送信
                [[NSNotificationCenter defaultCenter] postNotificationName:@"PDFDidEndPageInsert" object:self userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:i] forKey:@"page"]];
                //出力PDFと保存先のパスを作成
                PDFDocument *outputDoc = [[PDFDocument alloc]init];
                [outputDoc insertPage:[inputDoc pageAtIndex:i] atIndex:0];
                savePath = [NSString stringWithFormat:@"%@/%@(%i).pdf",saveFolder,fName,i+1];
                if ([fileMgr fileExistsAtPath:savePath]) {
                    //同名ファイルが存在した場合
                    NSInteger result = [self showFileExistsAllert];
                    if (result == 1000) {
                        saveFolder = nil;
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"PDFDidEndCreate" object:self];
                        return;
                    }
                }
                [outputDoc writeToFile:savePath];
            }
            //PDF作成終了ノーティフィケーションを送信
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PDFDidEndCreate" object:self];
        }
            break;
    }
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}

- (NSInteger)showPageRangeAllert:(NSString*)infoTxt{
    NSAlert *alert = [[NSAlert alloc]init];
    alert.messageText = NSLocalizedString(@"PageRangeMsg",@"");
    [alert setInformativeText:infoTxt];
    [alert addButtonWithTitle:NSLocalizedString(@"OK",@"")];
    [alert setAlertStyle:NSCriticalAlertStyle];
    return [alert runModalSheetForWindow:self.window];
}

- (NSInteger)showFileExistsAllert{
    NSAlert *alert = [[NSAlert alloc]init];
    alert.messageText = [NSString stringWithFormat:@"\"%@\" %@",savePath.lastPathComponent,NSLocalizedString(@"fileNameAlertMsg",@"")];
    [alert setInformativeText:NSLocalizedString(@"fileNameAlertInfo",@"")];
    [alert addButtonWithTitle:NSLocalizedString(@"Suspend",@"")];
    [alert addButtonWithTitle:NSLocalizedString(@"Replace",@"")];
    [alert setAlertStyle:NSCriticalAlertStyle];
    return [alert runModalSheetForWindow:[self.window.sheets objectAtIndex:0]
            ];
}

//最初と最後のインデクスを指定してインデクスセットを作成
- (NSMutableIndexSet *)indexFrom1stIndex:(NSUInteger)firstIndex toLastIndex:(NSUInteger)lastIndex{
    NSMutableIndexSet *indexset = [NSMutableIndexSet indexSet];
    for (NSUInteger i = firstIndex; i <= lastIndex; i++) {
        [indexset addIndex:i];
    }
    return indexset;
}

- (IBAction)pshSaveTo:(id)sender {
    NSOpenPanel *openpanel = [NSOpenPanel openPanel];
    //openPanelのパラメータを設定
    [openpanel setCanChooseFiles:NO]; //ファイルの選択の可否
    [openpanel setCanChooseDirectories:YES]; //ディレクトリの選択の可否
    [openpanel setCanCreateDirectories:YES]; //フォルダ作成ボタンの有無
    [openpanel setPrompt:NSLocalizedString(@"Choose", @"")]; //ボタンのタイトル
    [openpanel setMessage:NSLocalizedString(@"ChooseFolder", @"")]; //表示するメッセージテキスト
    [openpanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            saveFolder = openpanel.URL.path;
        }
    }];
}

- (IBAction)pshCancel:(id)sender {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

@end
