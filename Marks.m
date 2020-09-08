//
//  Marks.m
//  iLGL
//
//  Created by Sacha Bartholmé on 07/11/2014.
//  Copyright (c) 2014 The iLGL Team. All rights reserved.
//

#import "Marks.h"

@implementation Marks

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults.dictionaryRepresentation.allKeys containsObject:@"rgb"]) {
        
        rgb = [userDefaults objectForKey:@"rgb"];
        NSInteger red = [rgb[0]integerValue];
        NSInteger green = [rgb[1]integerValue];
        NSInteger blue = [rgb[2]integerValue];
        color = [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1];
        
    } else {
        
        color = [UIColor colorWithRed:0 green:112/255.0 blue:0 alpha:1];
        rgb = @[@0,@112,@0];
    }
    
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[color colorWithAlphaComponent:0.7] CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self.navigationController.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    
    UIBarButtonItem *rewind = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"rewind.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(rewind)];
    
    UIBarButtonItem *forward = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"forward.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(forward)];
    
    self.navigationItem.leftBarButtonItem = rewind;
    self.navigationItem.rightBarButtonItem = forward;
    
    file = [userDefaults objectForKey:@"file"];
    NSString *class = [file componentsSeparatedByString:@"_"][0];
    isPremiere = [class hasPrefix:@"1M"] || [class hasPrefix:@"1C"] || [class hasPrefix:@"13"];
    if (isPremiere)
        titles = @[@"1. semester", @"2. semester", @"exam", @"schoolyear"];
    else
        titles = @[@"1. term", @"2. term", @"3. term", @"schoolyear"];
    
    termIndex = [userDefaults integerForKey:@"term"];
    [titleButton setTitle:NSLocalizedString(titles[termIndex], nil) forState:UIControlStateNormal];
    
    if ([[[userDefaults dictionaryRepresentation]allKeys] containsObject:@"file"]) {
        
        BOOL showedInfo = [userDefaults boolForKey:@"showedInfo"];
        if (!showedInfo && termIndex != 3) {
            
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"trick", nil) message:NSLocalizedString(@"longPress", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
            [userDefaults setBool:YES forKey:@"showedInfo"];
        }
        
        [self marksForFile:file path:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.view addGestureRecognizer:longPress];
    
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (isPremiere && termIndex == 2 && !isnan([generalAverages[2]doubleValue])) {
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        BOOL didShow = [userDefaults boolForKey:@"notes finales"];
        
        if (!didShow) {
            
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Ministère de l’Éducation" message:@"\"Pour chaque branche d’examen, la note finale se compose pour un tiers de la note de l’année et pour deux tiers de la note de l’examen. Pour le candidat qui n’a pas suivi les cours pendant l’année scolaire, les notes des épreuves à l’examen constituent les notes finales. Les branches de l’année qui ne sont pas des branches d’examen ne donnent pas lieu à une note finale.\"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
            
            [userDefaults setBool:YES forKey:@"notes finales"];
            [userDefaults synchronize];
        }
    }
}

- (void)forward {
    
    termIndex = (termIndex + 1) % 4;
    [titleButton setTitle:NSLocalizedString(titles[termIndex], nil) forState:UIControlStateNormal];
    [self.tableView reloadData];
    [self.view addGestureRecognizer:longPress];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:termIndex forKey:@"term"];
}

- (void)rewind {
    
    termIndex = (termIndex - 1) % 4 < 0 ? 3 : (termIndex - 1) % 4;
    [titleButton setTitle:NSLocalizedString(titles[termIndex], nil) forState:UIControlStateNormal];
    [self.tableView reloadData];
    [self.view addGestureRecognizer:longPress];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:termIndex forKey:@"term"];
}

# pragma mark - Marks operations

- (NSInteger)round:(double)value :(BOOL)bounds {
    
    if (bounds) {
        
        if (value > 60) value = 60;
        else if (value < 1) value = 1;
    }
    
    return ceil(value);
}

