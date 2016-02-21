//
//  MyWindowController.m
//  Sao's PDF Kit
//
//  Created by 河野 さおり on 2016/02/19.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "MyWindowController.h"
#import "Document.h"

@interface MyWindowController ()

@end

@implementation MyWindowController

@synthesize _pdfView;

#pragma mark - Window Controller Method

- (void)windowDidLoad {
    [super windowDidLoad];
    Document *doc = [self document];
    //ファイルから読み込まれたPDFドキュメントをビューに表示
    [_pdfView setDocument:doc.strPDFDoc];
}

@end
