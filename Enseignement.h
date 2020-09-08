//
//  Enseignement.h
//  Notten
//
//  Created by Sacha Bartholmé on 3/18/17.
//  Copyright © 2017 Sacha Bartholmé. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Classique.h"

@protocol EnseignementDelegate

- (void)didEditEnseignement:(NSString *)fileName path:(NSString *)filePath;

@end

@interface Enseignement : UITableViewController <ClassiqueDelegate>

{
    NSMutableArray *folders;
}

@property (weak, nonatomic) id delegate;

@end
