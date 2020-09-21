//
//  SubjectCombined.m
//  Notten
//
//  Created by Sacha Bartholmé on 7/16/16.
//  Copyright © 2016 Sacha Bartholmé. All rights reserved.
//

#import "SubjectCombined.h"

@implementation SubjectCombined

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.topItem.title = _mark[@"code"];
    [self updateTitle];
    
    influence = [_mark[@"coefficient"]doubleValue]/_coefSum.doubleValue;
    influencing = [NSNumber numberWithInteger:1];
    
    desired = [NSNumber numberWithInteger:30];
    needed = [NSMutableArray arrayWithCapacity:[_mark[@"sub subjects"]count]];
    
    [self neededForDesired];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateTitle];
    
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)neededForDesired {
    
    for (NSInteger i = 0; i < [_mark[@"sub subjects"]count]; i++) {
        
        double sum = desired.doubleValue-1;
        double pond = 1;
        
        for (NSInteger j = 0; j < [_mark[@"sub subjects"]count]; j++) {
            
            if (j != i) {
                
                double num = [_mark[@"sub subjects"][j][@"pondNum"]doubleValue];
                double den = [_mark[@"sub subjects"][j][@"pondDen"]doubleValue];
                double average = _termIndex == 3 ? [_mark[@"sub subjects"][j][@"average"]doubleValue] : [_mark[@"sub subjects"][j][@"terms"][_termIndex][@"average"]doubleValue];
                
                if (!isnan(average)) {
                    
                    average = (double)[self round:average :YES];
                    pond -= num / den;
                    sum -= average * num / den;
                }
            }
        }
        
        sum /= pond;
        sum += 0.001;
        needed[i] = [NSNumber numberWithInteger:ceil(sum)];
    }
}

- (NSInteger)round:(double)value :(BOOL)bounds {
    
    if (bounds) {
        
        if (value > 60) value = 60;
        else if (value < 1) value = 1;
    }
    
    return ceil(value);
}

- (void)updateTitle {
    
    NSNumber *average = _termIndex == 3 ? _mark[@"average"] : _mark[@"terms"][_termIndex][@"average"];
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.usesGroupingSeparator = NO;
    formatter.maximumFractionDigits = 3;
    formatter.minimumFractionDigits = 1;
    
    [titleButton setTitle:isnan(average.doubleValue)?@" ":[formatter stringFromNumber:average] forState:UIControlStateNormal];
}

- (void)averages {
    
    for (NSInteger i = 0; i < 3; i++) {
        
        double sum = 0.0;
        double max = 0.0;
        
        for (NSDictionary *subject in _mark[@"sub subjects"]) {
            
            double num = [subject[@"pondNum"]doubleValue];
            double den = [subject[@"pondDen"]doubleValue];
            float average;
            
            if (i == 2 && _isPremiere) {
                
                NSArray *array = subject[@"terms"][i][@"marks"];
                double sum2 = 0.0;
                double max2 = 0.0;
                
                for (NSDictionary *dictionary in array) {
                    
                    double num2 = [dictionary[@"pondNum"]doubleValue];
                    double den2 = [dictionary[@"pondDen"]doubleValue];
                    
                    sum2 += [dictionary[@"mark"]doubleValue] * num2 / den2;
                    max2 += [dictionary[@"max"]doubleValue] * num2 / den2;
                }
                
                sum2 /= max2;
                sum2 *= 60.0;
                sum2 += [subject[@"terms"][i][@"bonus"]integerValue];
                
                average = sum2;
                
            } else {
                
                average = [subject[@"terms"][i][@"average"]floatValue];
            }
            
            if (!isnan(average)) {
                
                sum += (double)[self round:average :YES] * num / den;
                max += 60.0 * num / den;
            }
        }
        
        sum /= max;
        sum *= 60.0;
        _mark[@"terms"][i][@"average"] = [NSNumber numberWithDouble:sum];
    }
    
    double sum = 0.0;
    double denominator = 0.0;
    
    for (NSInteger i = 0; i < (_isPremiere ? 2 : 3); i++) {
        
        NSNumber *average = _mark[@"terms"][i][@"average"];
        
        if (!isnan(average.doubleValue)) {
            
            sum += [self round:average.floatValue :YES];
            denominator += 60.0;
        }
    }
    sum /= denominator;
    sum *= 60.0;
    _mark[@"average"] = [NSNumber numberWithDouble:sum];
    
    if (_isPremiere) {
        
        double exam = [_mark[@"terms"][2][@"average"]doubleValue];
        if (!isnan(exam) && !isnan(sum)) {
            
            sum = (2.0*[self round:exam :YES] + [self round:sum :YES]) / 3.0;
            _mark[@"terms"][2][@"average"] = [NSNumber numberWithDouble:sum];
        }
    }
}

