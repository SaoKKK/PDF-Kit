//
//  Document.h
//  PDF Kit
//
//  Created by 河野 さおり on 2016/02/15.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface Document : NSDocument

@property (readwrite,nonatomic)PDFDocument* strPDFDoc;

@end

