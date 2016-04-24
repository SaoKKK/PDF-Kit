//
//  EncryptPanel.m
//  Sao's PDF Kit
//
//  Created by 河野 さおり on 2016/04/21.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "EncryptPanel.h"

#define APPD (AppDelegate *)[NSApp delegate]
#define WINC (MyWinC *)self.window.sheetParent.windowController

@interface EncryptPanel (){
    IBOutlet NSSecureTextField *txtUPass1;
    IBOutlet NSSecureTextField *txtUPass2;
    IBOutlet NSSecureTextField *txtOPass1;
    IBOutlet NSSecureTextField *txtOPass2;
    IBOutlet NSButton *chkForbidCopy;
    IBOutlet NSButton *chkForbidPrint;
}

@end

@implementation EncryptPanel

- (void)windowDidLoad {
    [super windowDidLoad];
}

- (IBAction)pshEncrypt:(id)sender {
    if (!(WINC)._pdfView.document.allowsCopying || !(WINC)._pdfView.document.allowsPrinting) {
        (APPD).parentWin = self.window;
        (APPD).pwTxtPass.stringValue = @"";
        (APPD).pwMsgTxt.stringValue = NSLocalizedString(@"UnlockEditMsg", @"");
        (APPD).pwInfoTxt.stringValue = NSLocalizedString(@"UnlockEditInfo", @"");
        [self.window beginSheet:(APPD).passWin completionHandler:^(NSInteger returnCode){
            if (returnCode == NSModalResponseOK) {
                [self performEncrypt];
            }
        }];
    } else {
        [self performEncrypt];
    }
}

- (void)performEncrypt{
    //入力値のチェック
    NSString *uPass = txtUPass1.stringValue;
    NSString *oPass = txtOPass1.stringValue;
    if (chkForbidCopy.state || chkForbidPrint.state) {
        if ([oPass isEqualToString:@""]) {
            [self alertWithOKBtn:NSLocalizedString(@"oNoneMsg",@"") info:NSLocalizedString(@"oNoneInfo",@"")];
            return;
        }
    }
    if ([oPass isNotEqualTo:txtOPass2.stringValue]) {
        [self alertWithOKBtn:NSLocalizedString(@"oPassMsg",@"") info:NSLocalizedString(@"passInfo",@"")];
        return;
    }
    if ([uPass isNotEqualTo:txtUPass2.stringValue]) {
        [self alertWithOKBtn:NSLocalizedString(@"uPassMsg",@"") info:NSLocalizedString(@"passInfo",@"")];
        return;
    }
    if ([oPass isNotEqualTo:@""] && [oPass isEqualToString:uPass]) {
        [self alertWithOKBtn:NSLocalizedString(@"passSameMsg",@"") info:NSLocalizedString(@"passInfo",@"")];
        return;
    }
    //ドキュメントの暗号化
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    NSDictionary *option = [NSDictionary dictionary];
    if (![uPass isEqualToString:@""]) {
        option = [NSDictionary dictionaryWithObjectsAndKeys:uPass,kCGPDFContextUserPassword, nil];
        [options addEntriesFromDictionary:option];
        if ([oPass isEqualToString:@""]) {
            option = [NSDictionary dictionaryWithObjectsAndKeys:oPass,kCGPDFContextOwnerPassword, nil];
            [options addEntriesFromDictionary:option];
        }
    }
    if (![oPass isEqualToString:@""]) {
        option = [NSDictionary dictionaryWithObjectsAndKeys:oPass,kCGPDFContextOwnerPassword, nil];
        [options addEntriesFromDictionary:option];
        CFBooleanRef aCopy,aPrint;
        if (chkForbidCopy.state) {
            aCopy = kCFBooleanFalse;
        } else {
            aCopy = kCFBooleanTrue;
        }
        if (chkForbidPrint.state) {
            aPrint = kCFBooleanFalse;
        } else {
            aPrint = kCFBooleanTrue;
        }
        option = [NSDictionary dictionaryWithObjectsAndKeys:(__bridge id _Nonnull)(aCopy),kCGPDFContextAllowsCopying,(__bridge id _Nonnull)(aPrint),kCGPDFContextAllowsPrinting, nil];
        [options addEntriesFromDictionary:option];
    }
    PDFDocument *doc = (WINC)._pdfView.document;
    [doc writeToURL: (WINC).docURL withOptions: options];
    [(WINC).document updateChangeCount:NSChangeCleared];
    (WINC).isEncrypted = YES;
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}

- (NSInteger)alertWithOKBtn:(NSString*)msgTxt info:(NSString*)infoTxt{
    NSAlert *alert = [[NSAlert alloc]init];
    alert.messageText = msgTxt;
    [alert setInformativeText:infoTxt];
    [alert addButtonWithTitle:@"OK"];
    [alert setAlertStyle:NSCriticalAlertStyle];
    return [alert runModalSheetForWindow:self.window];
}

- (IBAction)pshCancel:(id)sender {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

@end