- (void)marksForFile:(NSString *)fileName path:(NSString *)filePath {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    subjects = [NSArray arrayWithContentsOfFile:filePath];
    
    NSString *path = [NSString stringWithFormat:@"%@/%@", paths[0], file];
    
    generalAverages = nil;
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
        
        marks = [NSMutableArray arrayWithContentsOfFile:path];
        //for (NSInteger i = 0; i < marks.count; i ++) [self averagesForMarkAtIndex:i];
        [self generalAverages];
        
    } else {
        
        marks = subjects.mutableCopy;
        for (NSInteger i = 0; i < marks.count; i ++) [self initMarkAtIndex:i];
        //for (NSInteger i = 0; i < marks.count; i ++) [self averagesForMarkAtIndex:i];
        [self generalAverages];
        [self archive];
        marks = [NSMutableArray arrayWithContentsOfFile:path];
    }
}

- (void)archive {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [NSString stringWithFormat:@"%@/%@", paths[0], file];
    
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    
    NSArray *components = [file componentsSeparatedByString:@"_"];
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.roundingMode = NSNumberFormatterRoundCeiling;
    formatter.minimumIntegerDigits = 2;
    NSString *year = isnan([generalAverages[3]doubleValue])?@" ":[formatter stringFromNumber:generalAverages[3]];
    
    file = [@[components[0], year, components[2]] componentsJoinedByString:@"_"];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:file forKey:@"file"];
    [userDefaults synchronize];
    
    path = [NSString stringWithFormat:@"%@/%@", paths[0], file];
    [marks writeToFile:path atomically:YES];
    NSLog(@"marks archived to %@", file);
}

- (void)initMarkAtIndex:(NSInteger)index {
    
    NSMutableDictionary *newMark = [NSMutableDictionary dictionaryWithDictionary:subjects[index]];
    
    if (![newMark.allKeys containsObject:@"code"]){
        [newMark setObject:@"" forKey:@"code"];
    }
    
    if ([newMark.allKeys containsObject:@"sub subjects"]) {
        
        NSMutableArray *array = [NSMutableArray new];
        for (NSInteger i = 0; i < [newMark[@"sub subjects"]count]; i++) {
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:newMark[@"sub subjects"][i]];
            
            [dict addEntriesFromDictionary:@{@"terms": @[@{@"bonus": [NSNumber numberWithInteger:0], @"marks": @[], @"average": [NSNumber numberWithDouble:0/0.0]}, @{@"bonus": [NSNumber numberWithInteger:0], @"marks": @[], @"average": [NSNumber numberWithDouble:0/0.0]}, @{@"bonus": [NSNumber numberWithInteger:0], @"marks": @[], @"average": [NSNumber numberWithDouble:0/0.0]}], @"average": [NSNumber numberWithDouble:0/0.0]}];
            
            [array addObject:dict];
        }
        newMark[@"sub subjects"] = array;
    }
    
    [newMark addEntriesFromDictionary:@{@"terms": @[@{@"bonus": [NSNumber numberWithInteger:0], @"marks": @[], @"average": [NSNumber numberWithDouble:0/0.0]}, @{@"bonus": [NSNumber numberWithInteger:0], @"marks": @[], @"average": [NSNumber numberWithDouble:0/0.0]}, @{@"bonus": [NSNumber numberWithInteger:0], @"marks": @[], @"average": [NSNumber numberWithDouble:0/0.0]}], @"average": [NSNumber numberWithDouble:0/0.0]}];
    
    marks[index] = newMark;
}

