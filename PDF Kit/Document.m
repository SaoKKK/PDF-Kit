//
//  Document.m
//  PDF Kit
//
//  Created by 河野 さおり on 2016/02/15.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "Document.h"
#import "MyWindowController.h"

@interface Document ()

@end

@implementation Document

@synthesize strPDFDoc;

- (instancetype)init {
    self = [super init];
    if (self) {
        strPDFDoc = nil;
    }
    return self;
}

+ (BOOL)autosavesInPlace {
    return NO;
}

- (NSString *)windowNibName {
    return @"Document";
}

- (void)makeWindowControllers {
    //ドキュメントウインドウコントローラのインスタンスを作成
    NSWindowController *cntr = [[MyWindowController alloc]initWithWindowNibName:[self windowNibName]];
    [self addWindowController:cntr];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    //ドキュメントデータを読み込みドキュメントウインドウに表示
    PDFDocument *_pdfDoc = [[PDFDocument alloc]initWithURL:[self fileURL]];
    if (! _pdfDoc) {
        //ファイルの読み込みに失敗した場合
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
        return NO;
    } else {
        if ([self windowControllers].count != 0) {
            //復帰のための読み込みの場合（既存のPDFビューに直接読み込む）
            MyWindowController *winCtr = [[self windowControllers]objectAtIndex:0];
            [winCtr._pdfView setDocument:_pdfDoc];
        } else {
            strPDFDoc = _pdfDoc;
        }
    }
    return YES;
}

@end
