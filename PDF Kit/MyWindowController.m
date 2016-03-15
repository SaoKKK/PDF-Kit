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
#import "AppDelegate.h"
#import "OLController.h"

#define kMinTocAreaSplit	200.0f
#define APPD (AppDelegate *)[NSApp delegate]

@interface MyWindowController ()

@end

@implementation MyWindowController

#pragma mark - Window Controller Method

- (void)windowDidLoad {
    [super windowDidLoad];
    //インスタンス変数を初期化
    bFullscreen = NO;
    bOLEdited = NO;
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
    //ドキュメント情報を更新
    [self updateDocInfo];
    //ページ表示テキストフィールドの値を変更
    [self updateTxtPg];
    //サムネイルビューの設定
    [thumbView setAllowsMultipleSelection:YES];
    //アウトラインルートがあるかどうかチェック
    if ([[_pdfView document]outlineRoot]) {
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

//しおりが更新されていた場合のウインドウを閉じる動作
- (BOOL)windowShouldClose:(id)sender{
    if ([(NSDocument*)self.document isDocumentEdited]) {
        bOLEdited = NO;
    } else {
        if (bOLEdited) {
            [self outlineChangedAlert];
        }
    }
    return !bOLEdited;
}

- (void)outlineChangedAlert{
    NSAlert *alert = [[NSAlert alloc]init];
    NSString *errMsgTxt,*errInfoTxt;
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if ([language isEqualToString:@"en"]){
        errMsgTxt = [NSString stringWithFormat:@"Do you want to save the changes made to the document \"%@\" ?",docURL.path.lastPathComponent];
        errInfoTxt = @"Your changes will be lost if you don't save.";
    } else {
        errMsgTxt = [NSString stringWithFormat:@"書類 \"%@\" に加えた変更を保存しますか?",docURL.path.lastPathComponent];
        errInfoTxt = @"保存しないと変更は失われます。";
    }
    alert.messageText = errMsgTxt;
    [alert setInformativeText:errInfoTxt];
    [alert addButtonWithTitle:NSLocalizedString(@"Save",@"")];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel",@"")];
    [alert addButtonWithTitle:NSLocalizedString(@"Don't Save",@"")];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode){
        if (returnCode == NSAlertFirstButtonReturn) {
            [self.document saveDocument:nil];
            [self.window orderOut:self];
        } else if (returnCode == NSAlertThirdButtonReturn){
            [self.window orderOut:self];
        }
    }];
}

//ドキュメント情報を更新
- (void)updateDocInfo{
    PDFDocument *doc = [_pdfView document];
    [(APPD).olInfo setObject:[NSNumber numberWithFloat:doc.pageCount] forKey:@"totalPage"];
    [(APPD).olInfo setObject:[NSNumber numberWithFloat:doc.pageCount-1] forKey:@"lastIndex"];
    }

#pragma mark - document save/open support

- (NSData *)pdfViewDocumentData{
    return [[_pdfView document]dataRepresentation];
}

- (void)revertDocumentToSaved{
    PDFDocument *doc = [[PDFDocument alloc]initWithURL:docURL];
    [_pdfView setDocument:doc];
    [_olView reloadData];
    [_olView expandItem:nil expandChildren:YES];
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
        //ドキュメント更新フラグを初期化
        bOLEdited = NO;
    }];
    //メインウインドウ変更
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeMainNotification object:self.window queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        (APPD).isDocWinMain = YES;
        [(OLController*)_olView.delegate updateSelectedRowInfo];
        [APPD documentMenuSetEnabled:YES];
        (APPD).isOLExists = [self isOLExists];
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
            (APPD).isDocWinMain = NO;
            (APPD).isOLExists = NO;
            (APPD).isOLSelectedSingle = NO;
            (APPD).isOLSelected = NO;
            [APPD documentMenuSetEnabled:NO];
        }
    }];
    //ページ移動
    [[NSNotificationCenter defaultCenter] addObserverForName:PDFViewPageChangedNotification object:_pdfView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        //ページ移動ボタンの有効/無効の切り替え
        [self updateGoButtonEnabled];
        //ページ表示テキストフィールドの値を変更
        [self updateTxtPg];
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
    [_pdfView setAutoScales:NO];
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
    //検索結果を表示
    [tabToc selectTabViewItemAtIndex:2];
    [[[_tbView.tableColumns objectAtIndex:1]headerCell] setTitle:[NSString stringWithFormat:@"%@%li",NSLocalizedString(@"RESULT", @""),searchResult.count]];
    [_tbView reloadData];
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
    if (!sel) {
        [self showNoSelectAlert];
    } else {
        NSString *label = [sel string];
        PDFPage *page = [[sel pages]objectAtIndex:0];
        NSRect rect = [sel boundsForPage:page];
        NSPoint point = NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height);
        PDFDestination *destination = [[PDFDestination alloc]initWithPage:page atPoint:point];
        [self makeNewBookMark:label withDestination:destination];
    }
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

