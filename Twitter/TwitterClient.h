//
//  TwitterClient.h
//  Twitter
//
//  Created by Gabriel Gayán on 11/5/15.
//  Copyright © 2015 Gabriel Gayan. All rights reserved.
//

#import <BDBOAuth1Manager/BDBOAuth1RequestOperationManager.h>
#import "User.h"
#import "Tweet.h"

@interface TwitterClient : BDBOAuth1RequestOperationManager

+ (TwitterClient *)sharedInstance;

- (void)loginWithCompletion:(void (^)(User *user, NSError *error))completion;
- (void)openURL:(NSURL *)url;
- (void)homeTimeLineWithParams:(NSDictionary *)params completion:(void (^)(NSArray *tweets, NSError *error))completion;
- (void)mentionsTimeLineWithParams:(NSDictionary *)params completion:(void (^)(NSArray *tweets, NSError *error))completion;
- (void)userTimeLineWithUserId:(NSString *)userId completion:(void (^)(NSArray *tweets, NSError *error))completion;
- (void)getTweetWithTweetId:(NSString *)tweetId completion:(void (^)(Tweet *tweet, NSError *error))completion;
- (void)createTweetWithText:(NSString *)text completion:(void (^)(Tweet *tweet, NSError *error))completion;
- (void)createTweetWithText:(NSString *)text replyingTweetId:(NSString *)replyingTweetId completion:(void (^)(Tweet *tweet, NSError *error))completion;
- (void)removeTweetId:(NSString *)tweetId completion:(void (^)(NSError *error))completion;
- (void)retweetTweetId:(NSString *)tweetId completion:(void (^)(NSError *error))completion;
- (void)removeRetweetFromTweetId:(NSString *)tweetId completion:(void (^)(NSError *error))completion;
- (void)favoriteTweetId:(NSString *)tweetId completion:(void (^)(NSError *error))completion;
- (void)removeFavoriteTweetId:(NSString *)tweetId completion:(void (^)(NSError *error))completion;

@end