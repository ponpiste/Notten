//
//  ColorCell.m
//  Notten
//
//  Created by Sacha Bartholmé on 7/18/16.
//  Copyright © 2016 Sacha Bartholmé. All rights reserved.
//

#import "ColorCell.h"

@implementation ColorCell

- (IBAction)didChangeRed {
    
    [_delegate didEditColor:redSlider.value :greenSlider.value :blueSlider.value];
}

- (IBAction)didChangeGreen {
    
    [_delegate didEditColor:redSlider.value :greenSlider.value :blueSlider.value];
}

- (IBAction)didChangeBlue {
    
    [_delegate didEditColor:redSlider.value :greenSlider.value :blueSlider.value];
}

- (void)setRed:(NSInteger)red {
    
    redSlider.value = red;
}

- (void)setGreen:(NSInteger)green {
    
    greenSlider.value = green;
}

- (void)setBlue:(NSInteger)blue {
    
    blueSlider.value = blue;
}

@end
