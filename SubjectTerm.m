//
//  SubjectTerm.m
//  iLGL
//
//  Created by Sacha Bartholmé on 20/11/2014.
//  Copyright (c) 2014 The iLGL Team. All rights reserved.
//

#import "SubjectTerm.h"

@implementation SubjectTerm

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.topItem.title = _mark[@"code"];
    [self updateTitle];
    
    desiredYear = [NSNumber numberWithInteger:30];
    neededTrim = [self neededTermForDesiredYear];
    desiredTrim = neededTrim;
    neededTest = [self neededMarkForDesiredTrim:desiredTrim];
    
    influence = [_mark[@"coefficient"]doubleValue]/_coefSum.doubleValue;
    influencing = [NSNumber numberWithInteger:1];
}

- (NSNumber*)neededMarkForDesiredTrim:(NSNumber*)desiredMark {
    
    double sum = 0;
    for (NSDictionary *test in _mark[@"terms"][_termIndex][@"marks"]) {
        
        double num = [test[@"pondNum"]doubleValue];
        double den = [test[@"pondDen"]doubleValue];
        sum += [test[@"max"]doubleValue] * num / den;
    }
    sum += 60;
    sum *= (desiredTrim.doubleValue-[_mark[@"terms"][_termIndex][@"bonus"]integerValue]-1)/60.0;
    
    for (NSDictionary *test in _mark[@"terms"][_termIndex][@"marks"]) {
        
        double num = [test[@"pondNum"]doubleValue];
        double den = [test[@"pondDen"]doubleValue];
        sum -= [test[@"mark"]doubleValue] * num / den;
    }
    sum += 0.001;
    
    return [NSNumber numberWithInteger:ceil(sum)];
}

- (NSNumber*)neededTermForDesiredYear {
    
    if (_termIndex == 2 && _isPremiere) {
        
        double sum;
        
        if (isnan([_mark[@"average"]doubleValue]))
            sum = desiredYear.doubleValue-1;
        else
            sum = (3.0*(desiredYear.doubleValue-1)-[self round:[_mark[@"average"]doubleValue] :YES])/2.0;
        
        sum += 0.001;
        return [NSNumber numberWithInteger:ceil(sum)];
        
    } else {
        
        double sum = desiredYear.integerValue-1;
        
        for (NSInteger i = 0; i < (_isPremiere? 2 : 3); i++) {
            
            NSNumber *number = _mark[@"terms"][i][@"average"];
            
            if (!isnan(number.doubleValue) && _termIndex != i)
                sum += desiredYear.doubleValue-1-[self round:number.doubleValue :YES];
        }
        
        sum += 0.001;
        return [NSNumber numberWithInteger:ceil(sum)];
    }
}

- (NSInteger)round:(double)value :(BOOL)bounds {
    
    if (bounds) {
        
        if (value > 60) value = 60;
        else if (value < 1) value = 1;
    }
    
    return ceil(value);
}

- (void)averages {
    
    for (NSInteger i = 0; i < 3; i++) {
        
        NSArray *array = _mark[@"terms"][i][@"marks"];
        double sum = 0.0;
        double max = 0.0;
        
        for (NSDictionary *dictionary in array) {
            
            double num = [dictionary[@"pondNum"]doubleValue];
            double den = [dictionary[@"pondDen"]doubleValue];
            
            sum += [dictionary[@"mark"]doubleValue] * num / den;
            max += [dictionary[@"max"]doubleValue] * num / den;
        }
        
        sum /= max;
        sum *= 60.0;
        sum += [_mark[@"terms"][i][@"bonus"]integerValue];
        _mark[@"terms"][i][@"average"] = [NSNumber numberWithDouble:sum];
    }
    
    double sum = 0.0;
    double denominator = 0.0;
    
    for (NSInteger i = 0; i < (_isPremiere ? 2 : 3); i++) {
        
        NSNumber *average = _mark[@"terms"][i][@"average"];
        
        if (!isnan(average.doubleValue)) {
            
            sum += [self round:average.floatValue :YES];
            denominator ++;
        }
    }
    sum /= denominator;
    _mark[@"average"] = [NSNumber numberWithDouble:sum];
    
    if (_isPremiere) {
        
        double exam = [_mark[@"terms"][2][@"average"]doubleValue];
        if (!isnan(exam) && !isnan(sum)) {
            
            sum = (2.0*[self round:exam :YES] + [self round:sum :YES]) / 3.0;
            _mark[@"terms"][2][@"average"] = [NSNumber numberWithDouble:sum];
        }
    }
}

