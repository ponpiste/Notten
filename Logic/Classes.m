//
//  Classes.m
//  iLGL
//
//  Created by Sacha Bartholmé on 26/08/15.
//  Copyright (c) 2015 The iLGL Team. All rights reserved.
//

#import "Classes.h"

@implementation Classes

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.topItem.title = @" ";
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    path = [NSString stringWithFormat:@"%@/", paths[0]];
    files = [NSMutableArray arrayWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil]];
    [files removeObject:@".DS_Store"];
    [self setTitle];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //if (files.count == 0) [self performSegueWithIdentifier:@"segue" sender:nil];
}

- (void)didEditColor:(NSInteger)newRed :(NSInteger)newGreen :(NSInteger)newBlue {
    
    _rgb = @[@(newRed),@(newGreen),@(newBlue)];
    
    _color = [UIColor colorWithRed:newRed/255.0 green:newGreen/255.0 blue:newBlue/255.0 alpha:1.0];
    
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[_color colorWithAlphaComponent:0.7] CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self.navigationController.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    
    [self.tableView reloadData];
}

- (IBAction)didEndSliding {
    
    [_delegate didEditColor:_color rgb:_rgb];
}

- (void)accessoryButtonTapped:(id)sender event:(id)event {
    
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint: currentTouchPosition];
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSString *name = cell.textLabel.text;
    accessoryIndex = indexPath.row;
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView textFieldAtIndex:0].text = name;
    [alertView textFieldAtIndex:0].textAlignment = NSTextAlignmentCenter;
    [alertView show];
}

- (void)setTitle {
    
    double sum = 0.0;
    for (NSString *file in files) {
        
        NSString *filePath = [path stringByAppendingString:file];
        NSDictionary *details = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        NSNumber *bytes = details[NSFileSize];
        sum += bytes.doubleValue;
    }
    
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.maximumFractionDigits = 2;
    NSString *string = [NSString stringWithFormat:@"%@ KB", [formatter stringFromNumber:[NSNumber numberWithDouble:sum / 1000.0]]];
    self.navigationItem.title = string;
}

- (void)didEditEnseignement:(NSString *)fileName path:(NSString *)filePath {
    
    if (!names) {
        
        names = [NSMutableArray new];
        for (NSString *file in files) [names addObject:[file componentsSeparatedByString:@"_"][2]];
    }
    
    NSInteger count = 1;
    NSString *newName = [fileName stringByAppendingString:@".plist"];
    
    while ([names containsObject:newName]) {
        
        count ++;
        newName = [NSString stringWithFormat:@"%@ (%d).plist",fileName,count];
        
    }
    if(count>1){
        fileName = [NSString stringWithFormat:@"%@ (%d)", fileName, count];
    }

    
    [_delegate didAddClass:fileName path:filePath];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return section == 1 ? files.count : showSliders ? 2 : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        
        if (indexPath.row == 0) {
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rgb"];
                        
            cell.textLabel.text = @"RGB";
            cell.textLabel.textColor = _color;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d, %d, %d",[_rgb[0]integerValue],[_rgb[1]integerValue],[_rgb[2]integerValue]];
            
            return cell;
            
        } else {
            
            ColorCell *cell = [tableView dequeueReusableCellWithIdentifier:@"colorCell"];
            cell.delegate = self;
            
            [cell setRed:[_rgb[0]integerValue]];
            [cell setGreen:[_rgb[1]integerValue]];
            [cell setBlue:[_rgb[2]integerValue]];
            
            return cell;
        }
        
    } else {
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
        
        NSArray *components = [files[indexPath.row] componentsSeparatedByString:@"_"];
        cell.textLabel.text = [components[2] stringByReplacingOccurrencesOfString:@".plist" withString:@""];
        cell.textLabel.textColor = _color;
        cell.detailTextLabel.text = components[1];
        
        UIButton *pencil = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 25)];
        [pencil setImage:[UIImage imageNamed:@"compose.png"] forState:UIControlStateNormal];
        [pencil addTarget:self action:@selector(accessoryButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = pencil;
        cell.accessoryView.tintColor = _color;
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        
        showSliders = !showSliders;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        
    } else {
        
        [_delegate didSelectClass:files[indexPath.row]];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return indexPath.section == 0 && indexPath.row == 1 ? 123 : 44;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return indexPath.section == 1;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *filePath = [path stringByAppendingString:files[indexPath.row]];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    NSString *deletedFile = files[indexPath.row];
    [files removeObjectAtIndex:indexPath.row];
    [_delegate didDeleteClass:deletedFile defaultClass:files.count > 0 ? files[0] : nil];
    [self setTitle];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    NSLog(@"%@ deleted", deletedFile);
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    Enseignement *enseignement = segue.destinationViewController;
    enseignement.delegate=self;
}

#pragma mark - Alert view

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 1) {
        
        NSString *old = [path stringByAppendingString:files[accessoryIndex]];
        
        
        UITextField *textField = [alertView textFieldAtIndex:0];
        NSArray *components = [files[accessoryIndex] componentsSeparatedByString:@"_"];
        NSString *newFile = [NSString stringWithFormat:@"%@_%@_%@.plist", components[0], components[1], textField.text];
        NSString *new = [path stringByAppendingString:newFile];
        
        NSError *error;
        [[NSFileManager defaultManager] moveItemAtPath:old toPath:new error:&error];
        
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        } else {
            
            [_delegate didRenameClass:files[accessoryIndex] withName:newFile];
            NSLog(@"%@ renamed into %@", files[accessoryIndex], newFile);
            files[accessoryIndex] = newFile;
            names = nil;
            [self.tableView reloadData];
        }
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    
    if (!names) {
        
        names = [NSMutableArray new];
        for (NSString *file in files) [names addObject:[file componentsSeparatedByString:@"_"][2]];
    }
    
    UITextField *textField = [alertView textFieldAtIndex:0];
    NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"_/"];
    NSString *name = [NSString stringWithFormat:@"%@.plist", textField.text];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:accessoryIndex inSection:1];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSString *current = cell.textLabel.text;
    
    return (textField.text.length > 0 && textField.text.length < 30 && ![names containsObject:name] && [textField.text rangeOfCharacterFromSet:set].location == NSNotFound) || [textField.text isEqualToString:current];
}

@end
