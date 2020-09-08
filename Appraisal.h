//
//  Appraisal.h
//  iLGL
//
//  Created by Sacha Bartholmé on 10/11/2014.
//  Copyright (c) 2014 The iLGL Team. All rights reserved.
//

#import "Notten-Swift.h"

@protocol AppraisalDelegate <NSObject>

- (void)clickedBackWithIndex:(NSInteger)newIndex;

@end

@interface Appraisal : UITableViewController <ChartViewDelegate>

{
    NSArray *titles;
    NSInteger rounded;
    NSNumber *generalAverage;
    NSMutableString *exportString;
    
    IBOutlet UILabel *label1;
    IBOutlet UILabel *label2;
    IBOutlet UILabel *label3;
    IBOutlet UILabel *label4;
    IBOutlet UILabel *label5;
    IBOutlet UILabel *label6;
    IBOutlet UILabel *label7;
    IBOutlet UILabel *label8;
    IBOutlet UILabel *label9;
    
    IBOutlet UILabel *medianLabel;
    IBOutlet UILabel *varianceLabel;
    IBOutlet UILabel *deviationLabel;
    
    IBOutlet UILabel *averageLabel;
    IBOutlet UILabel *ratingLabel;
    IBOutlet UILabel *pointsLabel;
    
    IBOutlet UILabel *insufficientLabel;
    IBOutlet UILabel *compensateLabel;
    IBOutlet UILabel *appraisalLabel;
    
    IBOutlet UISegmentedControl *segmentedControl;
    IBOutlet BarChartView *barChart;
    IBOutlet LineChartView *lineChart;
    IBOutlet RadarChartView *radarChart;
    IBOutlet ScatterChartView *scatterChart;
}

@property (assign, nonatomic) NSInteger termIndex;
@property (strong, nonatomic) NSArray *generalAverages;
@property (strong, nonatomic) NSArray *marks;
@property (strong, nonatomic) NSString *file;
@property (strong, nonatomic) UIColor *color;
@property () BOOL isPremiere;
@property (weak, nonatomic) id delegate;

@end
