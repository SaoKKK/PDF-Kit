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
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError{
    return NULL;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    return YES;
}

@end