- (IBAction)longPressGesture:(UILongPressGestureRecognizer *)sender {
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        
        NSInteger bonus = [_mark[@"terms"][_termIndex][@"bonus"]integerValue];
        _mark[@"terms"][_termIndex][@"bonus"] = [NSNumber numberWithInteger:bonus == 0 ? ((arc4random()%1000)+9000) * (arc4random()%2 == 0 ? - 1 : 1) : 0];
        
        [self averages];
        [self.tableView reloadData];
        
        neededTest = [self neededMarkForDesiredTrim:desiredTrim];
        neededTrim = [self neededTermForDesiredYear];
        desiredTrim = neededTrim;
        
        [self updateTitle];
        [_delegate didEditMark:_mark];
    }
}

- (IBAction)add {
    
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"" message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@"OK", nil];
    
    alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    alertView.tag = 0;
    
    UITextField *textField1 = [alertView textFieldAtIndex:0];
    textField1.keyboardType = UIKeyboardTypeDecimalPad;
    textField1.placeholder = @"";
    textField1.textAlignment = NSTextAlignmentCenter;
    
    UITextField *textField2 = [alertView textFieldAtIndex:1];
    textField2.keyboardType = UIKeyboardTypeDecimalPad;
    textField2.placeholder = @"";
    textField2.secureTextEntry = NO;
    textField2.textAlignment = NSTextAlignmentCenter;
    
    [alertView textFieldAtIndex:0].text = @"";
    [alertView textFieldAtIndex:1].text = @"60";
    [alertView show];
}

- (void)accessoryButtonTapped:(id)sender event:(id)event {
    
    if(self.tableView.isEditing)return;
    
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint: point];
    
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    
    NSDictionary *dictionary = _mark[@"terms"][_termIndex][@"marks"][indexPath.row-1];
    
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    
    NSString *pondNum = [formatter stringFromNumber:dictionary[@"pondNum"]];
    NSString *pondDen = [formatter stringFromNumber:dictionary[@"pondDen"]];
    
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"ponderation", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@"OK", nil];
    
    alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    alertView.tag = 2;
    
    UITextField *textField1 = [alertView textFieldAtIndex:0];
    textField1.keyboardType = UIKeyboardTypeDecimalPad;
    textField1.placeholder = @"";
    textField1.textAlignment = NSTextAlignmentCenter;
    textField1.text = pondNum;
    
    UITextField *textField2 = [alertView textFieldAtIndex:1];
    textField2.keyboardType = UIKeyboardTypeDecimalPad;
    textField2.secureTextEntry = NO;
    textField2.placeholder = @"";
    textField2.textAlignment = NSTextAlignmentCenter;
    textField2.text = pondDen;
    
    [alertView show];
}

# pragma mark - Editing notification

- (void)didEditBonus:(NSNumber *)bonus fromIndexPath:(NSIndexPath *)indexPath {
    
    _mark[@"terms"][_termIndex][@"bonus"] = bonus;
    [self averages];
    
    neededTest = [self neededMarkForDesiredTrim:desiredTrim];
    neededTrim = [self neededTermForDesiredYear];
    desiredTrim = neededTrim;
    
    [self.tableView reloadData];
    [self updateTitle];
    [_delegate didEditMark:_mark];
}

- (void)updateTitle {
    
    NSNumber *average = _mark[@"terms"][_termIndex][@"average"];
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.usesGroupingSeparator = NO;
    formatter.maximumFractionDigits = 3;
    formatter.minimumFractionDigits = 1;
    
    self.navigationItem.title = [_mark[@"terms"][_termIndex][@"marks"]count] == 0 ? @" " : [formatter stringFromNumber:average];
    [self.navigationItem.titleView sizeToFit];
}

