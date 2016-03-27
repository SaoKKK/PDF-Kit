//
//  RemovePanel.m
//  Sao's PDF Kit
//
//  Created by 河野 さおり on 2016/03/26.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "RemovePanel.h"

@interface RemovePanel ()

@end

@implementation RemovePanel{
    IBOutlet NSTextField *txtPgRange;
    PDFDocument *doc;
    NSUInteger index;
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

- (IBAction)pshRemove:(id)sender {
    MyWindowController *docWinC = self.window.sheetParent.windowController;
    doc = [docWinC._pdfView document];
    NSUInteger totalPage = doc.pageCount;
    //ページ範囲をインデックス・セットに変換
    NSString *indexStr = txtPgRange.stringValue;
    NSMutableIndexSet *pageRange = [NSMutableIndexSet indexSet];
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
    //全ページが指定された場合
    if (pageRange.count == doc.pageCount) {
        [self showPageRangeAllert:NSLocalizedString(@"AllPages",@"")];
        return;
    }
    //削除開始
    [docWinC.thumbView setPDFView:nil]; //インデクスリセットのため一度切り離す
    index = [pageRange lastIndex];
    while(index != NSNotFound) {
        //しおりがある場合はインデクスを修正
        if (doc.outlineRoot) {
            [self getAllChildren:doc.outlineRoot];
        }
        [doc removePageAtIndex:index-1];
        index = [pageRange indexLessThanIndex:index];
    }
    [docWinC.thumbView setPDFView:docWinC._pdfView];
    [docWinC._pdfView layoutDocumentView]; //ビューのスクロールサイズをリセット
    [docWinC._olView reloadData];
    [docWinC._olView expandItem:nil expandChildren:YES];
    [docWinC updateDocInfo];
    [docWinC.document updateChangeCount:NSChangeDone];
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}

//すべてのアウトラインを走査
- (void)getAllChildren:(PDFOutline*)parentOL{
    [self resetOLPage:parentOL];
    for (int i = 0; i < parentOL.numberOfChildren; i++){
        [self getAllChildren:[parentOL childAtIndex:i]];
    }
}

//移動先に消えるページが設定されていた場合は移動先をリセット（インデクス0にジャンプするように）
- (void)resetOLPage:(PDFOutline*)ol{
    PDFDestination *dest = ol.destination;
    NSUInteger pageIndex = [doc indexForPage:dest.page];
    if (pageIndex == index-1) {
        PDFPage *page = [doc pageAtIndex:0];
        NSRect rect = [page boundsForBox:kPDFDisplayBoxArtBox];
        dest = [[PDFDestination alloc]initWithPage:page atPoint:NSMakePoint(0, rect.size.height)];
        [ol setDestination:dest];
    }
}

- (NSInteger)showPageRangeAllert:(NSString*)infoTxt{
    NSAlert *alert = [[NSAlert alloc]init];
    alert.messageText = NSLocalizedString(@"PageRangeMsg",@"");
    [alert setInformativeText:infoTxt];
    [alert addButtonWithTitle:NSLocalizedString(@"OK",@"")];
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

- (IBAction)pshCancel:(id)sender {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

@end
