//
//  AppDelegate.m
//  PDF Kit
//
//  Created by 河野 さおり on 2016/02/15.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "AppDelegate.h"
#import "MergePDFWin.h"
#import "BMPanelController.h"

@interface AppDelegate (){
    BMPanelController *_bmPanelC;
    MergePDFWin *_mergePDFWC;
    IBOutlet NSMenuItem *mnSinglePage;
    IBOutlet NSMenuItem *mnSingleCont;
    IBOutlet NSMenuItem *mnTwoPages;
    IBOutlet NSMenuItem *mnTwoPageCont;
    IBOutlet NSMenuItem *mnItemFindInPDF;
    NSArray *mnPageDisplay; //表示モード変更メニューグループ
    IBOutlet NSTextField *statusWinMsg;
    IBOutlet NSTextField *statusWinInfo;
}

@end

@implementation AppDelegate

@synthesize PDFLst,errLst,statusWin,mnItemView,mnItemGo,mnView,mnGo;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    //メニューグループを作成
    mnPageDisplay = [NSArray arrayWithObjects:mnSinglePage,mnSingleCont,mnTwoPages,mnTwoPageCont,nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (id)init{
    self = [super init];
    if (self) {
        PDFLst = [NSMutableArray array];
        errLst = [NSMutableArray array];
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

#pragma mark - menu item action

- (IBAction)showMergeWin:(id)sender {
    if (! [_mergePDFWC.window isVisible]){
        _mergePDFWC = [[MergePDFWin alloc]initWithWindowNibName:@"MergePDFWin"];
        [_mergePDFWC setShouldCascadeWindows:NO];
        [_mergePDFWC showWindow:self];
    }
}

- (IBAction)showBookmarkPanel:(id)sender{
    if (! [_bmPanelC.window isVisible]){
        _bmPanelC = [[BMPanelController alloc]initWithWindowNibName:@"BMPanelController"];
        [_bmPanelC showWindow:self];
    }
}

#pragma mark - menu control

//検索メニューの有効／無効を切り替え
- (void)findMenuSetEnabled:(BOOL)enabled{
    [mnItemFindInPDF setEnabled:enabled];
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

//ドキュメントメニューの有効／無効を切り替え
- (void)documentMenuSetEnabled:(BOOL)enabled{
    [mnItemGo setEnabled:enabled];
    [mnItemView setEnabled:enabled];
    for (NSMenuItem *item in [mnGo itemArray]) {
        [item setEnabled:enabled];
    }
    for (NSMenuItem *item in [mnView itemArray]){
        [item setEnabled:enabled];
    }
}

//PDF結合ウインドウ用メニュー有効／無効の切り替え
- (void)mergeMenuSetEnabled{
    [mnItemGo setEnabled:YES];
    [mnItemView setEnabled:YES];
    for (NSMenuItem *item in [mnGo itemArray]) {
        [item setEnabled:YES];
    }
    for (NSMenuItem *item in [mnView itemArray]){
        if (item == [mnView itemArray].lastObject){
            [item setEnabled:YES];
        } else {
            [item setEnabled:NO];
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

@end
