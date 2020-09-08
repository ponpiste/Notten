//
//  Appraisal.m
//  iLGL
//
//  Created by Sacha Bartholmé on 10/11/2014.
//  Copyright (c) 2014 The iLGL Team. All rights reserved.
//

#import "Appraisal.h"
#import "Report.h"

@implementation Appraisal

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:21.0];
    NSDictionary *attributes = @{NSFontAttributeName: font};
    [segmentedControl setTitleTextAttributes:attributes forState:UIControlStateNormal];
    
    NSArray *labels = @[label1,label2,label3,label4,label5,label6,label7,label8,label9];
    for (UILabel *label in labels)
        label.textColor = _color;
    
    self.tableView.tintColor = _color;
    
    segmentedControl.tintColor = _color;
    
    UIBarButtonItem *action = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(export)];
    UIBarButtonItem *forward = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"forward.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(forward)];
    self.navigationItem.rightBarButtonItems = @[forward,action];
    
    NSString *class = [_file componentsSeparatedByString:@"_"][0];
    if ([class hasPrefix:@"1M"] || [class hasPrefix:@"1C"] || [class hasPrefix:@"13"])
        titles = @[@"1. semester", @"2. semester", @"exam", @"schoolyear"];
    else
        titles = @[@"1. term", @"2. term", @"3. term", @"schoolyear"];
    
    [self calculate];
    barChart.noDataText = @"";
    NSTimer *timer;
    timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(graphs) userInfo:nil repeats:NO];
    
}

