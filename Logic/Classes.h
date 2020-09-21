//
//  Classes.h
//  iLGL
//
//  Created by Sacha Bartholmé on 26/08/15.
//  Copyright (c) 2015 The iLGL Team. All rights reserved.
//

#import "ColorCell.h"
#import "Enseignement.h"

@protocol ClassesDelegate 

- (void)didAddClass:(NSString *)fileName path:(NSString *)filePath;
- (void)didSelectClass:(NSString *)newFile;
- (void)didDeleteClass:(NSString *)deletedFile defaultClass:(NSString *)defaultFile;
- (void)didRenameClass:(NSString *)oldFile withName:(NSString *)newFile;
- (void)didEditColor:(UIColor *)newColor rgb:(NSArray *)newRgb;

@end

@interface Classes : UITableViewController <UIAlertViewDelegate,ColorCellDelegate,EnseignementDelegate>

{
    NSMutableArray *files;
    NSMutableArray *names;
    NSString *path;
    NSInteger accessoryIndex;
    BOOL showSliders;
}

@property (weak, nonatomic) id delegate;
@property (strong, nonatomic) UIColor *color;
@property (strong, nonatomic) NSArray *rgb;

@end