- (void)averagesForMarkAtIndex:(NSInteger)index {
    
    NSDictionary *mark = marks[index];
    
    for (NSInteger i = 0; i < 3; i++) {
        
        if ([mark.allKeys containsObject:@"sub subjects"]) {
            
            double sum1 = 0.0;
            double max1 = 0.0;
            
            for (NSMutableDictionary *subject in mark[@"sub subjects"]) {
                
                double num = [subject[@"pondNum"]doubleValue];
                double den = [subject[@"pondDen"]doubleValue];
                
                NSArray *array = subject[@"terms"][i][@"marks"];
                double sum2 = 0.0;
                double max2 = 0.0;
                
                for (NSDictionary *dictionary in array) {
                    
                    double num = [dictionary[@"pondNum"]doubleValue];
                    double den = [dictionary[@"pondDen"]doubleValue];
                    
                    sum2 += [dictionary[@"mark"]doubleValue] * num / den;
                    max2 += [dictionary[@"max"]doubleValue] * num / den;
                }
                
                sum2 /= max2;
                sum2 *= 60.0;
                sum2 += [subject[@"terms"][i][@"bonus"]integerValue];
                
                if (!isnan(sum2)) {
                    
                    sum1 += (double)[self round:sum2 :YES] * num / den;
                    max1 += 60.0 * num / den;
                }
                
                subject[@"terms"][i][@"average"] = [NSNumber numberWithDouble:sum2];
            }
            
            
            sum1 /= max1;
            sum1 *= 60.0;
            
            
            marks[index][@"terms"][i][@"average"] = [NSNumber numberWithDouble:sum1];
            
        } else {
            
            NSArray *array = mark[@"terms"][i][@"marks"];
            double sum = 0.0;
            double max = 0.0;
            
            for (NSDictionary *mark in array) {
                
                double num = [mark[@"pondNum"]doubleValue];
                double den = [mark[@"pondDen"]doubleValue];
                
                sum += [mark[@"mark"]doubleValue] * num / den;
                max += [mark[@"max"]doubleValue] * num / den;
            }
            
            sum /= max;
            sum *= 60.0;
            sum += [mark[@"terms"][i][@"bonus"]integerValue];
            
            marks[index][@"terms"][i][@"average"] = [NSNumber numberWithDouble:sum];
        }
    }
    
    double sum = 0.0;
    double denominator = 0.0;
    
    for (NSInteger i = 0; i < (isPremiere ? 2 : 3); i++) {
        
        NSNumber *average = marks[index][@"terms"][i][@"average"];
        
        if (!isnan(average.doubleValue)) {
            
            sum += [self round:average.floatValue :YES];
            denominator ++;
        }
    }
    
    sum /= denominator;
    marks[index][@"average"] = [NSNumber numberWithDouble:sum];
    
    if (isPremiere) {
        
        double exam = [mark[@"terms"][2][@"average"]doubleValue];
        if (!isnan(exam) && !isnan(sum)) {
            
            sum = (2.0*[self round:exam :YES] + [self round:sum :YES]) / 3.0;
            mark[@"terms"][2][@"average"] = [NSNumber numberWithDouble:sum];
        }
    }
    
    if ([[marks[index]allKeys] containsObject:@"sub subjects"]) {
        
        double sum = 0.0;
        double denominator = 0.0;
        
        for (NSInteger i = 0; i < (isPremiere ? 2 : 3); i++) {
            
            NSNumber *average = marks[index][@"sub subjects"][0][@"terms"][i][@"average"];
            
            if (!isnan(average.doubleValue)) {
                
                sum += [self round:average.floatValue :YES];
                denominator ++;
            }
        }
        
        sum /= denominator;
        marks[index][@"sub subjects"][0][@"average"] = [NSNumber numberWithDouble:sum];
        
        if (isPremiere) {
            
            double exam = [mark[@"sub subjects"][0][@"terms"][2][@"average"]doubleValue];
            if (!isnan(exam) && !isnan(sum)) {
                
                sum = (2.0*[self round:exam :YES] + [self round:sum :YES]) / 3.0;
                mark[@"sub subjects"][0][@"terms"][2][@"average"] = [NSNumber numberWithDouble:sum];
            }
        }
    }
}