- (IBAction)didSelectSegment {
    
    if (isnan(generalAverage.doubleValue)) {
        
        barChart.hidden = YES;
        lineChart.hidden = YES;
        radarChart.hidden = YES;
        scatterChart.hidden = YES;
    }
    
    else if (segmentedControl.selectedSegmentIndex == 0) {
        
        barChart.hidden = NO;
        lineChart.hidden = YES;
        radarChart.hidden = YES;
        scatterChart.hidden = YES;
        if (barChart.data.xValCount == 0)
            [self setBarChart];
        
    } else if (segmentedControl.selectedSegmentIndex == 1) {
        
        barChart.hidden = YES;
        lineChart.hidden = NO;
        radarChart.hidden = YES;
        scatterChart.hidden = YES;
        if (lineChart.data.xValCount == 0)
            [self setLineChart];
        
    } else if (segmentedControl.selectedSegmentIndex == 2) {
        
        barChart.hidden = YES;
        lineChart.hidden = YES;
        scatterChart.hidden = YES;
        radarChart.hidden = NO;
        if (radarChart.data.xValCount == 0)
            [self setRadarChart];
        
    } else {
        
        barChart.hidden = YES;
        lineChart.hidden = YES;
        radarChart.hidden = YES;
        scatterChart.hidden = NO;
        if (scatterChart.data.xValCount == 0)
            [self setScatterChart];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
        
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [_delegate clickedBackWithIndex:_termIndex];
}

- (NSInteger)round:(double)value :(BOOL)bounds {
    
    if (bounds) {
        
        if (value > 60) value = 60;
        else if (value < 1) value = 1;
    }
    
    return ceil(value);
}

- (void)export {
    
    [self performSegueWithIdentifier:@"segue" sender:nil];
}

- (void)forward {
    
    _termIndex = (_termIndex + 1) % 4;
    [self.navigationController.navigationBar.backItem setTitle:NSLocalizedString(titles[_termIndex], nil)];
    [self calculate];
    [self graphs];
}

- (void)graphs {
    
    [barChart clear];
    [lineChart clear];
    [radarChart clear];
    [scatterChart clear];
    
    [self didSelectSegment];
}

- (void)calculate {
    
    NSMutableArray *averages = [NSMutableArray new];
    
    if (_termIndex == 3)
        for (NSDictionary *mark in _marks)
            [averages addObject:mark[@"average"]];
    else
        for (NSDictionary *mark in _marks)
            [averages addObject:mark[@"terms"][_termIndex][@"average"]];
    
    generalAverage = _generalAverages[_termIndex];
    
    if (!isnan(generalAverage.doubleValue) && _generalAverages) {
        
        [self.navigationItem.rightBarButtonItems[1]setEnabled:YES];
        
        NSNumberFormatter *formatter = [NSNumberFormatter new];
        formatter.roundingMode = NSNumberFormatterRoundCeiling;
        formatter.minimumIntegerDigits = 2;
        rounded = [[formatter stringFromNumber:generalAverage]integerValue];
        
        self.navigationItem.title = [formatter stringFromNumber:generalAverage];
        
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        formatter.roundingMode = NSNumberFormatterRoundHalfUp;
        formatter.minimumIntegerDigits = 0;
        formatter.minimumFractionDigits = 1;
        formatter.maximumFractionDigits = 12;
        averageLabel.text = [formatter stringFromNumber:generalAverage];
        
        NSInteger sum = 0,
        marksRemplies = 0,
        suffisantes = 0,
        insuffisantes = 0,
        compensables = 0,
        inferieursAVingt = 0,
        mainSubjects = 0;
        
        for (NSInteger i = 0; i < _marks.count; i++) {
            
            NSNumber *average = averages[i];
            NSDictionary *mark = _marks[i];
            
            if (!isnan(average.doubleValue)) {
                
                NSNumberFormatter *formatter = [NSNumberFormatter new];
                formatter.roundingMode = NSNumberFormatterRoundCeiling;
                NSString *numberString = [formatter stringFromNumber:average];
                average = [formatter numberFromString:numberString];
                
                if (average.integerValue < 1) {
                    average = [NSNumber numberWithInteger:1];
                } else if (average.integerValue > 60) {
                    average = [NSNumber numberWithInteger:60];
                }
                
                sum += average.integerValue;
                marksRemplies ++;
                
                if (average.integerValue >= 30) {
                    suffisantes ++;
                } else {
                    insuffisantes ++;
                    
                    if (![mark[@"name"]isEqualToString:@"Vie et société"]) {
                        
                        if (average.integerValue < 20) {
                            inferieursAVingt++;
                        } else {
                            
                            if ([mark[@"bf"]boolValue]) {
                                mainSubjects++;
                            } else {
                                compensables++;
                            }
                        }
                    }
                }
            }
        }
        
        pointsLabel.text = [NSString stringWithFormat:@"%i / %i", sum, marksRemplies * 60];
        insufficientLabel.text = [NSString stringWithFormat:@"%i / %i", insuffisantes, marksRemplies];
        
        BOOL compenser = mainSubjects < (_file.integerValue > 3?2:1) && inferieursAVingt == 0 && compensables + mainSubjects <= 2 && (compensables + mainSubjects == 1?rounded >= 36:YES) && (compensables + mainSubjects == 2?rounded >= 38:YES);
        
        compensateLabel.text = compensables + inferieursAVingt + mainSubjects > 0?compenser?NSLocalizedString(@"yes", nil):NSLocalizedString(@"no", nil):NSLocalizedString(@"no need", nil);
        
        if (_isPremiere && _termIndex == 2) {
            
            if (compensables + inferieursAVingt + mainSubjects > 0) {
                
                ratingLabel.text = NSLocalizedString(@"none", nil);
                
            } else {
                
                if (rounded <= 35) {
                    ratingLabel.text = NSLocalizedString(@"none", nil);
                } else if (rounded >= 36 && rounded <= 39) {
                    ratingLabel.text = @"Assez bien";
                } else if (rounded >= 40 && rounded <= 47) {
                    ratingLabel.text = @"Bien";
                } else if (rounded >= 48 && rounded <= 51) {
                    ratingLabel.text = @"Très Bien";
                } else {
                    ratingLabel.text = @"Excellent 🎉";
                }
            }
            
        } else {
            
            if (rounded <= 9) {
                ratingLabel.text = @"Très mauvais";
            } else if (rounded >= 10 && rounded <= 19) {
                ratingLabel.text = @"Mauvais";
            } else if (rounded >= 20 && rounded <= 29) {
                ratingLabel.text = @"Insuffisant";
            } else if (rounded >= 30 && rounded <= 39) {
                ratingLabel.text = @"Satisfaisant";
            } else if (rounded >= 40 && rounded <= 49) {
                ratingLabel.text = @"Bien";
            } else if (rounded >= 50 && rounded <= 51) {
                ratingLabel.text = @"Très bien";
            } else if (rounded >= 52 && rounded <= 59) {
                ratingLabel.text = @"Excellent  🎉";
            } else {
                ratingLabel.text = @"Summa cum laude";
            }
        }
        
        BOOL succes = insuffisantes == 0 || compenser || (_file.integerValue > 3?rounded >= 45:NO);
        BOOL echec = insuffisantes > (_isPremiere ? 3 : (double)marksRemplies/3) && marksRemplies > 8;
        
        if (_isPremiere && _termIndex == 2) {
            
            if (succes) {
                appraisalLabel.text = NSLocalizedString(@"admitted", nil);
            } else if (!echec) {
                appraisalLabel.text = NSLocalizedString(@"adjournment", nil);
            } else {
                appraisalLabel.text = NSLocalizedString(@"refused", nil);
            }
            
        } else {
            
            if (succes) {
                appraisalLabel.text = NSLocalizedString(@"success", nil);
            } else if (!echec) {
                appraisalLabel.text = NSLocalizedString(@"retake exam", nil);
            } else {
                appraisalLabel.text = NSLocalizedString(@"stay down", nil);
            }
        }
        
        averages = [NSMutableArray new];
        
        if (_termIndex == 3)
            for (NSDictionary *mark in _marks) {
                
                NSNumber *average = mark[@"average"];
                if (!isnan(average.doubleValue))
                    [averages addObject:[NSNumber numberWithInteger:[self round:average.floatValue :YES]]];
            }
        else
            for (NSDictionary *mark in _marks) {
                
                NSNumber *average = mark[@"terms"][_termIndex][@"average"];
                if (!isnan(average.doubleValue))
                    [averages addObject:[NSNumber numberWithInteger:[self round:average.floatValue :YES]]];
            }
        
        [averages sortUsingSelector:@selector(compare:)];
        
        NSNumber *median;
        if (averages.count % 2 == 0) {
            
            NSNumber *number1 = averages[averages.count / 2];
            NSNumber *number2 = averages[(averages.count / 2)-1];
            median = [NSNumber numberWithDouble:(number1.doubleValue + number2.doubleValue) / 2];
            
        } else median = averages[(NSInteger)(averages.count / 2)];
        
        formatter.maximumFractionDigits = 7;
        formatter.minimumFractionDigits = 0;
        medianLabel.text = [formatter stringFromNumber:median];
        
        sum = 0;
        for (NSNumber *number in averages)
            sum += number.integerValue;
        double average = sum / (double)averages.count;
        
        double distance = 0;
        for (NSNumber *number in averages)
            distance += (number.integerValue-average)*(number.integerValue-average);
        
        NSNumber *variance = [NSNumber numberWithDouble:distance/(double)averages.count];
        varianceLabel.text = [formatter stringFromNumber:variance];
        
        NSNumber *deviation = [NSNumber numberWithDouble:sqrt(variance.doubleValue)];
        deviationLabel.text = [formatter stringFromNumber:deviation];
        
    } else {
        
        self.navigationItem.title = @" ";
        [self.navigationItem.rightBarButtonItems[1]setEnabled:NO];
        
        averageLabel.text = @" ";
        pointsLabel.text = @" ";
        ratingLabel.text = @" ";
        
        compensateLabel.text = @" ";
        appraisalLabel.text = @" ";
        insufficientLabel.text = @" ";
        
        medianLabel.text = @" ";
        varianceLabel.text = @" ";
        deviationLabel.text = @" ";
    }
}

- (void)chartValueSelected:(ChartViewBase *)chartView entry:(ChartDataEntry *)entry dataSetIndex:(NSInteger)dataSetIndex highlight:(ChartHighlight *)highlight {
    
    ChartMarker *marker = [ChartMarker new];
    chartView.drawMarkers = YES;
    UIImage *image = [UIImage imageNamed:@"marker.png"];
    
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:21];
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0f);
    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];
    CGRect rect = CGRectMake(0,0,image.size.width,image.size.height);
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *att = @{NSFontAttributeName:font, NSForegroundColorAttributeName:[UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle};
    
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.roundingMode = NSNumberFormatterRoundCeiling;
    formatter.minimumIntegerDigits = 2;
    NSString *s = [formatter stringFromNumber:[NSNumber numberWithInteger:[self round:entry.value :chartView.tag == 0]]];
    
    [s drawInRect:rect withAttributes:att];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    marker.image = image;
    marker.offset = CGPointMake(marker.offset.x-marker.size.width/2.0, marker.offset.y-marker.size.height-2);
    chartView.marker = marker;

}

