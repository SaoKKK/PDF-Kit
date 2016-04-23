//
//  AppDelegate.m
//  PDF Kit
//
//  Created by 河野 さおり on 2016/02/15.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "AppDelegate.h"
#import "MergePDFWin.h"

#define WINC (MyWinC *)[[NSDocumentController sharedDocumentController].currentDocument.windowControllers objectAtIndex:0]

#pragma mark - WindowController

@interface NSWindowController(ConvenienceWC)
- (BOOL)isWindowShown;
- (void)showOrHideWindow;
@end

@implementation NSWindowController(ConvenienceWC)

- (BOOL)isWindowShown{
    return [[self window]isVisible];
}

- (void)showOrHideWindow{
    NSWindow *window = [self window];
    if ([window isVisible]) {
        [window orderOut:self];
    } else {
        [self showWindow:self];
    }
}

@end

@interface AppDelegate (){
    MergePDFWin *_mergePDFWC;
    IBOutlet NSMenuItem *mnSinglePage;
    IBOutlet NSMenuItem *mnSingleCont;
    IBOutlet NSMenuItem *mnTwoPages;
    IBOutlet NSMenuItem *mnTwoPageCont;
    NSArray *mnPageDisplay; //表示モード変更メニューグループ
    IBOutlet NSTextField *statusWinMsg;
    IBOutlet NSTextField *statusWinInfo;
    NSTimer *timer; //ペーストボード監視用タイマー
    NSMutableArray *indexes; //アウトラインのページインデクスバックアップ用
    int cntIndex;
}

@end

@implementation AppDelegate

