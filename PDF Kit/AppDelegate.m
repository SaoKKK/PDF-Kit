//
//  AppDelegate.m
//  PDF Kit
//
//  Created by 河野 さおり on 2016/02/15.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "AppDelegate.h"
#import "MergePDFWin.h"

@interface AppDelegate (){
    IBOutlet NSMenuItem *mnMergePDF;
    IBOutlet NSTextField *statusWinMsg;
    IBOutlet NSTextField *statusWinInfo;
}

@property (strong) MergePDFWin* _mergePDFWC;

@end

@implementation AppDelegate

@synthesize PDFLst,errLst,statusWin;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    //メニューアイテムのアクションを設定
    [mnMergePDF setRepresentedObject:@"MergePDF"];
    [mnMergePDF setAction:@selector(mnMergePDF:)];
    
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

#pragma mark - menu item action

//MergePDF アクション
- (IBAction)mnMergePDF:(id)sender {
    self._mergePDFWC = [[MergePDFWin alloc]initWithWindowNibName:@"MergePDFWin"];
    [self._mergePDFWC showWindow:self];
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
