//
//  MyWinC.h
//  Sao's PDF Kit
//
//  Created by 河野 さおり on 2016/02/19.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "BMPanel.h"
#import "ExportPanel.h"
#import "SplitPanel.h"
#import "RemovePanel.h"
#import "MyOLView.h"
#import "InfoPanel.h"
#import "EncryptPanel.h"

@class MyPDFView;
@class ExportPanel;
@class SplitPanel;
@class RemovePanel;
@class MyOLView;
@class InfoPanel;
@class EncryptPanel;

@interface MyWinC : NSWindowController<NSWindowDelegate,NSTableViewDataSource,NSTableViewDelegate,NSSplitViewDelegate>{
    IBOutlet NSWindow *window;
    IBOutlet NSWindow *progressWin;
    IBOutlet NSProgressIndicator *savingProgBar;
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
    IBOutlet NSSegmentedControl *segOLViewMode;
    IBOutlet NSTableView *_tbView;
    IBOutlet NSSplitView *_splitView;
    IBOutlet NSSegmentedControl *segTabTocSelect;
    IBOutlet NSView *tocView;
    IBOutlet NSTabView *tabToc;
    IBOutlet NSSearchField *searchField;
    CGFloat oldTocWidth; //目次エリアの変更前の幅保持用
    BOOL bFullscreen; //スクリーンモード保持用
    NSMutableArray *searchResult; //検索結果保持用
    NSUInteger selectedViewMode; //指定ビューモード保持用
}
@property (strong) IBOutlet MyPDFView *_pdfView;
@property (strong) IBOutlet MyOLView *_olView;
@property (strong) IBOutlet PDFThumbnailView *thumbView;
@property (strong) IBOutlet NSSegmentedControl *segTool;
@property (strong) ExportPanel *_expPanel;
@property (strong) SplitPanel *_splitPanel;
@property (strong) RemovePanel *_removePanel;
@property (strong) InfoPanel *infoPanel;
@property (strong) EncryptPanel *secPanel;
@property (readonly) NSURL *docURL;  //ドキュメントのURL保持用
@property (assign) BOOL isEncrypted; //ドキュメントの暗号化の有無
@property (readwrite,nonatomic) NSMutableDictionary *options; //保存オプション

- (void)makeNewDocWithPDF:(PDFDocument*)pdf;
- (void)revertDocumentToSaved;
- (void)getDestinationFromCurrentSelection;
- (void)updateOL;
- (void)newBMFromInfo;
- (IBAction)outlineViewRowClicked:(id)sender;
- (void)updateDocInfo;
- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;

@end