//
//  BonusCell.h
//  iLGL
//
//  Created by Sacha Bartholmé on 22/11/2014.
//  Copyright (c) 2014 The iLGL Team. All rights reserved.
//

@protocol BonusCellDelegate 

- (void)didEditBonus:(NSNumber *)bonus fromIndexPath:(NSIndexPath *)indexPath;

@end

@interface BonusCell : UITableViewCell

@property (weak, nonatomic) id delegate;
@property (weak, nonatomic) IBOutlet UILabel *bonusLabel;
@property (weak, nonatomic) IBOutlet UIStepper *stepper;

@end