//未選択アラート表示
- (void)showNoSelectAlert{
    NSAlert *alert = [[NSAlert alloc]init];
    alert.messageText = NSLocalizedString(@"NoSelectBM_msg", @"");
    [alert setInformativeText:NSLocalizedString(@"NoSelectBM_info", @"")];
    [alert addButtonWithTitle:@"OK"];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode){
        return;
    }];
}

//新規PDFアウトライン作成
- (void)makeNewBookMark:(NSString *)label withDestination:(PDFDestination *)destination{
    PDFOutline *ol = [[PDFOutline alloc]init];
    [ol setLabel:label];
    [ol setDestination:destination];
    [self addNewDataToSelection:ol];
}

- (void)addNewDataToSelection:(PDFOutline*)ol{
    [self viewToEditBMMode];
    PDFOutline *parentOL = [[PDFOutline alloc]init];
    NSInteger selectedRow = _olView.selectedRow;
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
    bOLEdited = YES;
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
    bOLEdited = YES;
}

//メニュー／しおりクリア
- (IBAction)clearOutline:(id)sender{
    PDFOutline *root = _pdfView.document.outlineRoot;
    for (int i = 0; i<root.numberOfChildren; i++) {
        PDFOutline *ol = [root childAtIndex:i];
        [ol removeFromParent];
    }
    [_olView reloadData];
    (APPD).isOLExists = NO;
    bOLEdited = YES;
}

//ビューをしおり編集モードに
- (void)viewToEditBMMode{
    //ルートアイテムがない場合は作成
    if (![[_pdfView document]outlineRoot]) {
        PDFOutline *root = [[PDFOutline alloc]init];
        [[_pdfView document] setOutlineRoot:root];
        (APPD).isOLExists = YES;
    }
    [segTabTocSelect setSelectedSegment:1];
    [self segSelContentsView:segTabTocSelect];
    [segPageViewMode setSelected:YES forSegment:1];
    if (!(APPD)._bmPanelC.window.isVisible){
        [APPD showBookmarkPanel:nil];
        [self.window makeKeyWindow];
    }
}

//現在の選択範囲からPDFDestinationを取得
- (void)getDestinationFromCurrentSelection{
    PDFSelection *sel = [_pdfView currentSelection];
    if (!sel) {
        [self showNoSelectAlert];
    } else {
        PDFDocument *doc = _pdfView.document;
        PDFPage *page = [[sel pages]objectAtIndex:0];
        NSRect rect = [sel boundsForPage:page];
        [(APPD).olInfo setObject:[NSNumber numberWithInteger:[doc indexForPage:page]] forKey:@"pageIndex"];
        [(APPD).olInfo setObject:page.label forKey:@"pageLabel"];
        [(APPD).olInfo setObject:[NSNumber numberWithDouble:rect.origin.x] forKey:@"pointX"];
        [(APPD).olInfo setObject:[NSNumber numberWithDouble:rect.origin.y+rect.size.height] forKey:@"pointY"];
    }
}

//アウトラインを更新
- (void)updateOL{
    NSInteger selectedRow = _olView.selectedRow;
    PDFOutline *ol = [_olView itemAtRow:selectedRow];
    [ol setLabel:[(APPD).olInfo objectForKey:@"olLabel"]];
    [ol setDestination:[self destinationFromInfo]];
    [_olView reloadData];
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
        [_pdfView setCurrentSelection:sel];
        [_pdfView scrollSelectionToVisible:self];
    }
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

#pragma mark - actions

- (IBAction)test:(id)sender {
    PDFPage *page = _pdfView.currentPage;
    //ページ表示に必要なNSView座標系でのサイズ
    NSRect rect = [page boundsForBox:kPDFDisplayBoxArtBox];
    NSSize size = [_pdfView rowSizeForPage:page];
    //NSView座標系のpointをPDF座標系のpointに変換
    NSPoint point = [_pdfView convertPoint:NSMakePoint(size.width, size.height) toPage:page];
    NSLog(@"%f,%f",point.x,point.y);
    NSLog(@"%f,%f,%f,%f",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
}

- (IBAction)aa:(id)sender{
    PDFDestination *dest = _pdfView.currentDestination;
    NSLog(@"%f,%f",dest.point.x,dest.point.y);
}

- (IBAction)txtJumpPage:(id)sender {
    PDFDocument *doc = [_pdfView document];
    PDFPage *page = [doc pageAtIndex:[[sender stringValue]integerValue]-1];
    [_pdfView goToPage:page];
}

//コンテンツ・エリアのビューを切り替え
- (IBAction)segSelContentsView:(id)sender {
    if ([sender selectedSegment]==1 && ![[_pdfView document]outlineRoot]) {
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
            break;
        case 2:
            [_pdfView setDisplayMode:kPDFDisplayTwoUp];
            break;
        case 3:
            [_pdfView setDisplayMode:kPDFDisplayTwoUpContinuous];
            break;
        default:
            [_pdfView setDisplayMode:kPDFDisplaySinglePageContinuous];
            break;
    }
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

#pragma mark - menu action

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
    [self.window makeFirstResponder:searchField];
}

@end
