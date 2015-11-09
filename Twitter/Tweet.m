//
//  Tweet.m
//  Twitter
//
//  Created by Gabriel Gayán on 11/5/15.
//  Copyright © 2015 Gabriel Gayan. All rights reserved.
//

#import "Tweet.h"
#import "NSDate+DateTools.h"

@implementation Tweet

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        self.user = [[User alloc] initWithDictionary:dictionary[@"user"]];
        self.tweetId = dictionary[@"id_str"];
        if (dictionary[@"retweeted_status"]) {
            self.retweet = [[Tweet alloc] initWithDictionary:dictionary[@"retweeted_status"]];
        };
        self.text = dictionary[@"text"];
        self.retweets = [dictionary[@"retweet_count"] stringValue];
        self.favorites = [dictionary[@"favorite_count"] stringValue];
        self.createdAt = [NSDate dateWithString:dictionary[@"created_at"] formatString:@"EEE MMM d HH:mm:ss Z y"];

        self.retweeted = [dictionary[@"retweeted"] boolValue];
        self.favorited = [dictionary[@"favorited"] boolValue];
    }
    return self;
}


+ (NSArray *)tweetsWithArray:(NSArray *)array {
    NSMutableArray *tweets = [NSMutableArray array];
    
    for (NSDictionary *tweet in array) {
        [tweets addObject:[[Tweet alloc] initWithDictionary:tweet]];
    }
    
    return tweets;
}

@end
