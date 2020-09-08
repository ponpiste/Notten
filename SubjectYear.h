//
//  SubjectYear.h
//  iLGL
//
//  Created by Sacha Bartholmé on 20/11/2014.
//  Copyright (c) 2014 The iLGL Team. All rights reserved.
//

#import "BonusCell.h"

@protocol SubjectYearDelegate 

- (void)didEditMark:(NSDictionary *)newMark;

@end

@interface SubjectYear : UITableViewController <UIAlertViewDelegate, BonusCellDelegate>

@property () BOOL braco;
@property (strong, nonatomic) NSMutableDictionary *mark;
@property (weak, nonatomic) id delegate;
@property () BOOL isPremiere;
@property (strong, nonatomic) UIColor *color;

@end
