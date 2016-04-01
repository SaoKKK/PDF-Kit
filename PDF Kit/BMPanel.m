//
//  BMPanel.m
//  Sao's PDF Kit
//
//  Created by 河野 さおり on 2016/03/11.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "BMPanel.h"
#import "AppDelegate.h"

#define APPD (AppDelegate *)[NSApp delegate]

@interface BMPanel ()

@end

@implementation BMPanel{
    IBOutlet NSTextField *txtOLLabel;
    IBOutlet NSTextField *txtPgIndex;
    IBOutlet NSTextField *txtPgLabel;
    IBOutlet NSTextField *txtPointX;
    IBOutlet NSTextField *txtPointY;
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

- (IBAction)getDestinationFromCurrentSelection:(id)sender{
    [[self currentDocWinController] getDestinationFromCurrentSelection];
}

- (IBAction)updateOL:(id)sender{
    if ([self checkInput]) {
        [[self currentDocWinController] updateOL];
    }
}

- (IBAction)newBMFromInfo:(id)sender{
    if ([self checkInput]) {
        [[self currentDocWinController] newBMFromInfo];
    }
}

- (BOOL)checkInput{
    [self.window makeFirstResponder:nil]; //入力を確定させる
    if ([txtOLLabel.stringValue isEqualToString:@""]) {
        [self emptyFieldAlert:txtOLLabel.identifier];
    } else if ([txtPgIndex.stringValue isEqualToString:@""]) {
        [self emptyFieldAlert:txtPgIndex.identifier];
    } else if ([txtPointX.stringValue isEqualToString:@""]) {
        [self emptyFieldAlert:txtPointX.identifier];
    } else if ([txtPointY.stringValue isEqualToString:@""]) {
        [self emptyFieldAlert:txtPointY.identifier];
    } else {
        return YES;
    }
    return NO;
}

- (void)emptyFieldAlert:(NSString*)identifier{
    NSAlert *alert = [[NSAlert alloc]init];
    NSString *errMsgTxt = [NSString stringWithFormat:@"%@_msg",identifier];
    alert.messageText = NSLocalizedString(errMsgTxt,@"");
    [alert setInformativeText:NSLocalizedString(@"EmptyErr_info",@"")];
    [alert addButtonWithTitle:@"OK"];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:[self currentDocWinController].window completionHandler:^(NSModalResponse returnCode){}];
}

- (MyWinC*)currentDocWinController{
    NSDocumentController *docC = [NSDocumentController sharedDocumentController];
    NSDocument *doc = [docC currentDocument];
    return [doc.windowControllers objectAtIndex:0];
}

@end
