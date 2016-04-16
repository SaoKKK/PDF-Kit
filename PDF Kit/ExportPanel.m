//
//  ExportPanel.m
//  Sao's PDF Kit
//
//  Created by 河野 さおり on 2016/04/15.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "ExportPanel.h"

@interface ExportPanel ()

@end

@implementation ExportPanel{
    IBOutlet NSWindow *progressWin;
    IBOutlet NSProgressIndicator *progressBar;
    IBOutlet NSComboBox *comboPgRange;
    IBOutlet NSPopUpButton *popFormat;
    IBOutlet NSTabView *tabOption;
    IBOutlet NSPopUpButton *popCMethod;
    IBOutlet NSButton *chkAlpha;
    IBOutlet NSSlider *cSlider;
    NSString *saveFolder;
    NSString *savePath;
    NSArray *comboData;
    double imgCount;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    saveFolder = nil;
    //ノーティフィケーションを設定
    [self setUpNotification];
    //コンボボックスのデータソース用配列を作成
    comboData = [NSArray arrayWithObjects:NSLocalizedString(@"ALL_PAGES", @""),@"e.g. 1-2,5,10",nil];
}

- (void)setUpNotification{
    //書き出し開始
    [[NSNotificationCenter defaultCenter] addObserverForName:@"imgDidBeginCreate" object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        //プログレスバーのステータスを設定
        [progressBar setMaxValue:imgCount];
        [progressBar setDoubleValue: 0.0];
        //プログレス・パネルをシート表示
        [self.window beginSheet:progressWin completionHandler:^(NSInteger returnCode){}];
    }];
    //書き出し過程
    [[NSNotificationCenter defaultCenter] addObserverForName:@"imgDidEndPageInsert" object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
      //プログレスバーの値を更新
        NSNumber *page = [[notif userInfo] objectForKey:@"page"];
        [progressBar setDoubleValue:page.doubleValue];
        [progressBar displayIfNeeded];
    }];
    //書き出し完了
    [[NSNotificationCenter defaultCenter] addObserverForName:@"imgDidEndCreate" object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif){
        //プログレス・パネルを終了させる
        [self.window endSheet:progressWin returnCode:0];
    }];
}

# pragma mark - NSComboBox data source

//コンボボックスのデータソースのアイテム数を返す
- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox{
    return comboData.count;
}

//各インデクスのオブジェクトバリューを返す
- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index{
    return [comboData objectAtIndex:index];
}

- (IBAction)comboPgRange:(id)sender {
    if ([sender indexOfSelectedItem] == 0) {
        [sender setStringValue:NSLocalizedString(@"ALL_PAGES", @"")];
        [self.window makeFirstResponder:nil];
        [sender setEditable:NO];
    }else if([sender indexOfSelectedItem] == 1){
        [sender setStringValue:@""];
        [sender setEditable:YES];
        [self.window makeFirstResponder:sender];
    }
}

- (IBAction)popFormat:(id)sender {
    [tabOption selectTabViewItemAtIndex:[sender indexOfSelectedItem]];
}

