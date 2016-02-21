//
//  AppDelegate.m
//  PDF Kit
//
//  Created by 河野 さおり on 2016/02/15.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate (){
    IBOutlet NSMenuItem *mnMergePDF;
}
@property (strong) NSWindowController* _mergePDFWC;

@end

@implementation AppDelegate

@synthesize PDFLst,errLst;

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
    self._mergePDFWC = [[NSWindowController alloc]initWithWindowNibName:@"MergePDFWin"];
    [self._mergePDFWC showWindow:self];
}

@end
