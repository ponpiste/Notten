//
//  Marks.h
//  iLGL
//
//  Created by Sacha Bartholmé on 07/11/2014.
//  Copyright (c) 2014 The iLGL Team. All rights reserved.
//

#import "Classes.h"
#import "SubjectTerm.h"
#import "SubjectYear.h"
#import "SubjectCombined.h"
#import "Appraisal.h"

@interface Marks : UITableViewController <ClassesDelegate, SubjectTermDelegate, SubjectYearDelegate, AppraisalDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate>

{
    NSArray *titles, *subjects, *rgb;
    NSMutableArray *marks;
    NSMutableArray *generalAverages;
    NSInteger termIndex;
    UIAlertView *addAlertView;
    NSString *file;
    UIColor *color;
    BOOL isPremiere;
    
    IBOutlet UILongPressGestureRecognizer *longPress;
    IBOutlet UIButton *titleButton;
}

@end
