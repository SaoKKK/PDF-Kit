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

@implementation Document{
    BOOL bSave;
}

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
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
    NSWindowController *cntr = [[MyWindowController alloc]initWithWindowNibName:[self windowNibName]];
    [self addWindowController:cntr];
    //ウインドウの位置を制御
    NSDocumentController *docCtr = [NSDocumentController sharedDocumentController];
    if (docCtr.documents.count == 1) {
        //ドキュメントがひとつも開かれていなければ初期位置に戻す
        NSRect screen = [[NSScreen mainScreen]visibleFrame];
        NSRect winFrame = cntr.window.frame;
        [cntr.window setFrameOrigin:NSMakePoint(0, screen.size.height-winFrame.size.height)];
    }
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError{
    //PDFビューのドキュメントをNSDataにパッケージして返す
    MyWindowController *winC = [[self windowControllers]objectAtIndex:0];
    return [winC pdfViewDocumentData];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    if ([self windowControllers].count != 0) {
        //復帰のための読み込みの場合
        MyWindowController *winC = [[self windowControllers]objectAtIndex:0];
        [winC revertDocumentToSaved];
    }
    return YES;
}

@end