@synthesize PDFLst,errLst,olInfo,statusWin,_bmPanelC,_txtPanel,isImgInPboard,beResponse,passWin,pwTxtPass,parentWin;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    //メニューグループを作成
    mnPageDisplay = [NSArray arrayWithObjects:mnSinglePage,mnSingleCont,mnTwoPages,mnTwoPageCont,nil];
    //ペーストボード監視用タイマー開始
    timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(observePboard) userInfo:nil repeats:YES];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (id)init{
    self = [super init];
    if (self) {
        PDFLst = [NSMutableArray array];
        errLst = [NSMutableArray array];
        olInfo = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender{
    //アプリケーション起動時に空ドキュメントを開くかの可否
    return NO;
}

- (void)restorePDFLst{
    PDFLst = [NSMutableArray arrayWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"PDFLst" ofType:@"array"]];
}

//ペーストボードを監視
- (void)observePboard{
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    NSArray *classes = [NSArray arrayWithObject:[NSImage class]];
    if ([pboard canReadObjectForClasses:classes options:nil]) {
        isImgInPboard = YES;
    } else {
        isImgInPboard = NO;
    }
}

#pragma mark - menu item action

- (IBAction)newDocFromPboard:(id)sender{
    //クリップボードから画像オブジェクトを取得
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    NSArray *classes = [NSArray arrayWithObject:[NSImage class]];
    NSImage *img = [[pboard readObjectsForClasses:classes options:nil] objectAtIndex:0];
    //画像からPDFを作成
    PDFPage *page = [[PDFPage alloc]initWithImage:img];
    [page setValue:@"1" forKey:@"label"];
    PDFDocument *doc = [[PDFDocument alloc]init];
    [doc insertPage:page atIndex:0];
    //新規ドキュメント作成
    NSDocumentController *docC = [NSDocumentController sharedDocumentController];
    [docC openUntitledDocumentAndDisplay:YES error:nil];
    MyWinC *newWC= [docC.currentDocument.windowControllers objectAtIndex:0];
    [newWC makeNewDocWithPDF:doc];
}

- (IBAction)showMergeWin:(id)sender {
    if (! _mergePDFWC){
        _mergePDFWC = [[MergePDFWin alloc]initWithWindowNibName:@"MergePDFWin"];
    }
    [_mergePDFWC setShouldCascadeWindows:NO];
    [_mergePDFWC setWindowFrameAutosaveName:@"MergePDFWin"];
    [_mergePDFWC showWindow:self];
}

- (IBAction)showBookmarkPanel:(id)sender{
    if (! _bmPanelC){
        _bmPanelC = [[BMPanel alloc]initWithWindowNibName:@"BMPanel"];
        [_bmPanelC setWindowFrameAutosaveName:@"BMPanel"];
    }
    [_bmPanelC showOrHideWindow];
}

- (IBAction)showTxtPanel:(id)sender{
    if (! _txtPanel){
        _txtPanel = [[TxtPanel alloc]initWithWindowNibName:@"TxtPanel"];
        [_txtPanel setWindowFrameAutosaveName:@"TxtPanel"];
    }
    [_txtPanel clearTxt];
    [_txtPanel showOrHideWindow];
}

#pragma mark - menu control

//メニュータイトルの変更
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem{
    SEL action = menuItem.action;
    if (action==@selector(showBookmarkPanel:)) {
        [menuItem setTitle:([_bmPanelC isWindowShown] ? NSLocalizedString(@"HideBM", @""):NSLocalizedString(@"ShowBM", @""))];
    } else if (action==@selector(showTxtPanel:)) {
        [menuItem setTitle:([_txtPanel isWindowShown] ? NSLocalizedString(@"HideTP", @""):NSLocalizedString(@"ShowTP", @""))];
    }
    return YES;
}

//ディスプレイモード変更メニューのステータス変更
- (void)setMnPageDisplayState:(NSInteger)tag{
    for (int i=0; i < mnPageDisplay.count; i++) {
        if (i == tag) {
            [[mnPageDisplay objectAtIndex:i]setState:YES];
        } else {
            [[mnPageDisplay objectAtIndex:i]setState:NO];
        }
    }
}

#pragma mark - status window

- (void)showStatusWin:(NSRect)rect messageText:(NSString*)message infoText:(NSString*)info{
    [statusWin setFrame:rect display:NO];
    [statusWinMsg setStringValue:message];
    [statusWinInfo setStringValue:info];
    [statusWin setLevel:NSFloatingWindowLevel];
    [statusWin orderFront:self];
    [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(closeStatusWin) userInfo:nil repeats:NO];
}

- (void)closeStatusWin{
    [statusWin orderOut:self];
}

#pragma mark - pass window

- (IBAction)pwUnlock:(id)sender {
    //現在のアウトラインのページインデクスをバックアップ
    indexes = [NSMutableArray array];
    cntIndex = 0;
    PDFOutline *root = (WINC)._pdfView.document.outlineRoot;
    [self getIndex:root];
    //ドキュメントをアンロック
    [(WINC)._pdfView.document unlockWithPassword:pwTxtPass.stringValue];
    //アンロック後のアウトラインにバックアップしておいたページインデクスをセット
    [self setIndex:root];
    if ((WINC)._pdfView.document.allowsCopying && (WINC)._pdfView.document.allowsPrinting) {
        self.isLocked = NO;
        [parentWin endSheet:passWin returnCode:NSModalResponseOK];
    }
}

- (void)getIndex:(PDFOutline*)parent{
    for (int i = 0; i < parent.numberOfChildren; i++) {
        PDFOutline *ol = [parent childAtIndex:i];
        PDFPage *page = ol.destination.page;
        NSInteger pgIndex = [(WINC)._pdfView.document indexForPage:page];
        if (pgIndex == NSNotFound) {
            pgIndex = 0;
        }
        [indexes addObject:[NSNumber numberWithInteger:pgIndex]];
        if (ol.numberOfChildren > 0) {
            [self getIndex:ol];
        }
    }
}

- (void)setIndex:(PDFOutline*)parent{
    PDFDocument *doc = (WINC)._pdfView.document;
    for (int i = 0; i < parent.numberOfChildren; i++) {
        PDFOutline *ol = [parent childAtIndex:i];
        PDFPage *page = [doc pageAtIndex:[[indexes objectAtIndex:cntIndex] integerValue]];
        PDFDestination *dest = ol.destination;
        [dest setValue:page forKey:@"page"];
        cntIndex ++;
        if (ol.numberOfChildren > 0) {
            [self setIndex:ol];
        }
    }
}

- (IBAction)pwCancel:(id)sender {
    [parentWin endSheet:passWin returnCode:NSModalResponseCancel];
}

@end
