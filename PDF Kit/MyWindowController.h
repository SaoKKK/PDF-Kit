//
//  MyWindowController.h
//  Sao's PDF Kit
//
//  Created by 河野 さおり on 2016/02/19.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "BMPanelController.h"

@class MyPDFView;

@interface MyWindowController : NSWindowController<NSWindowDelegate,NSTableViewDataSource,NSTableViewDelegate,NSSplitViewDelegate>{
    IBOutlet NSWindow *window;
    IBOutlet NSWindow *progressWin;
    IBOutlet NSProgressIndicator *savingProgBar;
    IBOutlet MyPDFView *_pdfView;
    IBOutlet PDFThumbnailView *thumbView;
    IBOutlet NSButton *btnGoToFirstPage;
    IBOutlet NSButton *btnGoToPrevPage;
    IBOutlet NSButton *btnGoToNextPage;
    IBOutlet NSButton *btnGoToLastPage;
    IBOutlet NSButton *btnGoBack;
    IBOutlet NSButton *btnGoForward;
    IBOutlet NSTextField *txtPage;
    IBOutlet NSTextField *txtTotalPg;
    IBOutlet NSNumberFormatter *txtPageFormatter;
    IBOutlet NSSegmentedControl *segZoom;
    IBOutlet NSMatrix *matrixDisplayMode;
    IBOutlet NSOutlineView *_olView;
    IBOutlet NSSegmentedControl *segPageViewMode;
    IBOutlet NSTableView *_tbView;
    IBOutlet NSSplitView *_splitView;
    IBOutlet NSSegmentedControl *segTabTocSelect;
    IBOutlet NSView *tocView;
    IBOutlet NSTabView *tabToc;
    IBOutlet NSSearchField *searchField;
    NSURL *docURL;  //ドキュメントのURL保持用
    CGFloat oldTocWidth; //目次エリアの変更前の幅保持用
    BOOL bFullscreen;   //スクリーンモード保持用
    NSMutableArray *searchResult; //検索結果保持用
    BOOL bOLEdited; //Outline更新フラグ
}

- (void)makeNewDocWithPDF:(PDFDocument*)pdf;
- (NSData *)pdfViewDocumentData;
- (void)revertDocumentToSaved;

@end