- (void)setBarChart {
    
    [barChart animateWithYAxisDuration:1 easingOption:ChartEasingOptionEaseOutBack];
    barChart.descriptionText = @"";
    barChart.legend.enabled = NO;
    barChart.rightAxis.enabled = NO;
    barChart.xAxis.labelRotationAngle = 270;
    barChart.highlightPerDragEnabled = NO;
    barChart.highlightPerTapEnabled = YES;
    barChart.doubleTapToZoomEnabled = NO;
    barChart.drawMarkers = YES;
    barChart.delegate = self;
    
    barChart.xAxis.drawAxisLineEnabled = NO;
    barChart.xAxis.drawGridLinesEnabled = NO;
    barChart.xAxis.labelPosition = XAxisLabelPositionBottomInside;
    barChart.xAxis.labelTextColor = [UIColor whiteColor];
    barChart.xAxis.labelFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    barChart.drawMarkers = NO;
    barChart.drawBordersEnabled = NO;
    
    barChart.leftAxis.axisMinValue = 0;
    barChart.leftAxis.axisMaxValue = 61;
    barChart.leftAxis.drawAxisLineEnabled = NO;
    barChart.leftAxis.drawGridLinesEnabled = NO;
    barChart.leftAxis.drawLabelsEnabled = NO;
    
    ChartLimitLine *line = [[ChartLimitLine alloc]initWithLimit:30];
    line.lineWidth = 1;
    line.lineColor = [UIColor redColor];
    [barChart.leftAxis addLimitLine:line];
    
    NSMutableArray *dataEntries = [NSMutableArray new];
    NSMutableArray *values = [NSMutableArray new];
    
    for (NSInteger i = 0; i<_marks.count; i++) {
        
        NSNumber *number = _termIndex == 3 ? _marks[i][@"average"] : _marks[i][@"terms"][_termIndex][@"average"];
        if (!isnan(number.doubleValue)) {
            
            [values addObject:@{@"x":_marks[i][@"code"], @"y": number}];
        }
    }
    
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"y"  ascending:YES];
    [values sortUsingDescriptors:@[descriptor]];
    
    NSMutableArray *xValues = [NSMutableArray new];
    
    for (NSInteger i = 0; i < values.count; i++) {
        
        [xValues addObject:values[i][@"x"]];
        
        double value = [values[i][@"y"]doubleValue];
        BarChartDataEntry *dataEntry = [[BarChartDataEntry alloc]initWithValue:[self round:value :YES] xIndex:i];
        [dataEntries addObject:dataEntry];
    }
    
    BarChartDataSet *set = [[BarChartDataSet alloc]initWithYVals:dataEntries label:@""];
    set.colors = @[[_color colorWithAlphaComponent:0.8],[_color colorWithAlphaComponent:0.4],[_color colorWithAlphaComponent:0.6]];
    BarChartData *data = [[BarChartData alloc]initWithXVals:xValues dataSet:set];
    [data setDrawValues:NO];
    barChart.data = data;
}

