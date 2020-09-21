//
//  BonusCell.m
//  iLGL
//
//  Created by Sacha Bartholmé on 22/11/2014.
//  Copyright (c) 2014 The iLGL Team. All rights reserved.
//

#import "BonusCell.h"

@implementation BonusCell

- (IBAction)didStepp {
    
    [_delegate didEditBonus:[NSNumber numberWithInteger:_stepper.value] fromIndexPath:[(UITableView *)self.superview.superview indexPathForCell: self]];
    
    return;
}

@end