- (void)generalAverages {
    
    if (!generalAverages) generalAverages = [NSMutableArray new];
    else [generalAverages removeAllObjects];
    
    for (NSInteger i = 0; i < 3; i++) {
        
        double sum = 0.0;
        double coefficients = 0.0;
        
        for (NSInteger j = 0; j < marks.count; j++) {
            
            float average = [marks[j][@"terms"][i][@"average"]floatValue];
            
            if (!isnan(average)) {
                
                NSString *coefficient = marks[j][@"coefficient"];
                sum += [self round:average :YES] * coefficient.doubleValue;
                coefficients += coefficient.doubleValue;
            }
        }
        
        [generalAverages addObject:[NSNumber numberWithDouble:sum / coefficients]];
    }
    
    double sum = 0.0;
    double coefficients = 0.0;
    
    for (NSInteger j = 0; j < marks.count; j++) {
        
        float average = [marks[j][@"average"]doubleValue];
        
        if (average > 0) {
            
            NSString *coefficient = marks[j][@"coefficient"];
            sum += [self round:average :YES] * coefficient.doubleValue;
            coefficients += coefficient.doubleValue;
        }
    }
    
    [generalAverages addObject:[NSNumber numberWithDouble:sum / coefficients]];
}

# pragma mark - Notifications

- (void)didEditColor:(UIColor *)newColor rgb:(NSArray *)newRgb {
    
    color = newColor;
    rgb = newRgb;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:rgb forKey:@"rgb"];
    
    [self.tableView reloadData];
    
    NSLog(@"New color archieved");
}

- (IBAction)didSelectTitle {
    //[self forward];
}

- (void)clickedBackWithIndex:(NSInteger)newIndex {
    
    termIndex = newIndex;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:termIndex forKey:@"term"];
    
    [titleButton setTitle:NSLocalizedString(titles[termIndex], nil) forState:UIControlStateNormal];
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
}

- (void)didSelectClass:(NSString *)newFile {
    
    if (![file isEqualToString:newFile]) {
        
        file = newFile;
        
        NSString *class = [file componentsSeparatedByString:@"_"][0];
        isPremiere = [class hasPrefix:@"1M"] || [class hasPrefix:@"1C"] || [class hasPrefix:@"13"];
        if (isPremiere)
            titles = @[@"1. semester", @"2. semester", @"exam", @"schoolyear"];
        else
            titles = @[@"1. term", @"2. term", @"3. term", @"schoolyear"];
        
        [titleButton setTitle:NSLocalizedString(titles[termIndex], nil) forState:UIControlStateNormal];
        
        [[NSUserDefaults standardUserDefaults] setObject:file forKey:@"file"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self marksForFile:newFile path:nil];
        [self.tableView reloadData];
    }
}

- (void)didAddClass:(NSString *)fileName path:(NSString *)filePath {
    
    file = [NSString stringWithFormat:@"%@_ _%@.plist", [fileName componentsSeparatedByString:@" "][0], fileName];
    
    isPremiere = [fileName hasPrefix:@"1M"] || [fileName hasPrefix:@"1C"] || [fileName hasPrefix:@"13"];
    if (isPremiere)
        titles = @[@"1. semester", @"2. semester", @"exam", @"schoolyear"];
    else
        titles = @[@"1. term", @"2. term", @"3. term", @"schoolyear"];
    
    [titleButton setTitle:NSLocalizedString(titles[termIndex], nil) forState:UIControlStateNormal];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:file forKey:@"file"];
    [userDefaults synchronize];
    
    [self marksForFile:file path:filePath];
    [self.tableView reloadData];
}

