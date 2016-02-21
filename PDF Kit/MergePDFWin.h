//
//  MergePDFWin.h
//  Sao's PDF Kit
//
//  Created by 河野 さおり on 2016/02/15.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface MergePDFWin : NSWindowController<NSWindowDelegate, NSTableViewDelegate,NSTableViewDataSource>{
    @private
    IBOutlet NSTableView *mergePDFtable;
    IBOutlet NSButton *btnRemove;
    IBOutlet PDFView *_pdfView;
    IBOutlet NSTableView *errTable;
    NSIndexSet *dragRows; //ドラッグ中の行インデクスを保持
}

@end
