//
//  MyWinC.m
//  Sao's PDF Kit
//
//  Created by 河野 さおり on 2016/02/19.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "MyWinC.h"
#import "Document.h"
#import "MyPDFView.h"
#import "AppDelegate.h"
#import "OLController.h"

#define kMinTocAreaSplit	200.0f
#define APPD (AppDelegate *)[NSApp delegate]

@interface MyWinC ()

@end

@implementation MyWinC

@synthesize _pdfView,thumbView,_expPanel,_splitPanel,_removePanel,_olView,segTool;

#pragma mark - initialize window

- (void)windowDidLoad {
    [super windowDidLoad];
    //ファイルから読み込まれたPDFドキュメントをビューに表示
    docURL = [[self document] fileURL];
    PDFDocument *doc = [[PDFDocument alloc]initWithURL:docURL];
    [_pdfView setDocument:doc];
    [self initWindow];
}

- (void)initWindow{
    //インスタンス変数を初期化
    selectedViewMode = 0;
    bFullscreen = NO;
    //ノーティフィケーションを設定
    [self setupNotification];
    //デリゲートを設定
    [[_pdfView document] setDelegate: self];
    //オート・スケールをオフにする
    [_pdfView setAutoScales:NO];
    //ドキュメント情報を更新
    [self updateDocInfo];
    //ページ表示テキストフィールドの値を変更
    [self updateTxtPg];
    //サムネイルビューの設定
    [thumbView setAllowsMultipleSelection:YES];
    //アウトラインルートがあるかどうかチェック
    if ([self isOLExists]) {
        //アウトラインビューのデータを読み込み
        [_olView reloadData];
        [_olView expandItem:nil expandChildren:YES];
        //目次エリアの初期表示をアウトラインに変更
        if (_pdfView.document.outlineRoot.numberOfChildren) {
            [segTabTocSelect setSelected:YES forSegment:1];
            [self segSelContentsView:segTabTocSelect];
        }
    }
    //検索結果保持用配列を初期化
    searchResult = [NSMutableArray array];
    
}

//アウトライン情報があるかどうかを返す
- (BOOL)isOLExists{
    if ([[_pdfView document]outlineRoot]) {
        return YES;
    } else {
        return NO;
    }
}

//ドキュメント情報を更新
- (void)updateDocInfo{
    PDFDocument *doc = [_pdfView document];
    [(APPD).olInfo setObject:[NSNumber numberWithFloat:doc.pageCount] forKey:@"totalPage"];
    [(APPD).olInfo setObject:[NSNumber numberWithFloat:doc.pageCount-1] forKey:@"lastIndex"];
}

#pragma mark - document save/open support

- (void)revertDocumentToSaved{
    PDFDocument *doc = [[PDFDocument alloc]initWithURL:docURL];
    [_pdfView setDocument:doc];
    [_olView reloadData];
    [_olView expandItem:nil expandChildren:YES];
}

#pragma mark - setup notification