- (IBAction)exportAsImage:(id)sender {
    MyWinC *docWinC = self.window.sheetParent.windowController;
    PDFDocument *inputDoc = [[docWinC._pdfView document]copy];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    //保存先のパスを作成
    if (!saveFolder) {
        saveFolder = [[docWinC.document fileURL].path stringByDeletingLastPathComponent];
    }
    NSString *fName = [[docWinC.document fileURL].path.lastPathComponent stringByDeletingPathExtension];
    NSMutableIndexSet *pageRange = [NSMutableIndexSet indexSet];
    NSString *indexStr = comboPgRange.stringValue;
    NSUInteger totalPage = inputDoc.pageCount;
    if ([indexStr isEqualToString:NSLocalizedString(@"ALL_PAGES",@"")]) {
        //All Pagesが選択されている場合
        [pageRange addIndexesInRange:NSMakeRange(1, totalPage)];
    } else {
        //入力値に不正な文字列が含まれないかチェック
        NSCharacterSet *pgRangeChrSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789,-"];
        NSCharacterSet *inputChrSet = [NSCharacterSet characterSetWithCharactersInString:indexStr];
        if (! [pgRangeChrSet isSupersetOfSet:inputChrSet]) {
            //入力値が不正文字列を含む
            [self showPageRangeAllert:NSLocalizedString(@"CharError",@"")];
            return;
        } else {
            //入力値をカンマで分割
            NSArray *ranges = [indexStr componentsSeparatedByString:@","];
            for (NSString *range in ranges) {
                //インデクス指定文字列を"-"で分割
                NSArray *pages = [range componentsSeparatedByString:@"-"];
                if (pages.count > 2) {
                    //"-"が2つ以上含まれる場合
                    [self showPageRangeAllert:NSLocalizedString(@"PageRangeInfo",@"")];
                    return;
                } else if (pages.count == 1) {
                    //"-"が含まれない場合
                    if ([range integerValue] <= totalPage && [range integerValue] > 0) {
                        [pageRange addIndex:[range integerValue]];
                    } else {
                        [self showPageRangeAllert:NSLocalizedString(@"PageRangeInfo",@"")];
                        return;
                    }
                } else if ([[pages objectAtIndex:0]isEqualToString:@""]) {
                    //"-"が先頭にある場合
                    if ([[pages objectAtIndex:1]integerValue] > totalPage || [[pages objectAtIndex:0]integerValue] < 1) {
                        [self showPageRangeAllert:NSLocalizedString(@"PageRangeInfo",@"")];
                        return;
                    } else {
                        [pageRange addIndexesInRange:NSMakeRange(1,[[pages objectAtIndex:1]integerValue])];
                    }
                } else if ([[pages objectAtIndex:1]isEqualToString:@""]) {
                    //"-"が末尾にある場合
                    if ([[pages objectAtIndex:0]integerValue] > totalPage || [[pages objectAtIndex:0]integerValue] < 1) {
                        [self showPageRangeAllert:NSLocalizedString(@"PageRangeInfo",@"")];
                        return;
                    } else {
                        [pageRange addIndexes:[self indexFrom1stIndex:[[pages objectAtIndex:0]integerValue] toLastIndex:totalPage]];
                    }
                } else {
                    //通常の範囲指定
                    if ([[pages objectAtIndex:0]integerValue] < 1 || [[pages objectAtIndex:1]integerValue] > totalPage || [[pages objectAtIndex:0]integerValue] > [[pages objectAtIndex:1]integerValue]) {
                        [self showPageRangeAllert:NSLocalizedString(@"PageRangeInfo",@"")];
                        return;
                    } else {
                        [pageRange addIndexes:[self indexFrom1stIndex:[[pages objectAtIndex:0]integerValue] toLastIndex:[[pages objectAtIndex:1]integerValue]]];
                    }
                }
            }
        }
    }
    //書き出し開始ノーティフィケーションを送信
    imgCount = pageRange.count;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"imgDidBeginCreate" object:self];
    NSUInteger index = [pageRange firstIndex];
    int indexCount = 0;
    while (index != NSNotFound) {
        //書き出し過程ノーティフィケーションを送信
        [[NSNotificationCenter defaultCenter] postNotificationName:@"imgDidEndPageInsert" object:self userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:indexCount] forKey:@"page"]];
        NSImage *image = [self pageToImg:[inputDoc pageAtIndex:index-1]];
        NSData *tifRep = [image TIFFRepresentation];
        //Bitmap画像に変換
        NSBitmapImageRep *imgRep = [NSBitmapImageRep imageRepWithData:tifRep];
        /*
         NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc]
         initWithBitmapDataPlanes:NULL
         pixelsWide:imageSize.width
         pixelsHigh:imageSize.height
         bitsPerSample:8
         samplesPerPixel:3
         hasAlpha:NO
         isPlanar:NO
         bitmapFormat:NSAlphaNonpremultipliedBitmapFormat
         bytesPerRow:(3 * imageSize.width)
         bitsPerPixel:24];

         */
        if (popFormat.indexOfSelectedItem == 0) {
            //TIFF出力
            savePath = [NSString stringWithFormat:@"%@/%@(%li).tiff",saveFolder,fName,index];
            if ([fileMgr fileExistsAtPath:savePath]) {
                //同名ファイルが存在した場合
                NSInteger result = [self showFileExistsAllert];
                if (result == 1000) {
                    saveFolder = nil;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"imgDidEndCreate" object:self];
                    return;
                }
            }
            //圧縮方式を設定
            NSNumber *cMethod;
            switch (popCMethod.indexOfSelectedItem){
                case 0:
                    cMethod = [NSNumber numberWithInt:NSTIFFCompressionNone];
                    break;
                case 1:
                    cMethod = [NSNumber numberWithInt:NSTIFFCompressionLZW];
                    break;
                case 2:
                    cMethod = [NSNumber numberWithInt:NSTIFFCompressionPackBits];
                  break;
            }
            NSDictionary *pTiff = [NSDictionary dictionaryWithObjectsAndKeys:cMethod,NSImageCompressionMethod, nil];
            NSData *tifData = [imgRep representationUsingType:NSTIFFFileType properties:pTiff];
            [tifData writeToFile:savePath atomically:YES];
        } else {
            //JPEG出力
            savePath = [NSString stringWithFormat:@"%@/%@(%li).jpg",saveFolder,fName,index];
            if ([fileMgr fileExistsAtPath:savePath]) {
                //同名ファイルが存在した場合
                NSInteger result = [self showFileExistsAllert];
                if (result == 1000) {
                    saveFolder = nil;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"imgDidEndCreate" object:self];
                    return;
                }
            }
            NSDictionary *pJpeg = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:cSlider.floatValue],NSImageCompressionFactor, nil];
            NSData *jpgData = [imgRep representationUsingType:NSJPEGFileType properties:pJpeg];
            [jpgData writeToFile:savePath atomically:YES];
}
        indexCount++;
        index = [pageRange indexGreaterThanIndex:index];
    }
    //書き出し終了ノーティフィケーションを送信
    [[NSNotificationCenter defaultCenter] postNotificationName:@"imgDidEndCreate" object:self];
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}

