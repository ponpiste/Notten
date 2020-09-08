//
//  Classname.h
//  Notten
//
//  Created by Sacha Bartholmé on 3/18/17.
//  Copyright © 2017 Sacha Bartholmé. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ClassnameDelegate

- (void)didEditClassname:(NSString *)fileName path:(NSString *)filePath;

@end

@interface Classname : UITableViewController

{
    NSMutableArray *files;
}

@property (weak, nonatomic) id delegate;
@property (strong, nonatomic) NSString *path;

@end