- (void)setLineChart {
    
    [lineChart animateWithYAxisDuration:1.5 easingOption:ChartEasingOptionEaseOutBounce];
    lineChart.descriptionText = @"";
    lineChart.legend.enabled = NO;
    lineChart.rightAxis.enabled = NO;
    lineChart.highlightPerDragEnabled = NO;
    lineChart.highlightPerTapEnabled = YES;
    lineChart.doubleTapToZoomEnabled = NO;
    lineChart.drawMarkers = YES;
    lineChart.delegate = self;
    
    lineChart.xAxis.drawAxisLineEnabled = NO;
    lineChart.xAxis.drawGridLinesEnabled = NO;
    lineChart.xAxis.labelPosition = XAxisLabelPositionBottom;
    lineChart.xAxis.labelTextColor = [UIColor darkGrayColor];
    lineChart.xAxis.labelFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    lineChart.xAxis.labelRotationAngle = 270;
    lineChart.drawMarkers = NO;
    lineChart.drawBordersEnabled = NO;
    
    lineChart.leftAxis.axisMinValue = -10;
    lineChart.leftAxis.axisMaxValue = 61;
    lineChart.leftAxis.drawAxisLineEnabled = NO;
    lineChart.leftAxis.drawGridLinesEnabled = NO;
    lineChart.leftAxis.drawLabelsEnabled = NO;
    
    ChartLimitLine *line = [[ChartLimitLine alloc]initWithLimit:30];
    line.lineWidth = 1;
    line.lineColor = [UIColor redColor];
    [lineChart.leftAxis addLimitLine:line];
    
    if (_termIndex == 3) {
        
        lineChart.legend.enabled = YES;
        lineChart.legend.drawInside = YES;
        lineChart.legend.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12];
        lineChart.legend.textColor = [UIColor darkGrayColor];
        lineChart.legend.form = ChartLegendFormLine;
        lineChart.legend.orientation = ChartLegendOrientationVertical;
        lineChart.legend.horizontalAlignment = ChartLegendHorizontalAlignmentRight;
        lineChart.legend.verticalAlignment = ChartLegendVerticalAlignmentCenter;
        
        NSArray *colors = @[[UIColor colorWithRed:0 green:0.5 blue:0 alpha:0.8], [UIColor orangeColor], [UIColor colorWithRed:0 green:200.0/255.0 blue:1 alpha:1]];
        
        NSMutableArray *values = [NSMutableArray new];
        
        for (NSInteger i = 0; i<_marks.count; i++) {
            
            NSNumber *number = _marks[i][@"average"];
            if (!isnan(number.doubleValue)) {
                
                [values addObject:@{@"x": _marks[i][@"code"], @"y": number, @"z":@(i)}];
            }
        }
        
        NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"y"  ascending:YES];
        [values sortUsingDescriptors:@[descriptor]];
        
        NSMutableArray *xValues = [NSMutableArray new];
        for (NSInteger i = 0; i < values.count; i++)
            [xValues addObject:values[i][@"x"]];
        
        NSMutableArray *sets = [NSMutableArray new];
        
        for (NSInteger term = 0; term < 3; term++) {
            
            NSMutableArray *dataEntries = [NSMutableArray new];
            
            for (NSInteger i = 0; i < values.count; i++) {
                
                NSInteger k = [values[i][@"z"]integerValue];
                NSNumber *number = _marks[k][@"terms"][term][@"average"];
                if (isnan(number.doubleValue))
                    continue;
                
                ChartDataEntry *dataEntry = [[ChartDataEntry alloc]initWithValue:[self round:number.doubleValue :YES] xIndex:i];
                [dataEntries addObject:dataEntry];
            }
            
            LineChartDataSet *set = [[LineChartDataSet alloc]initWithYVals:dataEntries label:[NSString stringWithFormat:@"%d. Tr",term+1]];
            set.colors = @[colors[term]];
            set.circleColors = set.colors;
            [sets addObject:set];
        }
        
        LineChartData *data = [[LineChartData alloc]initWithXVals:xValues dataSets:sets];
        [data setDrawValues:NO];
        lineChart.data = data;
        
    } else {
        
        NSMutableArray *dataEntries = [NSMutableArray new];
        NSMutableArray *values = [NSMutableArray new];
        
        for (NSInteger i = 0; i<_marks.count; i++) {
            
            NSNumber *number = _marks[i][@"terms"][_termIndex][@"average"];
            if (!isnan(number.doubleValue)) {
                
                [values addObject:@{@"x": _marks[i][@"code"], @"y": number}];
            }
        }
        
        NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"y"  ascending:YES];
        [values sortUsingDescriptors:@[descriptor]];
        
        NSMutableArray *xValues = [NSMutableArray new];
        
        for (NSInteger i = 0; i < values.count; i++) {
            
            [xValues addObject:values[i][@"x"]];
            
            double value = [values[i][@"y"]doubleValue];
            ChartDataEntry *dataEntry = [[ChartDataEntry alloc]initWithValue:[self round:value :YES] xIndex:i];
            [dataEntries addObject:dataEntry];
        }
        
        LineChartDataSet *set = [[LineChartDataSet alloc]initWithYVals:dataEntries label:@""];
         set.colors = @[_color];
        set.circleColors = set.colors;
         LineChartData *data = [[LineChartData alloc]initWithXVals:xValues dataSet:set];
         [data setDrawValues:NO];
         lineChart.data = data;
    }
}