#pragma mark - Table view delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return _braco ? 2 : 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return section == 0 ? [_mark[@"terms"][_termIndex][@"marks"] count]+1 : section == 1 ? (_isPremiere && _termIndex == 2) ? 1 : 2 : 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.usesGroupingSeparator = NO;
    formatter.maximumFractionDigits = 10;
    
    UITableViewCell *cell;
    
    if (indexPath.section == 0) {
        
        if (indexPath.row == 0) {
            
            BonusCell *cell = [tableView dequeueReusableCellWithIdentifier:@"bonusCell"];
            cell.delegate = self;
            
            cell.stepper.value = [_mark[@"terms"][_termIndex][@"bonus"]integerValue];
            cell.bonusLabel.text = [NSString stringWithFormat:@"Bonus %@", cell.stepper.value == 0.0 ? @"" : [NSString stringWithFormat:@"%@%@", cell.stepper.value > 0 ? @"+" : @"", [formatter stringFromNumber:[NSNumber numberWithDouble:cell.stepper.value]]]];
            cell.bonusLabel.textColor = _color;
            cell.stepper.tintColor = _color;
            
            return cell;
            
        } else {
            
            cell = [tableView dequeueReusableCellWithIdentifier:@"markCell"];
            formatter.minimumIntegerDigits = 2;
            
            NSString *text = [formatter stringFromNumber:_mark[@"terms"][_termIndex][@"marks"][indexPath.row-1][@"mark"]];
            
            text = [text stringByAppendingString:[NSString stringWithFormat:@" / %@",[formatter stringFromNumber:_mark[@"terms"][_termIndex][@"marks"][indexPath.row-1][@"max"]]]];
            
            cell.textLabel.text = text;
            
            cell.detailTextLabel.text = @"";
            
            NSNumber *num = _mark[@"terms"][_termIndex][@"marks"][indexPath.row-1][@"pondNum"];
            NSNumber *den = _mark[@"terms"][_termIndex][@"marks"][indexPath.row-1][@"pondDen"];
            
            if (num.integerValue / den.integerValue != 1) {
                
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ / %@", num, den];
                cell.detailTextLabel.textColor = _color;
            }
            
            
            UIButton *balance = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 25)];
            [balance setImage:[UIImage imageNamed:@"balance.png"] forState:UIControlStateNormal];
            [balance addTarget:self action:@selector(accessoryButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = balance;
            cell.accessoryView.tintColor = _color;
        }
        
    } else if (indexPath.section == 1) {
        
        if (indexPath.row == 0) {
            
            cell = [tableView dequeueReusableCellWithIdentifier:@"neededCell"];
            
            cell.textLabel.text = [NSString stringWithFormat:(_termIndex == 2 && _isPremiere) ? @"%@" : NSLocalizedString(@"in year", nil),[formatter stringFromNumber:desiredYear]];
            cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(_isPremiere ? _termIndex == 2 ? @"in exam" : @"in semester" : @"in term", nil),[formatter stringFromNumber:neededTrim]];
            cell.textLabel.textColor = _color;
            
        } else {
            
            cell = [tableView dequeueReusableCellWithIdentifier:@"neededCell"];
            
            cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(_isPremiere ? @"in semester" : @"in term", nil),[formatter stringFromNumber:desiredTrim]];
            cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"in test", nil),[formatter stringFromNumber:neededTest]];
            cell.textLabel.textColor = _color;
        }
        
    } else {
        
        if (indexPath.row == 0) {
            
            cell = [tableView dequeueReusableCellWithIdentifier:@"neededCell"];
            
            formatter.roundingMode = NSNumberFormatterRoundHalfUp;
            formatter.maximumFractionDigits = 13;
            
            cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(influencing.integerValue == 1 ? @"point" : @"points", nil),[formatter stringFromNumber:influencing]];
            cell.textLabel.textColor = _color;
            cell.detailTextLabel.text = [formatter stringFromNumber:[NSNumber numberWithDouble:influence]];
            
        } else if (indexPath.row == 1) {
            
            cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
            
            formatter.roundingMode = NSNumberFormatterRoundHalfUp;
            formatter.maximumFractionDigits = 3;
            
            cell.textLabel.text = NSLocalizedString(@"coefficient", nil);
            cell.textLabel.textColor = _color;
            cell.detailTextLabel.text = [formatter stringFromNumber:[NSNumber numberWithDouble:[_mark[@"coefficient"]doubleValue]]];
            
        } else {
            
            cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
            
            cell.textLabel.text = NSLocalizedString(@"main subject", nil);
            cell.textLabel.textColor = _color;
            cell.detailTextLabel.text = [_mark[@"bf"]boolValue]?NSLocalizedString(@"yes", nil):NSLocalizedString(@"no", nil);
        }
    }

    return cell ? cell : [UITableViewCell new];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return indexPath.section == 0 && indexPath.row != 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [_mark[@"terms"][_termIndex][@"marks"] removeObjectAtIndex:indexPath.row-1];
    [self averages];
    
    neededTest = [self neededMarkForDesiredTrim:desiredTrim];
    neededTrim = [self neededTermForDesiredYear];
    desiredTrim = neededTrim;
    
    [tableView reloadData];
    [self updateTitle];
    [tableView setEditing:NO];
    [_delegate didEditMark:_mark];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0 && indexPath.row > 0) {
        
        NSNumberFormatter *formatter = [NSNumberFormatter new];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        formatter.usesGroupingSeparator = NO;
        formatter.maximumFractionDigits = 10;
        
        NSDictionary *markModifiee = _mark[@"terms"][_termIndex][@"marks"][indexPath.row-1];
        NSString *markString = [formatter stringFromNumber:markModifiee[@"mark"]];
        NSString *maxMarkString = [formatter stringFromNumber:markModifiee[@"max"]];
        
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"" message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@"OK", nil];
        
        alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        alertView.tag = 1;
        
        UITextField *textField1 = [alertView textFieldAtIndex:0];
        textField1.keyboardType = UIKeyboardTypeDecimalPad;
        textField1.placeholder = @"";
        textField1.textAlignment = NSTextAlignmentCenter;
        
        UITextField *textField2 = [alertView textFieldAtIndex:1];
        textField2.keyboardType = UIKeyboardTypeDecimalPad;
        textField2.placeholder = @"";
        textField2.secureTextEntry = NO;
        textField2.textAlignment = NSTextAlignmentCenter;
        
        [alertView textFieldAtIndex:0].text = markString;
        [alertView textFieldAtIndex:1].text = maxMarkString;
        [alertView show];
        
    } else if (indexPath.section == 1) {
        
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"required", nil) message:indexPath.row == 0 ? NSLocalizedString(@"required year info", nil) : NSLocalizedString(@"required term info", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@"OK", nil];
        
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        alertView.tag = 3+indexPath.row;
        
        UITextField *textField = [alertView textFieldAtIndex:0];
        textField.keyboardType = UIKeyboardTypeDecimalPad;
        textField.textAlignment = NSTextAlignmentCenter;
                
        [alertView show];
        
    } else if (indexPath.section == 2 && indexPath.row == 0) {
        
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"influence", nil) message:NSLocalizedString(@"influence info", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@"OK", nil];
        
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        alertView.tag = 5;
        
        NSNumberFormatter *formatter = [NSNumberFormatter new];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        formatter.usesGroupingSeparator = NO;
        
        UITextField *textField = [alertView textFieldAtIndex:0];
        textField.keyboardType = UIKeyboardTypeDecimalPad;
        textField.textAlignment = NSTextAlignmentCenter;
        
        [alertView show];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if (section == 1) return NSLocalizedString(@"required for", nil);
    else if (section == 2) return NSLocalizedString(@"influence header", nil);
    return @"";
}

# pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    
    if (buttonIndex == 1) {
        
        if (alertView.tag == 0) {
            
            UITextField *textField1 = [alertView textFieldAtIndex:0];
            UITextField *textField2 = [alertView textFieldAtIndex:1];
            
            NSNumberFormatter *formatter = [NSNumberFormatter new];
            NSNumber *number1 = [formatter numberFromString:textField1.text];
            NSNumber *number2 = [formatter numberFromString:textField2.text];

            NSNumber *number = [NSNumber numberWithInteger:1];
            
            NSMutableDictionary *newMark = [NSMutableDictionary dictionaryWithObjectsAndKeys:number1, @"mark", number2, @"max", number, @"pondNum", number, @"pondDen", nil];
            [_mark[@"terms"][_termIndex][@"marks"] addObject:newMark];
            
            [self averages];
            
            neededTest = [self neededMarkForDesiredTrim:desiredTrim];
            neededTrim = [self neededTermForDesiredYear];
            desiredTrim = neededTrim;
            
            [self.tableView reloadData];
            [self updateTitle];
            
            [_delegate didEditMark:_mark];
            
        } else if (alertView.tag == 1) {
            
            UITextField *textField1 = [alertView textFieldAtIndex:0];
            UITextField *textField2 = [alertView textFieldAtIndex:1];
            
            NSNumberFormatter *formatter = [NSNumberFormatter new];
            NSNumber *number1 = [formatter numberFromString:textField1.text];
            NSNumber *number2 = [formatter numberFromString:textField2.text];
            
            _mark[@"terms"][_termIndex][@"marks"][indexPath.row-1][@"mark"] = number1;
            _mark[@"terms"][_termIndex][@"marks"][indexPath.row-1][@"max"] = number2;
            
            [self averages];
            
            neededTest = [self neededMarkForDesiredTrim:desiredTrim];
            neededTrim = [self neededTermForDesiredYear];
            desiredTrim = neededTrim;
            
            [self.tableView reloadData];
            
            [self updateTitle];
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            
            [_delegate didEditMark:_mark];
            
        } else if (alertView.tag == 2) {
            
            UITextField *textField1 = [alertView textFieldAtIndex:0];
            UITextField *textField2 = [alertView textFieldAtIndex:1];
            
            NSNumberFormatter *formatter = [NSNumberFormatter new];
            NSNumber *number1 = [formatter numberFromString:textField1.text];
            NSNumber *number2 = [formatter numberFromString:textField2.text];
            
            _mark[@"terms"][_termIndex][@"marks"][indexPath.row-1][@"pondNum"] = number1;
            _mark[@"terms"][_termIndex][@"marks"][indexPath.row-1][@"pondDen"] = number2;
            
            [self averages];
            [self.tableView reloadData];
            
            neededTest = [self neededMarkForDesiredTrim:desiredTrim];
            neededTrim = [self neededTermForDesiredYear];
            desiredTrim = neededTrim;
            
            [self updateTitle];
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            
            [_delegate didEditMark:_mark];
            
        } else if (alertView.tag == 3) {
            
            UITextField *textField = [alertView textFieldAtIndex:0];
            
            NSNumberFormatter *formatter = [NSNumberFormatter new];
            desiredYear = [formatter numberFromString:textField.text];
            neededTrim = [self neededTermForDesiredYear];
            [self.tableView reloadData];
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            
        } else if (alertView.tag == 4) {
            
            UITextField *textField = [alertView textFieldAtIndex:0];
            
            NSNumberFormatter *formatter = [NSNumberFormatter new];
            desiredTrim = [formatter numberFromString:textField.text];
            neededTest = [self neededMarkForDesiredTrim:desiredTrim];
            [self.tableView reloadData];
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            
        } else {
            
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
    
    if (alertView.tag == 2) {
        
        UITextField *textField1 = [alertView textFieldAtIndex:0];
        UITextField *textField2 = [alertView textFieldAtIndex:1];
        
        NSNumberFormatter *formatter = [NSNumberFormatter new];
        NSNumber *number1 = [formatter numberFromString:textField1.text];
        NSNumber *number2 = [formatter numberFromString:textField2.text];
        
        return number1 && number2 && number1.doubleValue >= 0 && number2.doubleValue > 0 && number1.integerValue == number1.doubleValue && number2.integerValue == number2.doubleValue && textField1.text.length < 4 && textField2.text.length < 4;
    }
    
    else if (alertView.tag < 2) {
        
        UITextField *textField1 = [alertView textFieldAtIndex:0];
        UITextField *textField2 = [alertView textFieldAtIndex:1];
        
        NSNumberFormatter *formatter = [NSNumberFormatter new];
        NSNumber *number1 = [formatter numberFromString:textField1.text];
        NSNumber *number2 = [formatter numberFromString:textField2.text];
        
        return number1 && number2 && number2.doubleValue > 0 && textField1.text.length < 13 && textField2.text.length < 13;
    }
    
    else {
        
        UITextField *textField = [alertView textFieldAtIndex:0];
        
        NSNumberFormatter *formatter = [NSNumberFormatter new];
        NSNumber *number = [formatter numberFromString:textField.text];
        
        return number && number.doubleValue == number.integerValue && abs(number.intValue) < 100000;
    }
}

@end