- (void)setupNotification{
    //ドキュメントが更新された
    [[NSNotificationCenter defaultCenter] addObserverForName:NSUndoManagerCheckpointNotification object:[self undoManager] queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        //ドキュメント情報を更新
        [self updateDocInfo];
    }];
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
    //メインウインドウ変更
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeMainNotification object:self.window queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        (APPD).isWinExist = YES;
        (APPD).isDocWinMain = YES;
        (APPD).isOLExists = [self isOLExists];
        [self updateSelectedRowInfo];
        if (_pdfView.currentSelection || _pdfView.selRect.size.width != 0 || _pdfView.selRect.size.height  != 0) {
            (APPD).isSelection = YES;
        } else {
            (APPD).isSelection = NO;
        }
        //ページ移動メニューの有効/無効の切り替え
        [self updateGoButtonEnabled];
        //倍率変更メニューの有効／無効の切り替え
        [self updateSizingBtnEnabled];
        //ディスプレイ・モード変更メニューのステータス変更
        [self updateDisplayModeMenuStatus];
        //スクリーンモード変更メニューのタイトルを変更
        [self mnFullScreenSetTitle];
    }];
    //ウインドウが閉じられた
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification object:self.window queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        NSDocumentController *docCtr = [NSDocumentController sharedDocumentController];
        if (docCtr.documents.count == 1) {
            (APPD).isWinExist = NO;
            (APPD).isDocWinMain = NO;
            (APPD).isSelection = NO;
            (APPD).isOLExists = NO;
            (APPD).isOLSelectedSingle = NO;
            (APPD).isOLSelected = NO;
        }
    }];
    //ページ移動
    [[NSNotificationCenter defaultCenter] addObserverForName:PDFViewPageChangedNotification object:_pdfView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        //ページ移動ボタンの有効/無効の切り替え
        [self updateGoButtonEnabled];
        //ページ表示テキストフィールドの値を変更
        [self updateTxtPg];
        //アウトラインビューの選択行変更
        [self pageChanged];
    }];
    //表示倍率変更
    [[NSNotificationCenter defaultCenter]addObserverForName:PDFViewScaleChangedNotification object:_pdfView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        //倍率変更ボタン／メニューの有効／無効の切り替え
        [self updateSizingBtnEnabled];
    }];
    //ディスプレイモード変更
    [[NSNotificationCenter defaultCenter]addObserverForName:PDFViewDisplayBoxChangedNotification object:_pdfView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        //ディスプレイ・モード変更メニューのステータス変更
        [self updateDisplayModeMenuStatus];
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

- (void) updateTxtPg {
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

//倍率変更ボタン／メニューの有効／無効の切り替え
- (void)updateSizingBtnEnabled{
    if (_pdfView.scaleFactor < 5.0) {
        [segZoom setEnabled:YES forSegment:0];
        [[APPD mnZoomIn]setEnabled:YES];
    } else {
        [segZoom setEnabled:NO forSegment:0];
        [[APPD mnZoomIn]setEnabled:NO];
    }
    if (_pdfView.canZoomOut) {
        [segZoom setEnabled:YES forSegment:1];
        [[APPD mnZoomOut]setEnabled:YES];
    } else {
        [segZoom setEnabled:NO forSegment:1];
        [[APPD mnZoomOut]setEnabled:NO];
    }
}

//ディスプレイ・モード変更ボタン／メニューのステータス変更
- (void)updateDisplayModeMenuStatus{
    [APPD setMnPageDisplayState:[matrixDisplayMode selectedColumn]];
}

//スクリーンモード変更メニューのタイトルを変更
- (void)mnFullScreenSetTitle{
    if (bFullscreen) {
        [[APPD mnFullScreen]setTitle:NSLocalizedString(@"MnTitleExitFullScreen", @"")];
    } else {
        [[APPD mnFullScreen]setTitle:NSLocalizedString(@"MnTitleEnterFullScreen", @"")];
    }
}

#pragma mark - make new document

- (void)makeNewDocWithPDF:(PDFDocument*)pdf{
    [_pdfView setAutoScales:YES];
    [_pdfView setDocument:pdf];
    [self initWindow];
    [self.document updateChangeCount:NSChangeDone];
}

#pragma mark - search in document

- (IBAction)searchField:(id)sender {
    NSString *searchString = [sender stringValue];
    if ([searchString isEqualToString:@""]) {
        //目次エリアの表示を元に戻す
        [self segSelContentsView:segTabTocSelect];
        return;
    }
    //検索実行
    PDFDocument *doc = [_pdfView document];
    [doc beginFindString:searchString withOptions:NSCaseInsensitiveSearch];
    [tabToc selectTabViewItemAtIndex:2];
    [segOLViewMode setSelectedSegment:1];
}

- (void)documentDidEndDocumentFind:(NSNotification *)notification{
    //検索結果を表示
    [[[_tbView.tableColumns objectAtIndex:1]headerCell] setTitle:[NSString stringWithFormat:@"%@%li",NSLocalizedString(@"RESULT", @""),searchResult.count]];
    [_tbView reloadData];
}

- (void)didMatchString:(PDFSelection *)instance{
    //元の選択領域を保持
    PDFSelection *sel = instance.copy;
    //テーブルの結果列の項目作成
    [instance extendSelectionAtStart:10];
    [instance extendSelectionAtEnd:10];
    NSString *labelString = [self stringByRemoveLine:instance.string];
    labelString = [NSString stringWithFormat:@"...%@...",labelString];
    //テーブルのページ列の項目作成
    PDFPage *page = [[instance pages]objectAtIndex:0];
    NSString *pageLabel = page.label;
    
    //検索結果を作成
    NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:sel,@"selection",labelString,@"result",pageLabel,@"page",nil];
    [searchResult addObject:result];
}

//改行を削除した文字列を返す
- (NSString*)stringByRemoveLine:(NSString*)string{
    NSMutableArray *lines = [NSMutableArray array];
    [string enumerateLinesUsingBlock:^(NSString *line,BOOL *stop){
        [lines addObject:line];
    }];
    NSString *newStr = [lines componentsJoinedByString:@" "];
    return newStr;
}

- (void)documentDidBeginDocumentFind:(NSNotification *)notification{
    [searchResult removeAllObjects];
    [_tbView reloadData];
}

#pragma mark - table view data source and delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return searchResult.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    NSString *identifier = tableColumn.identifier;
    NSDictionary *result = [searchResult objectAtIndex:row];
    NSTableCellView *view = [tableView makeViewWithIdentifier:identifier owner:self];
    if ([identifier isEqualToString:@"page"]){
        view.textField.stringValue = [result objectForKey:identifier];
    } else {
        NSMutableAttributedString *labelTxt = [[NSMutableAttributedString alloc]initWithString:[result objectForKey:identifier]];
        NSDictionary *attr = @{NSFontAttributeName:[NSFont systemFontOfSize:11 weight:NSFontWeightBold]};
        NSRange range = [[result objectForKey:identifier] rangeOfString:searchField.stringValue options:NSCaseInsensitiveSearch];
        [labelTxt setAttributes:attr range:range];
        [view.textField setAttributedStringValue:labelTxt];
    }
    return view;
}

