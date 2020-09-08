//
//  Classique.h
//  Notten
//
//  Created by Sacha Bartholmé on 3/18/17.
//  Copyright © 2017 Sacha Bartholmé. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Classname.h"

@protocol ClassiqueDelegate

- (void)didEditClassique:(NSString *)fileName path:(NSString *)filePath;

@end

@interface Classique : UITableViewController <ClassnameDelegate>

{
    NSMutableArray *folders;
}

@property (weak, nonatomic) id delegate;
@property (strong, nonatomic) NSString *path;

@end