- (void)didDeleteClass:(NSString *)deletedFile defaultClass:(NSString *)defaultFile {
    
    if ([file isEqualToString:deletedFile]) {
        
        file = defaultFile;
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        if (file) {
            
            NSString *class = [file componentsSeparatedByString:@"_"][0];
            isPremiere = [class hasPrefix:@"1M"] || [class hasPrefix:@"1C"] || [class hasPrefix:@"13"];
            if (isPremiere)
                titles = @[@"1. semester", @"2. semester", @"exam", @"schoolyear"];
            else
                titles = @[@"1. term", @"2. term", @"3. term", @"schoolyear"];
            
            [titleButton setTitle:NSLocalizedString(titles[termIndex], nil) forState:UIControlStateNormal];
            
            [userDefaults setObject:file forKey:@"file"];
            NSLog(@"new file: %@", file);
            [self marksForFile:file path:nil];
            
        } else {
            
            [userDefaults removeObjectForKey:@"file"];
            [marks removeAllObjects];
        }
        
        [userDefaults synchronize];
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)didRenameClass:(NSString *)oldFile withName:(NSString *)newFile {
    
    if ([file isEqualToString:oldFile]) {
        
        file = newFile;
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:file forKey:@"file"];
        [userDefaults synchronize];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)didEditMark:(NSDictionary *)newMark {
    
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    
    marks[indexPath.row] = newMark;
    [self generalAverages];
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath, [NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    
    [self archive];
}

# pragma mark - Gesture recognizer

- (IBAction)longPressGesture:(UILongPressGestureRecognizer *)sender {
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        
        CGPoint point = [sender locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        
        if (indexPath) {
            
            if (!addAlertView) {
                
                addAlertView = [[UIAlertView alloc]initWithTitle:nil message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@"OK", nil];
                
                addAlertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
                
                UITextField *textField1 = [addAlertView textFieldAtIndex:0];
                textField1.keyboardType = UIKeyboardTypeDecimalPad;
                textField1.placeholder = @"";
                textField1.textAlignment = NSTextAlignmentCenter;
                
                UITextField *textField2 = [addAlertView textFieldAtIndex:1];
                textField2.keyboardType = UIKeyboardTypeDecimalPad;
                textField2.placeholder = @"";
                textField2.secureTextEntry = NO;
                textField2.textAlignment = NSTextAlignmentCenter;
                
            }
            
            addAlertView.title = marks[indexPath.row][@"name"];
            [addAlertView textFieldAtIndex:0].text = @"";
            [addAlertView textFieldAtIndex:1].text = @"60";
            [addAlertView show];
        }
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    
    if (gestureRecognizer == longPress) {
        
        CGPoint point = [gestureRecognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
        return indexPath.section == 1 && termIndex != 3;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - Table View

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    self.navigationItem.title = NSLocalizedString(titles[termIndex], nil);
    
    if (indexPath.section == 1) {
        
        if ([[marks[indexPath.row]allKeys] containsObject:@"sub subjects"]) {
            
            [self performSegueWithIdentifier:@"subjectCombined" sender:nil];
            
        } else {
            
            NSString *identifier = termIndex == 3 ? @"subjectYear" : @"subjectTerm";
            [self performSegueWithIdentifier:identifier sender:nil];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return ![indexPath isEqual:[NSIndexPath indexPathForRow:1 inSection:0]];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NSLocalizedString(@"reset", nil);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        if (termIndex == 3) {
            
            for (NSInteger i = 0; i < marks.count; i++) [self initMarkAtIndex:i];
        
        } else {
            
            for (NSInteger i = 0; i < marks.count; i ++) {
                
                [marks[i][@"terms"][termIndex][@"marks"]removeAllObjects];
                marks[i][@"terms"][termIndex][@"bonus"] = [NSNumber numberWithInteger:0];
                marks[i][@"terms"][termIndex][@"average"] = [NSNumber numberWithDouble:0/0.0];
                
                if ([[marks[i]allKeys]containsObject:@"sub subjects"]) {
                    
                    for (NSDictionary *subject in marks[i][@"sub subjects"]) {
                        
                        [subject[@"terms"][termIndex][@"marks"]removeAllObjects];
                        subject[@"terms"][termIndex][@"bonus"] = [NSNumber numberWithInteger:0];
                        subject[@"terms"][termIndex][@"average"] = [NSNumber numberWithDouble:0/0.0];
                    }
                }
                
                [self averagesForMarkAtIndex:i];
            }
        }
        
    } else {
        
        if (termIndex == 3) {
            
            for (int i=0; i<3; i++) {
                
                [marks[indexPath.row][@"terms"][i][@"marks"]removeAllObjects];
                marks[indexPath.row][@"terms"][i][@"bonus"] = [NSNumber numberWithInteger:0];
                marks[indexPath.row][@"terms"][i][@"average"] = [NSNumber numberWithDouble:0/0.0];
                
                if ([[marks[indexPath.row]allKeys]containsObject:@"sub subjects"]) {
                    
                    for (NSDictionary *subject in marks[indexPath.row][@"sub subjects"]) {
                        
                        [subject[@"terms"][i][@"marks"]removeAllObjects];
                        subject[@"terms"][i][@"bonus"] = [NSNumber numberWithInteger:0];
                        subject[@"terms"][i][@"average"] = [NSNumber numberWithDouble:0/0.0];
                    }
                }
            }
            
        } else {
            
            [marks[indexPath.row][@"terms"][termIndex][@"marks"]removeAllObjects];
            marks[indexPath.row][@"terms"][termIndex][@"bonus"] = [NSNumber numberWithInteger:0];
            marks[indexPath.row][@"terms"][termIndex][@"average"] = [NSNumber numberWithDouble:0/0.0];
            
            if ([[marks[indexPath.row]allKeys]containsObject:@"sub subjects"]) {
                
                for (NSDictionary *subject in marks[indexPath.row][@"sub subjects"]) {
                    
                    [subject[@"terms"][termIndex][@"marks"]removeAllObjects];
                    subject[@"terms"][termIndex][@"bonus"] = [NSNumber numberWithInteger:0];
                    subject[@"terms"][termIndex][@"average"] = [NSNumber numberWithDouble:0/0.0];
                }
            }
        }
        [self averagesForMarkAtIndex:indexPath.row];
    }
    
    [self generalAverages];
    [tableView reloadData];
    [self.view addGestureRecognizer:longPress];
    
    [tableView setEditing:NO];
    [self archive];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [NSString stringWithFormat:@"%@/%@", paths[0], file];
    marks = [NSMutableArray arrayWithContentsOfFile:path];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return section == 0 ? 2 : marks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.roundingMode = NSNumberFormatterRoundCeiling;
    formatter.minimumIntegerDigits = 2;
    
    if (indexPath.section == 0) {
        
        if (indexPath.row == 0) {
            
            UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"termCell"];
            cell.detailTextLabel.text = isnan([generalAverages[termIndex]doubleValue])?@" ":[formatter stringFromNumber:generalAverages[termIndex]];
            cell.textLabel.textColor = color;
            return cell;
            
        } else {
            
            UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"classCell"];
            cell.detailTextLabel.text = file ? [[file componentsSeparatedByString:@"_"][2] stringByReplacingOccurrencesOfString:@".plist" withString:@""] : NSLocalizedString(@"no class", nil);
            cell.textLabel.textColor = color;
            return cell;
        }
        
    } else {
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"markCell"];
        
        cell.textLabel.text = marks[indexPath.row][@"name"];
        cell.textLabel.textColor = color;
        
        NSNumber *average = termIndex == 3 ? marks[indexPath.row][@"average"] : marks[indexPath.row][@"terms"][termIndex][@"average"];
        
        cell.detailTextLabel.text = isnan(average.doubleValue)?@" ":[formatter stringFromNumber:[NSNumber numberWithInteger:[self round:average.floatValue :YES]]];
        
        return cell;
    }
}

//Der Teichmolch ist ein kleiner Schwanzlurch mit einer Körperlänge von höchstens elf Zentimetern (in Südeuropa weniger). Die Oberseite ist glatthäutig und von gelbbrauner bis schwarzgrauer Färbung. Die Männchen haben darauf – insbesondere zur Paarungszeit auffällig – grobe, rundliche, dunkle Punkte. Bei beiden Geschlechtern verlaufen abwechselnd helle...wien interesséiert dat schon et liest sws keen dat do also kann ech do schreiwen wat ech well abracadabra schubidabadidu alakazam abcdefghjiklm... a merd d'ass hij nt hji ech man et frësch: abcdefghijklmnopqrstuvwxyz voila lo ass et richteg. Jop! abcdefghijklmnopqrstuvwxyz ass definitiv besser wéi abcdefghjiklmnopqrstuvwxyz bon allé ech gi pennen ciao 👋🏼

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"classes"]) {
        
        Classes *classes = segue.destinationViewController;
        classes.color = color;
        classes.rgb = rgb;
        classes.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"subjectCombined"]) {
        
        SubjectCombined *subjectCombined = segue.destinationViewController;
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        subjectCombined.mark = marks[indexPath.row];
        subjectCombined.coefSum = marks[0][@"coefficientSum"];
        subjectCombined.termIndex = termIndex;
        subjectCombined.color = color;
        subjectCombined.isPremiere = isPremiere;
        subjectCombined.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"subjectTerm"]) {
        
        SubjectTerm *subjectTerm = segue.destinationViewController;
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        subjectTerm.coefSum = marks[0][@"coefficientSum"];
        subjectTerm.mark = marks[indexPath.row];
        subjectTerm.termIndex = termIndex;
        subjectTerm.color = color;
        subjectTerm.isPremiere = isPremiere;
        subjectTerm.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"subjectYear"]) {
        
        SubjectYear *subjectYear = segue.destinationViewController;
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        subjectYear.mark = marks[indexPath.row];
        subjectYear.color = color;
        subjectYear.isPremiere = isPremiere;
        subjectYear.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"appraisal"]) {
        
        Appraisal *appraisal = segue.destinationViewController;
        
        appraisal.generalAverages = generalAverages;
        appraisal.marks = marks;
        appraisal.termIndex = termIndex;
        appraisal.file = file;
        appraisal.color = color;
        appraisal.isPremiere = isPremiere;
        appraisal.delegate = self;
    }
}