- (void)setRadarChart {
    
    [radarChart animateWithXAxisDuration:1 yAxisDuration:1];
    radarChart.descriptionText = @"";
    radarChart.legend.enabled = NO;
    radarChart.drawWeb = NO;
    radarChart.highlightPerTapEnabled = YES;
    radarChart.drawMarkers = YES;
    radarChart.delegate = self;
    
    radarChart.yAxis.drawLabelsEnabled = NO;
    radarChart.yAxis.axisMaxValue = 60;
    radarChart.yAxis.axisMinValue = 0;
    
    radarChart.xAxis.drawAxisLineEnabled = NO;
    radarChart.xAxis.drawGridLinesEnabled = NO;
    radarChart.xAxis.labelPosition = XAxisLabelPositionBottom;
    radarChart.xAxis.labelTextColor = [UIColor darkGrayColor];
    radarChart.xAxis.labelFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    radarChart.drawMarkers = NO;
    
    ChartLimitLine *line = [[ChartLimitLine alloc]initWithLimit:30];
    line.lineWidth = 1;
    line.lineColor = [UIColor redColor];
    [radarChart.yAxis addLimitLine:line];
    
    if (_termIndex == 3) {
        
        NSMutableArray *xValues = [NSMutableArray new];
        NSMutableArray *indexes = [NSMutableArray new];
        for (NSInteger i = 0; i < _marks.count; i++)
            
            if (!isnan([_marks[i][@"average"]doubleValue])) {
                
                [xValues addObject:_marks[i][@"code"]];
                [indexes addObject:@(i)];
            }
        
        radarChart.legend.enabled = YES;
        radarChart.legend.drawInside = YES;
        radarChart.legend.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12];
        radarChart.legend.textColor = [UIColor darkGrayColor];
        radarChart.legend.form = ChartLegendFormLine;
        radarChart.legend.orientation = ChartLegendOrientationVertical;
        radarChart.legend.horizontalAlignment = ChartLegendHorizontalAlignmentRight;
        radarChart.legend.verticalAlignment = ChartLegendVerticalAlignmentBottom;

        NSMutableArray *sets = [NSMutableArray new];
        NSArray *colors = @[[UIColor colorWithRed:0 green:0.5 blue:0 alpha:0.8], [UIColor orangeColor], [UIColor colorWithRed:0 green:200.0/255.0 blue:1 alpha:1]];
        NSArray *fillColors = @[[UIColor colorWithRed:0 green:0.5 blue:0 alpha:0.3], [UIColor colorWithRed:1 green:0.5 blue:0 alpha:0.5], [UIColor colorWithRed:0 green:200.0/255.0 blue:1 alpha:0.5]];
        
        for (NSInteger term = 0; term < 3; term++) {
            
            NSMutableArray *dataEntries = [NSMutableArray new];
            
            for (NSInteger i = 0; i < indexes.count; i++) {
                
                NSInteger k = [indexes[i]integerValue];
                NSNumber *number = _marks[k][@"terms"][term][@"average"];
                if (isnan(number.doubleValue))
                    number = _marks[k][@"average"];
                
                ChartDataEntry *dataEntry = [[ChartDataEntry alloc]initWithValue:[self round:number.doubleValue :YES] xIndex:i];
                [dataEntries addObject:dataEntry];
            }
            
            RadarChartDataSet *set = [[RadarChartDataSet alloc]initWithYVals:dataEntries label:[NSString stringWithFormat:@"%d. Tr",term+1]];
            set.colors = @[colors[term]];
            set.drawFilledEnabled = YES;
            set.fillColor = fillColors[term];
            [sets addObject:set];
        }
        
        RadarChartData *data = [[RadarChartData alloc]initWithXVals:xValues dataSets:sets];
        [data setDrawValues:NO];
        radarChart.data = data;
        
    } else {
        
        NSMutableArray *dataEntries = [NSMutableArray new];
        NSMutableArray *xValues = [NSMutableArray new];
        
        for (NSInteger i = 0; i < _marks.count; i++) {
            
            NSNumber *number = _marks[i][@"terms"][_termIndex][@"average"];
            
            if (!isnan(number.doubleValue)) {
                
                ChartDataEntry *dataEntry = [[ChartDataEntry alloc]initWithValue:[self round:number.doubleValue :YES] xIndex:i];
                [dataEntries addObject:dataEntry];
                [xValues addObject:_marks[i][@"code"]];
            }
        }
        
        if (xValues.count < 2) {
            
            radarChart.hidden = YES;
            return;
        }
        
        RadarChartDataSet *set = [[RadarChartDataSet alloc]initWithYVals:dataEntries label:@""];
        set.colors = @[_color];
        set.drawFilledEnabled = YES;
        set.fillColor = [_color colorWithAlphaComponent:0.3];
        RadarChartData *data = [[RadarChartData alloc]initWithXVals:xValues dataSet:set];
        [data setDrawValues:NO];
        radarChart.data = data;
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    
    NSString *title, *message;
    
    if (indexPath.row == 0) {
        
        title = NSLocalizedString(@"median", nil);
        message = NSLocalizedString(@"median info", nil);
        
    } else if (indexPath.row == 1) {
        
        title = NSLocalizedString(@"variance", nil);
        message = NSLocalizedString(@"variance info", nil);
        
    } else {
        
        title = NSLocalizedString(@"standard deviation", nil);
        message = NSLocalizedString(@"standard deviation info", nil);
    }
    
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alertView show];
}

