//
//  MCConstants.m
//  Sudoku++
//
//  Created by Maarut Chandegra on 05/06/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "MCConstants.h"

NSString *const kAdMobAppId = ADMOB_APP_ID;
NSString *const kAdMobAdUnitId = ADMOB_ADUNIT_ID;

@implementation MCConstants

static NSArray<NSString *> * kAdMobTestDevices;

+ (NSArray<NSString *> *) adMobTestDevices
{
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        kAdMobTestDevices =
            [[ADMOB_TEST_DEVICES componentsSeparatedByString: @" "] arrayByAddingObject:kGADSimulatorID];
    });
    return kAdMobTestDevices;
}

@end
