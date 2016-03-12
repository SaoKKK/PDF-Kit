//
//  BMPanelController.m
//  Sao's PDF Kit
//
//  Created by 河野 さおり on 2016/03/11.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "BMPanelController.h"

@interface BMPanelController ()

@end

@implementation BMPanelController{
    
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

- (IBAction)getDestinationFromCurrentSelection:(id)sender{
    NSDocumentController *docC = [NSDocumentController sharedDocumentController];
    NSDocument *doc = [docC currentDocument];
    MyWindowController *winC = [doc.windowControllers objectAtIndex:0];
    NSWindow *docWin = winC.window;
    NSLog(@"%@",docWin.title);
}

@end
