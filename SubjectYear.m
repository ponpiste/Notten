//
//  SubjectYear.m
//  iLGL
//
//  Created by Sacha Bartholmé on 20/11/2014.
//  Copyright (c) 2014 The iLGL Team. All rights reserved.
//

#import "SubjectYear.h"

@implementation SubjectYear

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.topItem.title = _mark[@"code"];
    [self updateTitle];
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

- (void)accessoryButtonTapped:(id)sender event:(id)event {
    
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint: point];
    
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    
    NSDictionary *dictionary = _mark[@"terms"][indexPath.section][@"marks"][indexPath.row-2];
    
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
    
    _mark[@"terms"][indexPath.section][@"bonus"] = bonus;
    [self averages];
    
    [self.tableView reloadData];
    [self updateTitle];
    [_delegate didEditMark:_mark];
}

- (void)updateTitle {
    
    NSNumber *average = _mark[@"average"];
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.usesGroupingSeparator = NO;
    formatter.maximumFractionDigits = 3;
    formatter.minimumFractionDigits = 1;
    
    self.navigationItem.title = isnan(average.doubleValue)?@" ":[formatter stringFromNumber:average];
    [self.navigationItem.titleView sizeToFit];
}

#pragma mark - Table view delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return (_isPremiere ? 2 : 3);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [_mark[@"terms"][section][@"marks"] count] + 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.usesGroupingSeparator = NO;
    formatter.maximumFractionDigits = 10;
    
    UITableViewCell *cell;
    
    if (indexPath.row == 0) {
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
        
        cell.textLabel.text = [NSString stringWithFormat:@"%d. %@", indexPath.section + 1, NSLocalizedString(_isPremiere ? @"semester" : @"term", nil)];
        cell.textLabel.textColor = _color;
        
        NSNumber *average = _mark[@"terms"][indexPath.section][@"average"];
        NSNumber *rounded = [NSNumber numberWithInteger:[self round:average.floatValue :YES]];
        
        formatter.minimumIntegerDigits = 2;
        cell.detailTextLabel.text = isnan(average.doubleValue)?@" ":[formatter stringFromNumber:rounded];
        
    } else if (indexPath.row == 1) {
        
        BonusCell *cell = [tableView dequeueReusableCellWithIdentifier:@"bonusCell"];
        cell.delegate = self;
        
        cell.stepper.value = [_mark[@"terms"][indexPath.section][@"bonus"] integerValue];
        cell.bonusLabel.text = [NSString stringWithFormat:@"Bonus %@", cell.stepper.value == 0.0 ? @"" : [NSString stringWithFormat:@"%@%@", cell.stepper.value > 0 ? @"+" : @"", [formatter stringFromNumber:[NSNumber numberWithDouble:cell.stepper.value]]]];
        cell.bonusLabel.textColor = _color;
        cell.stepper.tintColor = _color;
        
        return cell;
        
    } else {
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"markCell"];
        formatter.minimumIntegerDigits = 2;
        
        NSString *text = [formatter stringFromNumber:_mark[@"terms"][indexPath.section][@"marks"][indexPath.row - 2][@"mark"]];
        
        text = [text stringByAppendingString:[NSString stringWithFormat:@" / %@",[formatter stringFromNumber:_mark[@"terms"][indexPath.section][@"marks"][indexPath.row - 2][@"max"]]]];
        
        cell.textLabel.text = text;
        cell.detailTextLabel.text = @" ";
        
        NSNumber *num = _mark[@"terms"][indexPath.section][@"marks"][indexPath.row - 2][@"pondNum"];
        NSNumber *den = _mark[@"terms"][indexPath.section][@"marks"][indexPath.row - 2][@"pondDen"];
        
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

    return cell ? cell : [UITableViewCell new];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return indexPath.row != 0 && indexPath.row != 1;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [_mark[@"terms"][indexPath.section][@"marks"] removeObjectAtIndex:indexPath.row-2];
    [self averages];
    
    [tableView reloadData];
    [self updateTitle];
    [tableView setEditing:NO];
    [_delegate didEditMark:_mark];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row != 0 && indexPath.row != 1) {
        
        NSNumberFormatter *formatter = [NSNumberFormatter new];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        formatter.usesGroupingSeparator = NO;
        formatter.maximumFractionDigits = 10;
        
        NSDictionary *markModifiee = _mark[@"terms"][indexPath.section][@"marks"][indexPath.row-2];
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
    }
}

# pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    
    if (buttonIndex == 1) {
        
        if (alertView.tag == 1) {
            
            UITextField *textField1 = [alertView textFieldAtIndex:0];
            UITextField *textField2 = [alertView textFieldAtIndex:1];
            
            NSNumberFormatter *formatter = [NSNumberFormatter new];
            NSNumber *number1 = [formatter numberFromString:textField1.text];
            NSNumber *number2 = [formatter numberFromString:textField2.text];
            
            _mark[@"terms"][indexPath.section][@"marks"][indexPath.row-2][@"mark"] = number1;
            _mark[@"terms"][indexPath.section][@"marks"][indexPath.row-2][@"max"] = number2;
            
            [self averages];
            
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
            
            _mark[@"terms"][indexPath.section][@"marks"][indexPath.row-2][@"pondNum"] = number1;
            _mark[@"terms"][indexPath.section][@"marks"][indexPath.row-2][@"pondDen"] = number2;
            
            [self averages];
            [self.tableView reloadData];
            
            [self updateTitle];
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            
            [_delegate didEditMark:_mark];
            
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
    
    else {
        
        UITextField *textField1 = [alertView textFieldAtIndex:0];
        UITextField *textField2 = [alertView textFieldAtIndex:1];
        
        NSNumberFormatter *formatter = [NSNumberFormatter new];
        NSNumber *number1 = [formatter numberFromString:textField1.text];
        NSNumber *number2 = [formatter numberFromString:textField2.text];
        
        return number1 && number2 && number2.doubleValue > 0 && textField1.text.length < 13 && textField2.text.length < 13;
    }
}

@end