//行選択時
- (void)tableViewSelectionDidChange:(NSNotification *)notification{
    //選択行を取得
    NSInteger row = [_tbView selectedRow];
    if (row != -1){
        //選択領域を取得
        PDFSelection *sel = [[searchResult objectAtIndex:row] objectForKey:@"selection"];
        //選択領域を表示
        [sel setColor:[NSColor yellowColor]];
        [_pdfView setCurrentSelection:sel animate:YES];
        [_pdfView scrollSelectionToVisible:self];
    }
}
#pragma mark - navigate between the destinations

//選択行変更時
- (IBAction)outlineViewRowClicked:(id)sender{
    (APPD).bRowClicked = YES;
    if ([_olView selectedRowIndexes].count == 1) {
        PDFOutline *ol = [_olView itemAtRow:[_olView selectedRow]];
        [_pdfView goToDestination:ol.destination];
        //情報データを更新
        [self updateOLInfo:ol];
    }
    [self updateSelectedRowInfo];
}

//行の選択状況情報を更新
- (void)updateSelectedRowInfo{
    if ([_olView selectedRowIndexes].count == 1) {
        (APPD).isOLSelected = YES;
        (APPD).isOLSelectedSingle = YES;
    } else if ([_olView selectedRowIndexes].count == 0) {
        (APPD).isOLSelectedSingle = NO;
        (APPD).isOLSelected = NO;
    } else {
        (APPD).isOLSelectedSingle = NO;
        (APPD).isOLSelected = YES;
    }
}

//PDFOutline情報の更新
- (void)updateOLInfo:(PDFOutline*)ol{
    PDFPage *page = ol.destination.page;
    PDFDocument *doc = [_pdfView document];
    NSRect rect = [page boundsForBox:kPDFDisplayBoxArtBox];
    [(APPD).olInfo setObject:ol.label forKey:@"olLabel"];
    [(APPD).olInfo setObject:ol.destination forKey:@"destination"];
    [(APPD).olInfo setObject:page.label forKey:@"pageLabel"];
    [(APPD).olInfo setObject:[NSNumber numberWithInteger:[doc indexForPage:page]] forKey:@"pageIndex"];
    [(APPD).olInfo setObject:[NSNumber numberWithDouble:ol.destination.point.x] forKey:@"pointX"];
    [(APPD).olInfo setObject:[NSNumber numberWithDouble:ol.destination.point.y] forKey:@"pointY"];
    [(APPD).olInfo setObject:[NSNumber numberWithDouble:rect.size.width] forKey:@"xMax"];
    [(APPD).olInfo setObject:[NSNumber numberWithDouble:rect.size.height] forKey:@"yMax"];
}

