//
//  OLController.m
//  Sao's PDF Kit
//
//  Created by 河野 さおり on 2016/03/10.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "OLController.h"

@implementation OLController{
    IBOutlet NSOutlineView *_olView;
    IBOutlet MyPDFView *_pdfView;
}

- (void)awakeFromNib{
    //ページ移動ノーティフィケーションを設定
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pageChanged) name:PDFViewPageChangedNotification object:_pdfView];
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
    } else {
        PDFDocument *doc = [_pdfView document];
        PDFPage *page = [[item destination]page];
        NSString *pageStr;
        if (page.label){
            pageStr = page.label;
        } else {
            [NSString stringWithFormat:@"%li",[doc indexForPage:page]+1];
        }
        view.textField.stringValue = pageStr;
    }
    return view;
}

//更新の受付
- (IBAction)labelUpdated:(id)sender {
    PDFOutline *ol = (PDFOutline*)[_olView itemAtRow:[_olView rowForView:sender]];
    [ol setLabel:[sender stringValue]];
}


#pragma mark - navigate between the destinations

//行選択アクション
- (IBAction)takeDestination:(id)sender {
    [_pdfView goToDestination:[[sender itemAtRow:[sender selectedRow]]destination]];
}

//ページ移動時
- (void) pageChanged{
    if (![[_pdfView document] outlineRoot])
        return;
    //現在のページインデクスを取得
    NSUInteger newPageIndex = [[_pdfView document] indexForPage:[_pdfView currentPage]];
    //アウトラインを走査してページをチェック
    NSInteger newRow;
    for (int i = 0; i < [_olView numberOfRows]; i++){
        PDFOutline  *ol;
        //PDFアウトラインのページを取得
        ol = (PDFOutline *)[_olView itemAtRow: i];
        if ([[_pdfView document] indexForPage:[[ol destination] page]] == newPageIndex){
            //現在のページとPDFアウトラインのページが一致した場合
            newRow = i;
            break;
        } else if ([[_pdfView document] indexForPage:[[ol destination] page]] > newPageIndex){
            //現在のページよりPDFアウトラインのページが後ろの場合
            newRow = i - 1;
            break;
        }
    }
    //該当行を選択
    if (newRow >= 0){
        [_olView selectRowIndexes:[NSIndexSet indexSetWithIndex:newRow] byExtendingSelection:NO];
    }
}

//コンテナ開閉で選択行を移行
- (void)outlineViewItemDidExpand:(NSNotification *)notification{
    [self pageChanged];
}
- (void)outlineViewItemDidCollapse:(NSNotification *)notification{
    [self pageChanged];
}

@end