- (void)didEditMark:(NSDictionary *)newMark {
    
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    
    _mark[@"sub subjects"][indexPath.section] = newMark;
    [self averages];
    [self neededForDesired];
    
    [self.tableView reloadData];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    
    [_delegate didEditMark:_mark];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return [_mark[@"sub subjects"]count]+1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section != [tableView numberOfSections]-1) {
        
        if (indexPath.row == 0) {
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
            
            cell.textLabel.text = _mark[@"sub subjects"][indexPath.section][@"name"];
            cell.textLabel.textColor = _color;
            
            NSNumber *average = _termIndex == 3 ? _mark[@"sub subjects"][indexPath.section][@"average"] : _mark[@"sub subjects"][indexPath.section][@"terms"][_termIndex][@"average"];
        
            if (isnan(average.doubleValue)) cell.detailTextLabel.text = @" ";
            else {
                
                NSNumberFormatter *formatter = [NSNumberFormatter new];
                formatter.minimumIntegerDigits = 2;
                cell.detailTextLabel.text = [formatter stringFromNumber:[NSNumber numberWithInteger:[self round:average.floatValue :YES]]];
            }
                        
            return cell;
            
        } else if (indexPath.row == 1) {
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ponderationCell"];
            
            cell.textLabel.text = NSLocalizedString(@"ponderation", nil);
            cell.textLabel.textColor = _color;
            
            NSInteger pondNum = [_mark[@"sub subjects"][indexPath.section][@"pondNum"]integerValue];
            NSInteger pondDen = [_mark[@"sub subjects"][indexPath.section][@"pondDen"]integerValue];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d / %d",pondNum,pondDen];
            
            return cell;
            
        } else {
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"neededCell"];
                        
            NSNumberFormatter *formatter = [NSNumberFormatter new];
            formatter.numberStyle = NSNumberFormatterDecimalStyle;
            formatter.usesGroupingSeparator = NO;
            formatter.maximumFractionDigits = 10;
            
            cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"needed for",nil),[formatter stringFromNumber:desired]];
            cell.detailTextLabel.text = [formatter stringFromNumber:needed[indexPath.section]];
            cell.textLabel.textColor = _color;
            
            return cell;
        }
        
    } else {
        
        if (indexPath.row == 0) {
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"neededCell"];
            
            NSNumberFormatter *formatter = [NSNumberFormatter new];
            formatter.numberStyle = NSNumberFormatterDecimalStyle;
            formatter.maximumFractionDigits = 13;
            
            cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(influencing.integerValue == 1 ? @"point" : @"points", nil),[formatter stringFromNumber:influencing]];
            cell.textLabel.textColor = _color;
            cell.detailTextLabel.text = [formatter stringFromNumber:[NSNumber numberWithDouble:influence]];
            
            return cell;
            
        } else if (indexPath.row == 1) {
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ponderationCell"];
            
            NSNumberFormatter *formatter = [NSNumberFormatter new];
            formatter.roundingMode = NSNumberFormatterRoundHalfUp;
            formatter.maximumFractionDigits = 3;
            
            cell.textLabel.text = NSLocalizedString(@"coefficient", nil);
            cell.textLabel.textColor = _color;
            cell.detailTextLabel.text = [formatter stringFromNumber:[NSNumber numberWithDouble:[_mark[@"coefficient"]doubleValue]]];
            
            return cell;
            
        } else {
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ponderationCell"];
            
            cell.textLabel.text = NSLocalizedString(@"main subject", nil);
            cell.textLabel.textColor = _color;
            cell.detailTextLabel.text = [_mark[@"bf"]boolValue]?NSLocalizedString(@"yes", nil):NSLocalizedString(@"no", nil);
            
            return cell;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section != [tableView numberOfSections]-1) {
        
        if (indexPath.row == 0) {
            
            NSString *identifier = _termIndex == 3 ? @"subjectYear" : @"subjectTerm";
            [self performSegueWithIdentifier:identifier sender:nil];
            
        } else if (indexPath.row == 2) {
            
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"required", nil) message:NSLocalizedString(@"required combined info", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@"OK", nil];
            
            alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            
            UITextField *textField = [alertView textFieldAtIndex:0];
            textField.keyboardType = UIKeyboardTypeDecimalPad;
            textField.textAlignment = NSTextAlignmentCenter;
            
            alertView.tag = 0;
            [alertView show];
        }
        
    } else if (indexPath.row == 0) {
        
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"influence", nil) message:NSLocalizedString(@"influence info", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@"OK", nil];
        
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        
        NSNumberFormatter *formatter = [NSNumberFormatter new];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        formatter.usesGroupingSeparator = NO;
        
        UITextField *textField = [alertView textFieldAtIndex:0];
        textField.keyboardType = UIKeyboardTypeDecimalPad;
        textField.textAlignment = NSTextAlignmentCenter;
        
        alertView.tag = 1;
        [alertView show];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return indexPath.section != [tableView numberOfSections]-1 && indexPath.row == 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (_termIndex == 3) {
        
        for (NSInteger i = 0; i < 3; i++) {
            
            [_mark[@"sub subjects"][indexPath.section][@"terms"][i][@"marks"] removeAllObjects];
            _mark[@"sub subjects"][indexPath.section][@"terms"][i][@"bonus"] = [NSNumber numberWithInteger:0];
            _mark[@"sub subjects"][indexPath.section][@"terms"][i][@"average"] = [NSNumber numberWithDouble:0/0.0];
        }
        
        _mark[@"sub subjects"][indexPath.section][@"average"] = [NSNumber numberWithDouble:0/0.0];
        
    } else {
        
        [_mark[@"sub subjects"][indexPath.section][@"terms"][_termIndex][@"marks"] removeAllObjects];
        _mark[@"sub subjects"][indexPath.section][@"terms"][_termIndex][@"bonus"] = [NSNumber numberWithInteger:0];
        _mark[@"sub subjects"][indexPath.section][@"terms"][_termIndex][@"average"] = [NSNumber numberWithDouble:0/0.0];
    }
    
    [self averages];
    [self neededForDesired];
    [self updateTitle];
    [tableView reloadData];
    [tableView setEditing:NO];
    [_delegate didEditMark:_mark];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return NSLocalizedString(@"reset", nil);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if (section == [tableView numberOfSections]-1) return NSLocalizedString(@"influence header", nil);
    return @"";
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"subjectTerm"]) {
        
        SubjectTerm *subjectTerm = segue.destinationViewController;
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        subjectTerm.coefSum = _coefSum;
        subjectTerm.mark = _mark[@"sub subjects"][indexPath.section];
        subjectTerm.termIndex = _termIndex;
        subjectTerm.braco = YES;
        subjectTerm.color = _color;
        subjectTerm.isPremiere = _isPremiere;
        subjectTerm.delegate = self;
        
    } else {
        
        SubjectYear *subjectYear = segue.destinationViewController;
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        subjectYear.mark = _mark[@"sub subjects"][indexPath.section];;
        subjectYear.braco = YES;
        subjectYear.color = _color;
        subjectYear.isPremiere = _isPremiere;
        subjectYear.delegate = self;
    }
}

# pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    
    if (buttonIndex == 1) {
        
        if (alertView.tag == 0) {
            
            UITextField *textField = [alertView textFieldAtIndex:0];
            
            NSNumberFormatter *formatter = [NSNumberFormatter new];
            desired = [formatter numberFromString:textField.text];
            [self neededForDesired];
            
            [self.tableView reloadData];
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            
        } else if (alertView.tag == 1) {
            
            UITextField *textField = [alertView textFieldAtIndex:0];
            
            NSNumberFormatter *formatter = [NSNumberFormatter new];
            influencing = [formatter numberFromString:textField.text];
            influence = influencing.doubleValue * [_mark[@"coefficient"]doubleValue]/_coefSum.doubleValue;
            [self.tableView reloadData];
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    
    UITextField *textField = [alertView textFieldAtIndex:0];
    
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    NSNumber *number = [formatter numberFromString:textField.text];
    
    return number && number.doubleValue == number.integerValue && abs(number.intValue) < 100000;
}

@end
