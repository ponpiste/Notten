//
//  SubjectCombined.h
//  Notten
//
//  Created by Sacha Bartholmé on 7/16/16.
//  Copyright © 2016 Sacha Bartholmé. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SubjectTerm.h"
#import "SubjectYear.h"

@protocol SubjectCombinedDelegate

- (void)didEditMark:(NSDictionary *)newMark;

@end

@interface SubjectCombined : UITableViewController <SubjectTermDelegate,SubjectYearDelegate,UIAlertViewDelegate>

{
    NSNumber *influencing, *desired;
    NSMutableArray *needed;
    double influence;
    
    IBOutlet UIButton *titleButton;
}

@property (assign, nonatomic) NSInteger termIndex;
@property (strong, nonatomic) NSMutableDictionary *mark;
@property (strong, nonatomic) NSNumber *coefSum;
@property (strong, nonatomic) UIColor *color;
@property () BOOL isPremiere;

@property (weak, nonatomic) id delegate;

@end
