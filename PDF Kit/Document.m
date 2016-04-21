//
//  Document.m
//  PDF Kit
//
//  Created by 河野 さおり on 2016/02/15.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "Document.h"
#import "MyWinC.h"

@interface Document ()

@end

@implementation Document{
    BOOL bSave;
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
    NSWindowController *cntr = [[MyWinC alloc]initWithWindowNibName:[self windowNibName]];
    [self addWindowController:cntr];
    [cntr setShouldCloseDocument:YES];
    //ウインドウの位置を制御
    NSDocumentController *docCtr = [NSDocumentController sharedDocumentController];
    if (docCtr.documents.count == 1) {
        //ドキュメントがひとつも開かれていなければ初期位置に戻す
        NSRect screen = [[NSScreen mainScreen]visibleFrame];
        NSRect winFrame = cntr.window.frame;
        [cntr.window setFrameOrigin:NSMakePoint(0, screen.size.height-winFrame.size.height)];
    }
}

- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError{
    MyWinC *winC = [[self windowControllers]objectAtIndex:0];
    return [winC._pdfView.document writeToURL:url withOptions:winC.options];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    if ([self windowControllers].count != 0) {
        //復帰のための読み込みの場合
        MyWinC *winC = [[self windowControllers]objectAtIndex:0];
        [winC revertDocumentToSaved];
    }
    return YES;
}

//セーブパネルにファイルフォーマット選択のポップアップを表示させるかの可否
- (BOOL)shouldRunSavePanelWithAccessoryView{
    return NO;
}

@end