//ページ移動時
- (void)pageChanged{
    PDFDocument *doc = [_pdfView document];
    if (!doc.outlineRoot||segOLViewMode.selectedSegment==1)
        return;
    //現在のページインデクスを取得
    NSUInteger dPage = [doc indexForPage:[_pdfView currentDestination].page];
    NSUInteger page = [doc indexForPage:[_pdfView currentPage]];
    if (_olView.selectedRow >= 0) {
        //現在のページと同ページのしおりが選択されている場合は選択行を変更しない
        PDFOutline *selectedOL = [_olView itemAtRow:[_olView selectedRow]];
        NSUInteger selectedRowPage = [doc indexForPage:selectedOL.destination.page];
        if ((APPD).bRowClicked && selectedRowPage == dPage) {
            return;
        }
    }
    //アウトラインを走査してページをチェック
    NSInteger newRow = -1;
    NSUInteger olPg = 0;
    for (int i = 0; i < [_olView numberOfRows]; i++){
        //PDFアウトラインのページを取得
        PDFOutline  *ol = [_olView itemAtRow: i];
        olPg = [doc indexForPage:ol.destination.page];
        if (olPg == page){
            //現在のページとPDFアウトラインのページが一致した場合
            newRow = i;
            break;
        }
        if (olPg > page){
            //現在のページよりPDFアウトラインのページが後ろの場合
            newRow = i - 1;
            break;
        }
    }
    //現在のページが最終行のページより後ろの場合
    if (olPg < page) {
        newRow = [_olView numberOfRows]-1;
    }
    //該当行を選択
    if (newRow >= 0||!(olPg < page)){
        [_olView selectRowIndexes:[NSIndexSet indexSetWithIndex:newRow] byExtendingSelection:NO];
        [_olView scrollRowToVisible:newRow];
    }
    (APPD).bRowClicked = NO;
}

//コンテナ開閉で選択行を移行
- (void)outlineViewItemDidExpand:(NSNotification *)notification{
    [self pageChanged];
}
- (void)outlineViewItemDidCollapse:(NSNotification *)notification{
    [self pageChanged];
}

#pragma mark - outline data control

//メニュー／新規しおり作成
- (IBAction)mnNewBookmark:(id)sender{
    PDFPage *page = [[_pdfView document]pageAtIndex:0];
    NSRect rect = [page boundsForBox:kPDFDisplayBoxArtBox];
    PDFDestination *destination = [[PDFDestination alloc]initWithPage:page atPoint:NSMakePoint(0, rect.size.height)];
    [self makeNewBookMark:NSLocalizedString(@"UntitledLabal", @"") withDestination:destination];
}

//メニュー／選択範囲から新規しおり作成
- (IBAction)mnNewBookmarkFromSelection:(id)sender{
    PDFSelection *sel = [_pdfView currentSelection];
    PDFPage *page;
    NSRect rect;
    if (!sel) {
        page = _pdfView.targetPg;
        rect = _pdfView.selRect;
        sel = [page selectionForRect:rect];
    } else {
        page = [[sel pages]objectAtIndex:0];
        rect = [sel boundsForPage:page];
    }
    //ラベルから先頭末尾の改行文字を取り除く
    NSCharacterSet *chrSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *label = [[sel string] stringByTrimmingCharactersInSet:chrSet];
    NSPoint point = NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height);
    PDFDestination *destination = [[PDFDestination alloc]initWithPage:page atPoint:point];
    [self makeNewBookMark:label withDestination:destination];
}

//BMパネル新規しおり作成
- (void)newBMFromInfo{
    NSString *label = [(APPD).olInfo objectForKey:@"olLabel"];
    [self makeNewBookMark:label withDestination:[self destinationFromInfo]];
}

- (PDFDestination*)destinationFromInfo{
    NSInteger pageIndex = [[(APPD).olInfo objectForKey:@"pageIndex"]integerValue];
    double pointX = [[(APPD).olInfo objectForKey:@"pointX"]doubleValue];
    double pointY = [[(APPD).olInfo objectForKey:@"pointY"]doubleValue];
    PDFPage *page = [[_pdfView document]pageAtIndex:pageIndex];
    PDFDestination *destination = [[PDFDestination alloc]initWithPage:page atPoint:NSMakePoint(pointX, pointY)];
    return destination;
}

