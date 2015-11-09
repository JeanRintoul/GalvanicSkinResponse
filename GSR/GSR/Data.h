//
//  Data.h
//  BioimpedanceSpectrometer
//
//  Created by Jean Rintoul on 8/2/14.
//  Copyright (c) 2014 ibisbiofeedback. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Data : NSManagedObject

@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * magnitude;
@property (nonatomic, retain) NSData * biodata;
@property (nonatomic, retain) NSNumber * phase;

@end
