//
//  TxtPanel.m
//  Sao's PDF Kit
//
//  Created by 河野 さおり on 2016/04/02.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "TxtPanel.h"

#define APPD (AppDelegate *)[NSApp delegate]

@interface TxtPanel ()

@end

@implementation TxtPanel{
    IBOutlet NSTextView *_txtView;
    IBOutlet NSTextField *txtPgRange;
    IBOutlet NSPopUpButton *popTarget;
    NSString *saveFolder;
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

- (void)clearTxt{
    [_txtView setString:@""];
    [popTarget selectItemAtIndex:0];
    [self popTarget:popTarget];
    saveFolder = nil;
}

- (IBAction)popTarget:(id)sender {
    if ([sender indexOfSelectedItem] == 1) {
        [txtPgRange setEnabled:YES];
        [self.window makeFirstResponder:txtPgRange];
    } else {
        [txtPgRange setStringValue:@""];
        [txtPgRange setEnabled:NO];
    }
}

- (IBAction)getTxt:(id)sender {
    MyWinC *winC = [self currentWinC];
    PDFDocument *doc = winC._pdfView.document;
    if ([popTarget indexOfSelectedItem] == 1) {
        //ページ範囲をインデックス・セットに変換
        NSString *indexStr = txtPgRange.stringValue;
        NSMutableIndexSet *pageRange = [NSMutableIndexSet indexSet];
        NSUInteger totalPage = doc.pageCount;
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
                if ([[pages objectAtIndex:1]integerValue] > totalPage || [[pages objectAtIndex:0]integerValue] < 1) {
                    [self showPageRangeAllert:NSLocalizedString(@"PageRangeInfo",@"")];
                    return;
                } else {
                    [pageRange addIndexesInRange:NSMakeRange(1,[[pages objectAtIndex:1]integerValue])];
                }
            } else if ([[pages objectAtIndex:1]isEqualToString:@""]) {
                //"-"が末尾にある場合
                if ([[pages objectAtIndex:0]integerValue] > totalPage || [[pages objectAtIndex:0]integerValue] < 1) {
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
        NSUInteger index = [pageRange firstIndex];
        NSMutableAttributedString *aStr = [[NSMutableAttributedString alloc]init];
        while(index != NSNotFound) {
            PDFPage *page = [doc pageAtIndex:index-1];
            [aStr appendAttributedString:page.attributedString];
            index = [pageRange indexGreaterThanIndex:index];
        }
        [_txtView.textStorage setAttributedString:aStr];
    } else {
        PDFSelection *sel;
        if (popTarget.indexOfSelectedItem == 0) {
            sel = [doc selectionForEntireDocument];
        } else {
            sel = winC._pdfView.currentSelection;
            if (!sel && (APPD).isSelection) {
                sel = [winC._pdfView.targetPg selectionForRect:winC._pdfView.selRect];
            }
        }
        if (sel){
            [_txtView.textStorage setAttributedString:sel.attributedString];
        } else {
            [_txtView setString:@""];
        }
        sel = nil;
    }
}

- (NSInteger)showPageRangeAllert:(NSString*)infoTxt{
    NSAlert *alert = [[NSAlert alloc]init];
    alert.messageText = NSLocalizedString(@"PageRangeMsg",@"");
    [alert setInformativeText:infoTxt];
    [alert addButtonWithTitle:@"OK"];
    [alert setAlertStyle:NSCriticalAlertStyle];
    return [alert runModalSheetForWindow:self.window];
}

//最初と最後のインデクスを指定してインデクスセットを作成
- (NSMutableIndexSet *)indexFrom1stIndex:(NSUInteger)firstIndex toLastIndex:(NSUInteger)lastIndex{
    NSMutableIndexSet *indexset = [NSMutableIndexSet indexSet];
    for (NSUInteger i = firstIndex; i <= lastIndex; i++) {
        [indexset addIndex:i];
    }
    return indexset;
}

- (IBAction)saveTo:(id)sender {
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

- (IBAction)exportAsRichTxt:(id)sender {
    NSString *savePath = [self createSavePath:@"rtf"];
    NSAttributedString *aStr = _txtView.textStorage;
    NSData *data = [aStr dataFromRange:(NSRange){0, [aStr length]} documentAttributes:@{NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType} error:NULL];
    [data writeToFile:savePath atomically:YES];
    
}

- (IBAction)exportAsPlainTxt:(id)sender {
    NSString *savePath = [self createSavePath:@"txt"];
    NSString *expStr = [[_txtView.textStorage attributedSubstringFromRange:NSMakeRange(0, _txtView.textStorage.length)] string];
    [expStr writeToFile:savePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (NSString*)createSavePath:(NSString*)ext{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    MyWinC *winC = [self currentWinC];
    if (!saveFolder) {
        saveFolder = [[winC.document fileURL].path stringByDeletingLastPathComponent];
    }
    NSString *fName = [[winC.document fileURL].path.lastPathComponent stringByDeletingPathExtension];
    NSString *savePath = [NSString stringWithFormat:@"%@/%@_text.%@",saveFolder,fName,ext];
    int i = 1;
    while ([fileMgr fileExistsAtPath:savePath]) {
        savePath = [NSString stringWithFormat:@"%@/%@_text %i.%@",saveFolder,fName,i,ext];
        i++;
    }
    return savePath;
}

- (MyWinC*)currentWinC{
    NSDocumentController *docC = [NSDocumentController sharedDocumentController];
    return [[docC currentDocument].windowControllers objectAtIndex:0];
}

@end
