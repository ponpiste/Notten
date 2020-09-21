//
//  ColorCell.h
//  Notten
//
//  Created by Sacha Bartholmé on 7/18/16.
//  Copyright © 2016 Sacha Bartholmé. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ColorCellDelegate

- (void)didEditColor:(NSInteger)newRed :(NSInteger)newGreen :(NSInteger)newBlue;

@end

@interface ColorCell : UITableViewCell

{    
    IBOutlet UISlider *redSlider;
    IBOutlet UISlider *greenSlider;
    IBOutlet UISlider *blueSlider;
}

@property (weak, nonatomic) id delegate;

- (void)setRed:(NSInteger)red;
- (void)setGreen:(NSInteger)green;
- (void)setBlue:(NSInteger)blue;

@end