//新規PDFアウトライン作成
- (void)makeNewBookMark:(NSString *)label withDestination:(PDFDestination *)destination{
    PDFOutline *ol = [[PDFOutline alloc]init];
    [ol setLabel:label];
    [ol setDestination:destination];
    [self addNewDataToSelection:ol];
}

- (void)addNewDataToSelection:(PDFOutline*)ol{
    //ルートアイテムがない場合は作成
    [self createOLRoot];
    PDFOutline *parentOL = [[PDFOutline alloc]init];
    NSInteger selectedRow = _olView.selectedRow;
    //アウトラインビューを編集モードに変更
    [self viewToEditBMMode];
    if (selectedRow == -1){
        //何も選択されていない = ルートが親
        parentOL = [[_pdfView document]outlineRoot];
    } else {
        //選択行が親
        parentOL = (PDFOutline *)[_olView itemAtRow:selectedRow];
    }
    //親の小グループの末尾に追加
    NSInteger index = parentOL.numberOfChildren;
    [parentOL insertChild:ol atIndex:index];
    [_olView reloadData];
    //追加行が名称未設定Bookmarkの場合、ラベルを編集状態にする
    [_olView expandItem:[_olView itemAtRow:selectedRow] expandChildren:YES];
    if ([ol.label isEqualToString:NSLocalizedString(@"UntitledLabal", @"")]) {
        [_olView editColumn:0 row:[_olView rowForItem:ol] withEvent:nil select:YES];
    }
    [self.document updateChangeCount:NSChangeDone];
}

//メニュー／しおり削除
- (IBAction)removeOutline:(id)sender{
    NSIndexSet *selectedRows = _olView.selectedRowIndexes;
    NSInteger index = selectedRows.lastIndex;
    while (index != NSNotFound) {
        PDFOutline *ol = [_olView itemAtRow:index];
        [ol removeFromParent];
        index = [selectedRows indexLessThanIndex:index];
    }
    [_olView reloadData];
    [self.document updateChangeCount:NSChangeDone];
    (APPD).isOLSelected = NO;
    if (_pdfView.document.outlineRoot.numberOfChildren == 0) {
        (APPD).isOLExists = NO;
    }
}

//メニュー／しおりクリア
- (IBAction)clearOutline:(id)sender{
    PDFOutline *root = _pdfView.document.outlineRoot;
    for (NSInteger i = root.numberOfChildren - 1; i >= 0; i--) {
        PDFOutline *ol = [root childAtIndex:i];
        [ol removeFromParent];
    }
    [_olView reloadData];
    (APPD).isOLExists = NO;
    [self.document updateChangeCount:NSChangeDone];
}

//しおりのルートアイテムを作成
- (void)createOLRoot{
    if (![[_pdfView document]outlineRoot]) {
        PDFOutline *root = [[PDFOutline alloc]init];
        [[_pdfView document] setOutlineRoot:root];
    }
    (APPD).isOLExists = YES;
}

//ビューをしおり編集モードに
- (void)viewToEditBMMode{
    [segTabTocSelect setSelectedSegment:1];
    [self segSelContentsView:segTabTocSelect];
    [segOLViewMode setSelectedSegment:1];
    [self segOLViewMode:segOLViewMode];
}

//現在の選択範囲からPDFDestinationを取得
- (void)getDestinationFromCurrentSelection{
    PDFDocument *doc = _pdfView.document;
    PDFSelection *sel = [_pdfView currentSelection];
    PDFPage *page;
    NSRect rect;
    if (!sel) {
        page = _pdfView.targetPg;
        rect = _pdfView.selRect;
    } else {
        page = [[sel pages]objectAtIndex:0];
        rect = [sel boundsForPage:page];
    }
    [(APPD).olInfo setObject:[NSNumber numberWithInteger:[doc indexForPage:page]] forKey:@"pageIndex"];
    [(APPD).olInfo setObject:page.label forKey:@"pageLabel"];
    [(APPD).olInfo setObject:[NSNumber numberWithDouble:rect.origin.x] forKey:@"pointX"];
    [(APPD).olInfo setObject:[NSNumber numberWithDouble:rect.origin.y+rect.size.height] forKey:@"pointY"];
}