# pragma mark - Alert view

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    
    if (buttonIndex == 1) {
        
        UITextField *textField1 = [alertView textFieldAtIndex:0];
        UITextField *textField2 = [alertView textFieldAtIndex:1];
        
        NSNumberFormatter *formatter = [NSNumberFormatter new];
        
        NSNumber *number1 = [NSNumber numberWithInteger:1];
        
        NSMutableDictionary *newMark = [NSMutableDictionary dictionaryWithObjectsAndKeys:[formatter numberFromString:textField1.text], @"mark", [formatter numberFromString:textField2.text], @"max", number1, @"pondNum", number1, @"pondDen", nil];
        
        NSDictionary *mark = marks[indexPath.row];
        
        if ([mark.allKeys containsObject:@"sub subjects"])
            [mark[@"sub subjects"][0][@"terms"][termIndex][@"marks"] addObject:newMark];
        else
            [mark[@"terms"][termIndex][@"marks"] addObject:newMark];
             
        [self averagesForMarkAtIndex:indexPath.row];
        [self generalAverages];
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        
        [self archive];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    
    UITextField *textField1 = [alertView textFieldAtIndex:0];
    UITextField *textField2 = [alertView textFieldAtIndex:1];
    
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    NSNumber *mark = [formatter numberFromString:textField1.text];
    NSNumber *maxMark = [formatter numberFromString:textField2.text];
    
    return mark && maxMark && maxMark.doubleValue > 0 && textField1.text.length < 13 && textField2.text.length < 13;
}

@end
