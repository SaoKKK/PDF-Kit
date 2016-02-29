//
//  MyWindowController.h
//  Sao's PDF Kit
//
//  Created by 河野 さおり on 2016/02/19.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@class MyPDFView;

@interface MyWindowController : NSWindowController{
    IBOutlet NSWindow *window;
    IBOutlet NSWindow *progressWin;
    IBOutlet NSProgressIndicator *savingProgBar;
    IBOutlet MyPDFView *_pdfView;
    IBOutlet NSButton *btnGoToFirstPage;
    IBOutlet NSButton *btnGoToPrevPage;
    IBOutlet NSButton *btnGoToNextPage;
    IBOutlet NSButton *btnGoToLastPage;
    IBOutlet NSButton *btnGoBack;
    IBOutlet NSButton *btnGoFoward;
    IBOutlet NSTextField *txtPage;
    IBOutlet NSTextField *txtTotalPg;
    IBOutlet NSNumberFormatter *txtPageFormatter;
    NSURL *docURL;
}

- (void)makeNewDocWithPDF:(PDFDocument*)pdf;

@end