//最初と最後のインデクスを指定してインデクスセットを作成
- (NSMutableIndexSet *)indexFrom1stIndex:(NSUInteger)firstIndex toLastIndex:(NSUInteger)lastIndex{
    NSMutableIndexSet *indexset = [NSMutableIndexSet indexSet];
    for (NSUInteger i = firstIndex; i <= lastIndex; i++) {
        [indexset addIndex:i];
    }
    return indexset;
}

- (NSImage*)pageToImg:(PDFPage*)page{
    NSData *pgData = [page dataRepresentation];
    NSPDFImageRep *pdfImgRep = [NSPDFImageRep imageRepWithData:pgData];
    //NSImageに書き込み
    NSSize size; //出力サイズ
    size.width = pdfImgRep.size.width;
    size.height = pdfImgRep.size.height;
    NSImage *image = [[NSImage alloc]initWithSize:size];
    [image lockFocus];
    [pdfImgRep drawInRect:NSMakeRect(0, 0, size.width, size.height)];
    [image unlockFocus];
    return image;
}

- (NSInteger)showPageRangeAllert:(NSString*)infoTxt{
    NSAlert *alert = [[NSAlert alloc]init];
    alert.messageText = NSLocalizedString(@"PageRangeMsg",@"");
    [alert setInformativeText:infoTxt];
    [alert addButtonWithTitle:@"OK"];
    [alert setAlertStyle:NSCriticalAlertStyle];
    return [alert runModalSheetForWindow:self.window];
}
    
- (NSInteger)showFileExistsAllert{
    NSAlert *alert = [[NSAlert alloc]init];
    alert.messageText = [NSString stringWithFormat:@"\"%@\" %@",savePath.lastPathComponent,NSLocalizedString(@"fileNameAlertMsg",@"")];
    [alert setInformativeText:NSLocalizedString(@"fileNameAlertInfo",@"")];
    [alert addButtonWithTitle:NSLocalizedString(@"Suspend",@"")];
    [alert addButtonWithTitle:NSLocalizedString(@"Replace",@"")];
    [alert setAlertStyle:NSCriticalAlertStyle];
    return [alert runModalSheetForWindow:[self.window.sheets objectAtIndex:0]
            ];
}
    

- (IBAction)pshSaveTo:(id)sender {
    NSOpenPanel *openpanel = [NSOpenPanel openPanel];
    //openPanelのパラメータを設定
    [openpanel setCanChooseFiles:NO]; //ファイルの選択の可否
    [openpanel setCanChooseDirectories:YES]; //ディレクトリの選択の可否
    [openpanel setCanCreateDirectories:YES]; //フォルダ作成ボタンの有無
    [openpanel setPrompt:NSLocalizedString(@"Choose", @"")]; //ボタンのタイトル
    [openpanel setMessage:NSLocalizedString(@"ChooseFolder", @"")]; //表示するメッセージテキスト
    [openpanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            saveFolder = openpanel.URL.path;
        }
    }];
}

- (IBAction)pshCancel:(id)sender {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

@end