//アウトラインを更新
- (void)updateOL{
    NSInteger selectedRow = _olView.selectedRow;
    PDFOutline *ol = [_olView itemAtRow:selectedRow];
    [ol setLabel:[(APPD).olInfo objectForKey:@"olLabel"]];
    [ol setDestination:[self destinationFromInfo]];
    (APPD).isOLExists = YES;
    [_olView reloadData];
}

//アウトラインビューのモードを変更
- (IBAction)segOLViewMode:(id)sender {
    switch ([sender selectedSegment]) {
        case 0:
            if ((APPD)._bmPanelC.window.isVisible){
                [APPD showBookmarkPanel:nil];
            }
            selectedViewMode = 0;
            break;
            
        default:
            if (!(APPD)._bmPanelC.window.isVisible){
                [APPD showBookmarkPanel:nil];
                [self.window makeKeyWindow];
            }
            selectedViewMode = 1;
            break;
    }
    [_olView reloadData];
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

- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex{
    NSView *leftView = [[splitView subviews]objectAtIndex:0];
    NSRect leftFrame = [leftView frame];
    [segOLViewMode setWidth:leftFrame.size.width/2 forSegment:0];
    [segOLViewMode setWidth:leftFrame.size.width/2 forSegment:1];
    return proposedPosition;
}

#pragma mark - actions

- (IBAction)txtJumpPage:(id)sender {
    PDFDocument *doc = [_pdfView document];
    PDFPage *page = [doc pageAtIndex:[[sender stringValue]integerValue]-1];
    [_pdfView goToPage:page];
}

//コンテンツ・エリアのビューを切り替え
- (IBAction)segSelContentsView:(id)sender {
    if ([sender selectedSegment]==1) {
        if (![[_pdfView document]outlineRoot]) {
            //ドキュメントにアウトラインがない時にアウトライン表示が選択された
            NSAlert *alert = [[NSAlert alloc]init];
            alert.messageText = NSLocalizedString(@"NotExistOutline_msg", @"");
            [alert setInformativeText:NSLocalizedString(@"NotExistOutline_info", @"")];
            [alert addButtonWithTitle:@"OK"];
            [alert setAlertStyle:NSInformationalAlertStyle];
            [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode){
                //セグメントの選択を元に戻す
                if ([tabToc indexOfTabViewItem:[tabToc selectedTabViewItem]] == 0) {
                    [segTabTocSelect setSelectedSegment:0];
                } else {
                    [segTabTocSelect setSelected:NO forSegment:1];
                }
            }];
        } else {
            [tabToc selectTabViewItemAtIndex:[sender selectedSegment]];
            [segOLViewMode setSelectedSegment:selectedViewMode];
        }
    } else {
        [tabToc selectTabViewItemAtIndex:[sender selectedSegment]];
        [segOLViewMode setSelectedSegment:1];
    }
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
- (IBAction)matrixDisplayMode:(id)sender {
    switch ([sender selectedColumn]) {
        case 0:
            [_pdfView setDisplayMode:kPDFDisplaySinglePage];
            (APPD).isTwoPages = NO;
            break;
        case 2:
            [_pdfView setDisplayMode:kPDFDisplayTwoUp];
            (APPD).isTwoPages = YES;
            break;
        case 3:
            [_pdfView setDisplayMode:kPDFDisplayTwoUpContinuous];
            (APPD).isTwoPages = YES;
            break;
        default:
            [_pdfView setDisplayMode:kPDFDisplaySinglePageContinuous];
            (APPD).isTwoPages = NO;
            break;
    }
    [self updateDisplayModeMenuStatus];
}

- (IBAction)segZoom:(id)sender {
    switch ([sender selectedSegment]) {
        case 0:
            [self zoomIn:nil];
            break;
        case 1:
            [self zoomOut:nil];
            break;
        default:
            [self zoomImageToFit:nil];
            break;
    }
}

- (IBAction)segTool:(id)sender {
    switch ([sender selectedSegment]) {
        case 0:
            [sender setImage:[NSImage imageNamed:@"selectText_on"] forSegment:0];
            [sender setImage:[NSImage imageNamed:@"selectArea_off"] forSegment:1];
            [sender setImage:[NSImage imageNamed:@"zoom_off"] forSegment:3];
            [_pdfView removeSubView];
            [_pdfView deselectArea];
            break;
        case 1:
            [sender setImage:[NSImage imageNamed:@"selectText_off"] forSegment:0];
            [sender setImage:[NSImage imageNamed:@"selectArea_on"] forSegment:1];
            [sender setImage:[NSImage imageNamed:@"zoom_off"] forSegment:3];
            [_pdfView removeSubView];
            [_pdfView clearSelection];
            break;
        case 2:
            [sender setImage:[NSImage imageNamed:@"selectText_off"] forSegment:0];
            [sender setImage:[NSImage imageNamed:@"selectArea_off"] forSegment:1];
            [sender setImage:[NSImage imageNamed:@"zoom_off"] forSegment:3];
            [_pdfView loadHandScrollView];
            break;
        case 3:
            [sender setImage:[NSImage imageNamed:@"selectText_off"] forSegment:0];
            [sender setImage:[NSImage imageNamed:@"selectArea_off"] forSegment:1];
            [sender setImage:[NSImage imageNamed:@"zoom_on"] forSegment:3];
            [_pdfView loadZoomView];
            break;
    }
}

#pragma mark - menu action

//ファイルメニュー/印刷
- (void)printDocument:(id)sender{
    [_pdfView printWithInfo:[self.document printInfo]  autoRotate:YES];
}

//表示メニュー
- (IBAction)zoomIn:(id)sender{
    [_pdfView zoomIn:nil];
}

- (IBAction)zoomOut:(id)sender{
    [_pdfView zoomOut:nil];
}

- (IBAction)zoomImageToFit:(id)sender{
    [_pdfView setAutoScales:YES];
    [_pdfView setAutoScales:NO];
}

- (IBAction)zoomImageToActualSize:(id)sender{
    [_pdfView setScaleFactor:1];
}

- (IBAction)mnSinglePage:(id)sender{
    [matrixDisplayMode selectCellWithTag:0];
    [APPD setMnPageDisplayState:0];
    [self matrixDisplayMode:matrixDisplayMode];
}

- (IBAction)mnSingleCont:(id)sender{
    [matrixDisplayMode selectCellWithTag:1];
    [APPD setMnPageDisplayState:1];
    [self matrixDisplayMode:matrixDisplayMode];
}

- (IBAction)mnTwoPages:(id)sender{
    [matrixDisplayMode selectCellWithTag:2];
    [APPD setMnPageDisplayState:2];
    [self matrixDisplayMode:matrixDisplayMode];
}

- (IBAction)mnTwoPagesCont:(id)sender{
    [matrixDisplayMode selectCellWithTag:3];
    [APPD setMnPageDisplayState:3];
    [self matrixDisplayMode:matrixDisplayMode];
}

- (IBAction)mnDisplayAsBook:(id)sender{
    if (_pdfView.displaysAsBook) {
        [_pdfView setDisplaysAsBook:NO];
        [sender setState:0];
    } else {
        [_pdfView setDisplaysAsBook:YES];
        [sender setState:1];
    }
}

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

- (IBAction)mnFindInPDF:(id)sender{
    CGFloat currentTocWidth = tocView.frame.size.width;
    if (currentTocWidth == 0) {
        [self showSideBar:nil];
    }
    [self.window makeFirstResponder:searchField];
}

- (IBAction)mnDeselect:(id)sender{
    [_pdfView clearSelection];
    [_pdfView deselectArea];
}

- (IBAction)mnExportASImage:(id)sender{
    _expPanel = [[ExportPanel alloc]initWithWindowNibName:@"ExportPanel"];
    [self.window beginSheet:_expPanel.window completionHandler:^(NSModalResponse returnCode){
        _expPanel = nil;
    }];
}

- (IBAction)mnSplitPDF:(id)sender{
    _splitPanel = [[SplitPanel alloc]initWithWindowNibName:@"SplitPanel"];
    [self.window beginSheet:_splitPanel.window completionHandler:^(NSModalResponse returnCode){
        _splitPanel = nil;
    }];
}

- (IBAction)mnRemovePage:(id)sender{
    _removePanel = [[RemovePanel alloc]initWithWindowNibName:@"RemovePanel"];
    [self.window beginSheet:_removePanel.window completionHandler:^(NSModalResponse returnCode){
        _removePanel = nil;
    }];
}

@end
