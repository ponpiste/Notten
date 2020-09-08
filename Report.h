//
//  Report.h
//  iLGL
//
//  Created by Sacha Bartholmé on 09/07/15.
//  Copyright (c) 2015 The iLGL Team. All rights reserved.
//

#import <CoreText/CoreText.h>

@interface Report : UIViewController

{
    IBOutlet UIWebView *pdfWebView;
    IBOutlet UIImageView *imageView;
    IBOutlet UILabel *label;
}

@property (strong, nonatomic) UIColor *color;

@end
