//
//  OLController.m
//  Sao's PDF Kit
//
//  Created by 河野 さおり on 2016/03/10.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "OLController.h"
#import "AppDelegate.h"

#define APPD (AppDelegate *)[NSApp delegate]
#define MyPBoardType @"MyPBoardType"

@implementation OLController{
    IBOutlet MYOLView *_olView;
    IBOutlet MyPDFView *_pdfView;
    IBOutlet NSSegmentedControl *segOLViewMode;
    NSArray *dragOLArray; //ドラッグ中のしおりデータを保持
    NSMutableIndexSet *oldIndexes; //ドラッグ元の行インデクスを保持
    BOOL bRowClicked; //アウトラインの行がユーザに選択されたか
}

-(void)awakeFromNib{
    //ドラッグ＆ドロップするデータタイプを設定
    [_olView registerForDraggedTypes:[NSArray arrayWithObjects:MyPBoardType, nil]];
    [_olView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
}

//現在のドキュメントのウインドウコントローラを返す
- (MyWindowController*)currentDocWinController{
    NSDocumentController *docC = [NSDocumentController sharedDocumentController];
    NSDocument *doc = [docC currentDocument];
    return [doc.windowControllers objectAtIndex:0];
}

#pragma mark - outlineView data source

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item{
    if (! item) {
        return [[[_pdfView document] outlineRoot]numberOfChildren];
    } else {
        return [(PDFOutline *)item numberOfChildren];
    }
}

- (id)outlineView: (NSOutlineView *) outlineView child: (NSInteger) index ofItem: (id) item{
    if (! item) {
        //ルートの場合はPDFOutlineを取得
        return [[[_pdfView document]outlineRoot] childAtIndex:index];
    } else {
        return [(PDFOutline *)item childAtIndex:index];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item{
    if (! item) {
        return ([[[_pdfView document]outlineRoot] numberOfChildren] > 0);
    } else {
        return ([(PDFOutline *)item numberOfChildren] > 0);
    }
}

- (NSView *)outlineView:(NSOutlineView *)olView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item{
    NSString *identifier = tableColumn.identifier;
    NSTableCellView *view = [olView makeViewWithIdentifier:identifier owner:self];
    if ([identifier isEqualToString:@"label"]){
        view.textField.stringValue = [item label];
        if (segOLViewMode.selectedSegment == 1) {
            [view.textField setEditable:YES];
        } else {
            [view.textField setEditable:NO];
        }
    } else {
        PDFDocument *doc = [_pdfView document];
        PDFPage *page = [[item destination]page];
        NSString *pageStr;
        if (page.label){
            pageStr = page.label;
        } else {
            pageStr = [NSString stringWithFormat:@"%li",[doc indexForPage:page]+1];
        }
        view.textField.stringValue = pageStr;
    }
    return view;
}

//更新の受付
- (IBAction)labelUpdated:(id)sender {
    PDFOutline *ol = (PDFOutline*)[_olView itemAtRow:[_olView rowForView:sender]];
    [ol setLabel:[sender stringValue]];
    [[self currentDocWinController].document updateChangeCount:NSChangeDone];
}

#pragma mark - drag and drop controll

// ドラッグ開始（ペーストボードに書き込む）
- (BOOL)outlineView:(NSOutlineView *)ov writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard{
    [pboard setData:[NSData data] forType:MyPBoardType];
    dragOLArray = [NSMutableArray arrayWithArray:items];
    oldIndexes = [[NSMutableIndexSet alloc]init];
    for (id item in items) {
        [oldIndexes addIndex:[_olView rowForItem:item]];
    }
    return YES;
}

//ドロップを確認
- (NSDragOperation)outlineView:(NSOutlineView *)ov validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index{
    PDFOutline *targetOL = item;
    NSDragOperation result = NSDragOperationGeneric;
    [info setAnimatesToDestination:YES];
    if (item) {
        //ドロップ先が自分か自分の子孫であればドロップ不可
        for (PDFOutline *draggedOL in dragOLArray){
            if ([self targetOL:targetOL isDescendant:draggedOL]){
                result = NSDragOperationNone;
                break;
            }
        }
    }
    return result;
}

//ドロップ先が自分を含むそれ以下の階層であれば真を返す
- (BOOL)targetOL:(PDFOutline*)ol isDescendant:(PDFOutline*)parentOL{
    while (ol != nil) {
        if (ol == parentOL) {
            return YES;
        }
        ol = ol.parent;
    }
    return NO;
}

//ドロップ受付開始
- (BOOL)outlineView:(NSOutlineView*)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index{
    PDFOutline *targetOL = item; //ドロップ先のしおり
    if (!item){
        //ルートへのドロップ
        targetOL = _pdfView.document.outlineRoot;
    }
    if (index == -1){
        //しおり上へのドロップの場合、しおりの子の末尾に入れる
        index = [targetOL numberOfChildren];
    }
    NSInteger targetIndex = [_olView rowForItem:targetOL]+index+1;
    NSInteger oldIndex = oldIndexes.lastIndex;
    NSInteger i = dragOLArray.count-1;
    while (oldIndex != NSNotFound) {
        PDFOutline *oldOL = [_olView itemAtRow:oldIndex];
        if (oldIndex < targetIndex && targetOL == oldOL.parent){
            //同じ親の中の下への移動（ドロップ先のインデクスが上にずれる）
            index --;
            targetIndex --;
        }
        //ペースト元のしおりを削除
        [oldOL removeFromParent];
        [_olView reloadData];
        //ドロップ先にペーストボードアイテムを挿入
        [targetOL insertChild:[dragOLArray objectAtIndex:i] atIndex:index];
        [_olView reloadData];
        if (oldIndex > targetIndex) {
            //上への移動の場合（ドロップ元のインデクスが下にずれる）
            [oldIndexes shiftIndexesStartingAtIndex:targetIndex by:1];
            oldIndex ++;
        }
        oldIndex = [oldIndexes indexLessThanIndex:oldIndex];
        i--;
    }
    [[self currentDocWinController].document updateChangeCount:NSChangeDone];
    return YES;
}

@end