- (void)setScatterChart {
    
    [scatterChart animateWithXAxisDuration:0.7];
    scatterChart.tag = 1;
    scatterChart.descriptionText = @"";
    scatterChart.legend.enabled = NO;
    scatterChart.rightAxis.enabled = NO;
    scatterChart.highlightPerDragEnabled = NO;
    scatterChart.highlightPerTapEnabled = YES;
    scatterChart.doubleTapToZoomEnabled = NO;
    scatterChart.drawMarkers = YES;
    scatterChart.delegate = self;
    
    scatterChart.xAxis.drawAxisLineEnabled = NO;
    scatterChart.xAxis.drawGridLinesEnabled = NO;
    scatterChart.xAxis.labelPosition = XAxisLabelPositionBottom;
    scatterChart.xAxis.labelTextColor = [UIColor darkGrayColor];
    scatterChart.xAxis.labelFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    scatterChart.xAxis.labelRotationAngle = 270;
    scatterChart.drawMarkers = NO;
    scatterChart.drawBordersEnabled = NO;
    
    scatterChart.leftAxis.axisMinValue = 0;
    scatterChart.leftAxis.axisMaxValue = 64;
    scatterChart.leftAxis.drawAxisLineEnabled = NO;
    scatterChart.leftAxis.drawGridLinesEnabled = NO;
    scatterChart.leftAxis.drawLabelsEnabled = NO;
    
    ChartLimitLine *line = [[ChartLimitLine alloc]initWithLimit:30];
    line.lineWidth = 1;
    line.lineColor = [UIColor redColor];
    [scatterChart.leftAxis addLimitLine:line];
    
    NSMutableArray *values = [NSMutableArray new];
    
    for (NSInteger i = 0; i < _marks.count; i++) {
        
        NSNumber *average = _termIndex == 3 ? _marks[i][@"average"] : _marks[i][@"terms"][_termIndex][@"average"];
        
        if (!isnan(average.doubleValue)) {
            
            [values addObject:@{@"x": _marks[i][@"code"], @"y": average, @"z": @(i)}];
        }
        
    }
    
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"y"  ascending:YES];
    [values sortUsingDescriptors:@[descriptor]];
    
    NSMutableArray *xValues = [NSMutableArray new];
    for (NSInteger i = 0; i < values.count; i++)
        [xValues addObject:values[i][@"x"]];
    
    if (_termIndex == 3) {
        
        scatterChart.legend.enabled = YES;
        scatterChart.legend.drawInside = YES;
        scatterChart.legend.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12];
        scatterChart.legend.textColor = [UIColor darkGrayColor];
        scatterChart.legend.form = ChartLegendFormLine;
        scatterChart.legend.orientation = ChartLegendOrientationVertical;
        scatterChart.legend.horizontalAlignment = ChartLegendHorizontalAlignmentRight;
        scatterChart.legend.verticalAlignment = ChartLegendVerticalAlignmentCenter;
        
        NSMutableArray *sets = [NSMutableArray new];
        NSArray *colors = @[[UIColor colorWithRed:0 green:0.5 blue:0 alpha:1], [UIColor orangeColor], [UIColor colorWithRed:0 green:200.0/255.0 blue:1 alpha:1]];
        
        for (NSInteger term = 0; term < 3; term++) {
            
            NSMutableArray *dataEntries = [NSMutableArray new];
            
            for (NSInteger i = 0; i < values.count; i++) {
                
                NSInteger k = [values[i][@"z"]integerValue];
                
                if ([[_marks[k]allKeys]containsObject:@"sub subjects"]) {
                    
                    for (NSDictionary *subject in _marks[k][@"sub subjects"]) {
                        
                        NSArray *marksArray = subject[@"terms"][term][@"marks"];
                        
                        for (NSInteger j = 0; j < marksArray.count; j++) {
                            
                            NSDictionary *m = marksArray[j];
                            double value = [m[@"mark"]doubleValue] / [m[@"max"]doubleValue] * 60.0;
                            
                            ChartDataEntry *dataEntry = [[ChartDataEntry alloc]initWithValue:value xIndex:i];
                            [dataEntries addObject:dataEntry];
                        }
                    }
                    
                } else {
                    
                    NSArray *marksArray = _marks[k][@"terms"][term][@"marks"];
                    
                    for (NSInteger j = 0; j < marksArray.count; j++) {
                        
                        NSDictionary *m = marksArray[j];
                        double value = [m[@"mark"]doubleValue] / [m[@"max"]doubleValue] * 60.0;
                        
                        ChartDataEntry *dataEntry = [[ChartDataEntry alloc]initWithValue:value xIndex:i];
                        [dataEntries addObject:dataEntry];
                    }
                }
            }
            ScatterChartDataSet *set = [[ScatterChartDataSet alloc]initWithYVals:dataEntries label:[NSString stringWithFormat:@"%d. Tr",term+1]];
            set.colors = @[colors[term]];
            set.scatterShape = ScatterShapeCross;
            set.scatterShapeSize = 20;
            [sets addObject:set];
            
        }
        
        ScatterChartData *data = [[ScatterChartData alloc]initWithXVals:xValues dataSets:sets];
        [data setDrawValues:NO];
        scatterChart.data = data;
        
    } else {
        
        NSMutableArray *dataEntries = [NSMutableArray new];
        
        for (NSInteger i = 0; i < values.count; i++) {
            
            NSInteger k = [values[i][@"z"]integerValue];
            
            if ([[_marks[k]allKeys]containsObject:@"sub subjects"]) {
                
                for (NSDictionary *subject in _marks[k][@"sub subjects"]) {
                    
                    NSArray *marksArray = subject[@"terms"][_termIndex][@"marks"];
                    
                    for (NSInteger j = 0; j < marksArray.count; j++) {
                        
                        NSDictionary *m = marksArray[j];
                        double value = [m[@"mark"]doubleValue] / [m[@"max"]doubleValue] * 60.0;
                        
                        ChartDataEntry *dataEntry = [[ChartDataEntry alloc]initWithValue:value xIndex:i];
                        [dataEntries addObject:dataEntry];
                    }
                }
                
            } else {
                
                NSArray *marksArray = _marks[k][@"terms"][_termIndex][@"marks"];
                
                for (NSInteger j = 0; j < marksArray.count; j++) {
                    
                    NSDictionary *m = marksArray[j];
                    double value = [m[@"mark"]doubleValue] / [m[@"max"]doubleValue] * 60.0;
                    
                    ChartDataEntry *dataEntry = [[ChartDataEntry alloc]initWithValue:value xIndex:i];
                    [dataEntries addObject:dataEntry];
                }
            }
        }
        
        ScatterChartDataSet *set = [[ScatterChartDataSet alloc]initWithYVals:dataEntries label:@""];
        set.colors = @[_color];
        ScatterChartData *data = [[ScatterChartData alloc]initWithXVals:xValues dataSet:set];
        set.scatterShape = ScatterShapeCross;
        set.scatterShapeSize = 20;
        [data setDrawValues:NO];
        scatterChart.data = data;
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"segue"]) {
        
        UINavigationController *navigation = segue.destinationViewController;
        Report *report = (Report *)navigation.topViewController;
        report.color = _color;
    }
}

@end
