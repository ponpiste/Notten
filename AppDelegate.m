//
//  AppDelegate.m
//  Notten
//
//  Created by Sacha Bartholmé on 4/10/16.
//  Copyright © 2016 Sacha Bartholmé. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self advertisement];
    return YES;
}


- (void)advertisement {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL technique = [userDefaults boolForKey:@"technique"];
    BOOL facebook = [userDefaults boolForKey:@"facebook"];
    
    if (!technique) {
        
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Enseignement Secondaire Technique" message:NSLocalizedString(@"technique message", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"technique"];
        
    }
    
    else if (!facebook) {
        
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Facebook" message:NSLocalizedString(@"facebook message", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        alertView.tag=1;
        alertView.delegate=self;
        [alertView show];
        
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"facebook"];
        
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if(alertView.tag==1){
        
        NSURL *url = [NSURL URLWithString:@"fb://profile/1362095067170484"];
        [[UIApplication sharedApplication]openURL:url];
    }
}

@end
