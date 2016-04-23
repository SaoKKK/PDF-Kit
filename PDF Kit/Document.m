//
//  Document.m
//  PDF Kit
//
//  Created by 河野 さおり on 2016/02/15.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "Document.h"
#import "MyWinC.h"

#define APPD (AppDelegate *)[NSApp delegate]
#define WINC (MyWinC *)[[self windowControllers]objectAtIndex:0]

@interface Document ()

@end

@implementation Document{
    BOOL bSave;
}

//オートセーブ機能のON/OFF
+ (BOOL)autosavesInPlace {
    return NO;
}

- (NSString *)windowNibName {
    return @"Document";
}

- (void)makeWindowControllers {
    //ドキュメントウインドウコントローラのインスタンスを作成
    NSWindowController *cntr = [[MyWinC alloc]initWithWindowNibName:[self windowNibName]];
    [self addWindowController:cntr];
    [cntr setShouldCloseDocument:YES];
    //ウインドウの位置を制御
    NSDocumentController *docCtr = [NSDocumentController sharedDocumentController];
    if (docCtr.documents.count == 1) {
        //ドキュメントがひとつも開かれていなければ初期位置に戻す
        NSRect screen = [[NSScreen mainScreen]visibleFrame];
        NSRect winFrame = cntr.window.frame;
        [cntr.window setFrameOrigin:NSMakePoint(0, screen.size.height-winFrame.size.height)];
    }
}

#pragma mark - Save Document

- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError{
    return [(WINC)._pdfView.document writeToURL:url withOptions:(WINC).options];
}

- (void)saveDocument:(id)sender{
    if (!(WINC)._pdfView.document.allowsCopying || !(WINC)._pdfView.document.allowsPrinting) {
        [self showUnlock:^(NSInteger returnCode){
            if (returnCode == NSModalResponseOK) {
                [self performSave];
            }
        }];
    } else {
        [self performSave];
    }
}

- (void)performSave{
    if ((WINC).isEncrypted) {
        NSAlert *alert = [[NSAlert alloc]init];
        alert.messageText = NSLocalizedString(@"EncryptedMsg", @"");
        [alert setInformativeText:NSLocalizedString(@"EncryptedInfo", @"")];
        [alert addButtonWithTitle:NSLocalizedString(@"Continue", @"")];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
        [alert setAlertStyle:NSCriticalAlertStyle];
        if ([alert runModalSheetForWindow:(WINC).window] == NSAlertSecondButtonReturn){
            return;
        }
    }
    [super saveDocument:nil];
    (WINC).isEncrypted = NO;
}

- (IBAction)saveDocumentAs:(id)sender{
    if (!(WINC)._pdfView.document.allowsCopying || !(WINC)._pdfView.document.allowsPrinting) {
        [self showUnlock:^(NSInteger returnCode){
            if (returnCode == NSModalResponseOK) {
                [super saveDocumentAs:nil];
            }
        }];
    } else {
        [super saveDocumentAs:nil];
    }
}

- (void)showUnlock:(void (^)(NSModalResponse returnCode))handler{
    (APPD).parentWin = (WINC).window;
    (APPD).pwTxtPass.stringValue = @"";
    (APPD).pwMsgTxt.stringValue = NSLocalizedString(@"UnlockEditMsg", @"");
    (APPD).pwInfoTxt.stringValue = NSLocalizedString(@"UnlockEditInfo", @"");
    [(APPD).parentWin beginSheet:(APPD).passWin completionHandler:handler];
}

//セーブパネルにファイルフォーマット選択のポップアップを表示させるかの可否
- (BOOL)shouldRunSavePanelWithAccessoryView{
    return NO;
}

#pragma mark - Open Document

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    if ([self windowControllers].count != 0) {
        //復帰のための読み込みの場合
        [WINC revertDocumentToSaved];
    }
    return YES;
}

@end
