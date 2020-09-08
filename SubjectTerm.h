//
//  SubjectTerm.h
//  iLGL
//
//  Created by Sacha Bartholmé on 20/11/2014.
//  Copyright (c) 2014 The iLGL Team. All rights reserved.
//

#import "BonusCell.h"

@protocol SubjectTermDelegate 

- (void)didEditMark:(NSDictionary *)newMark;

@end

@interface SubjectTerm : UITableViewController <UIAlertViewDelegate, BonusCellDelegate>

{
    NSNumber *desiredTrim,*neededTest,*desiredYear,*neededTrim,*influencing;
    double influence;
}

@property () BOOL braco;
@property (assign, nonatomic) NSInteger termIndex;
@property (strong, nonatomic) NSMutableDictionary *mark;
@property (strong, nonatomic) NSNumber *coefSum;
@property (strong, nonatomic) UIColor *color;
@property () BOOL isPremiere;
@property (weak, nonatomic) id delegate;

@end
