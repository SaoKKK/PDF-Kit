//
//  AppDelegate.m
//  PDF Kit
//
//  Created by 河野 さおり on 2016/02/15.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "AppDelegate.h"
#import "MergePDFWin.h"

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
}

@end

@implementation AppDelegate

@synthesize PDFLst,errLst,olInfo,statusWin,_bmPanelC,_txtPanel;

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

#pragma mark - menu item action

- (IBAction)showMergeWin:(id)sender {
    if (! _mergePDFWC){
        _mergePDFWC = [[MergePDFWin alloc]initWithWindowNibName:@"MergePDFWin"];
    }
    [_mergePDFWC setShouldCascadeWindows:NO];
    [_mergePDFWC showWindow:self];
}

- (IBAction)showBookmarkPanel:(id)sender{
    if (! _bmPanelC){
        _bmPanelC = [[BMPanel alloc]initWithWindowNibName:@"BMPanel"];
    }
    [_bmPanelC showOrHideWindow];
}

- (IBAction)showTxtPanel:(id)sender{
    if (! _txtPanel){
        _txtPanel = [[TxtPanel alloc]initWithWindowNibName:@"TxtPanel"];
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

@end
