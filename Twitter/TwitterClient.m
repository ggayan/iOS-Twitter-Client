//
//  TwitterClient.m
//  Twitter
//
//  Created by Gabriel Gayán on 11/5/15.
//  Copyright © 2015 Gabriel Gayan. All rights reserved.
//

#import "TwitterClient.h"
#import "Tweet.h"
#import "User.h"

NSString * const kTwitterConsumerKey = @"Xi4Ha2FVzixcEId3OJlJlJCpB";
NSString * const kTwitterConsumerSecret = @"jmBHiNpiCp8zhgk6pKGwVPkMnMVUseDb9ixLdZNOSUEzGMY8wo";
// These api keys are no longer valid so don't try anything funny :)
NSString * const kTwitterBaseUrl = @"https://api.twitter.com";

@interface TwitterClient()

@property (nonatomic, strong) void (^loginCompletion)(User *user, NSError *error);

@end

@implementation TwitterClient

+ (TwitterClient *)sharedInstance {
    static TwitterClient *instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (instance == nil) {
            instance = [[TwitterClient alloc] initWithBaseURL:[NSURL URLWithString:kTwitterBaseUrl]
                                                  consumerKey:kTwitterConsumerKey
                                               consumerSecret:kTwitterConsumerSecret];
        }
    });

    return instance;
}

# pragma mark - Login methods

- (void)loginWithCompletion:(void (^)(User *user, NSError *error))completion {
    self.loginCompletion= completion;
    [self.requestSerializer removeAccessToken];
    [self fetchRequestTokenWithPath:@"/oauth/request_token"
                             method:@"POST"
                        callbackURL:[NSURL URLWithString:@"ggayantwitter://request"]
                              scope:nil
                            success:^(BDBOAuth1Credential *requestToken) {
                                NSString *authURL = [NSString stringWithFormat:@"https://api.twitter.com/oauth/authorize?oauth_token=%@", requestToken.token];
                                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:authURL]];
                            }
                            failure:^(NSError *error) {
                                NSLog(@"Error: %@", error.localizedDescription);
                                self.loginCompletion(nil, error);
                            }];
}

- (void)openURL:(NSURL *)url {
    [self fetchAccessTokenWithPath:@"oauth/access_token"
                            method:@"POST"
                      requestToken:[BDBOAuth1Credential
                                    credentialWithQueryString:url.query]
                           success:^(BDBOAuth1Credential *accessToken) {
                               NSLog(@"got the access token!");
                               [self.requestSerializer saveAccessToken:accessToken];

                               [self GET:@"1.1/account/verify_credentials.json" parameters:nil
                                 success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
                                     User *user = [[User alloc] initWithDictionary:responseObject];
                                     [User setCurrentuser:user];
                                     NSLog(@"current user: %@", user.name);
                                     self.loginCompletion(user, nil);
                                 } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
                                     NSLog(@"failed getting current user");
                                     self.loginCompletion(nil, error);
                                 }];
                           } failure:^(NSError *error) {
                               NSLog(@"Failed to get the request token!");
                               self.loginCompletion(nil, error);
                           }];

}

# pragma mark - Timeline

- (void)homeTimeLineWithParams:(NSDictionary *)params completion:(void (^)(NSArray *tweets, NSError *error))completion {
    [self GET:@"1.1/statuses/home_timeline.json" parameters:params success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        NSArray *tweets = [Tweet tweetsWithArray:responseObject];
        completion(tweets, nil);
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        completion(nil, error);
    }];
}

- (void)mentionsTimeLineWithParams:(NSDictionary *)params completion:(void (^)(NSArray *tweets, NSError *error))completion {
    [self GET:@"1.1/statuses/mentions_timeline.json" parameters:params success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        NSArray *tweets = [Tweet tweetsWithArray:responseObject];
        completion(tweets, nil);
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        completion(nil, error);
    }];
}

# pragma mark - User Timeline

- (void)userTimeLineWithUserId:(NSString *)userId completion:(void (^)(NSArray *tweets, NSError *error))completion {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (userId) {
        params[@"user_id"] = userId;
    }

    [self GET:@"1.1/statuses/user_timeline.json" parameters:params success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        NSArray *tweets = [Tweet tweetsWithArray:responseObject];
        completion(tweets, nil);
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        completion(nil, error);
    }];
}

# pragma mark - Tweet methods

- (void)getTweetWithTweetId:(NSString *)tweetId completion:(void (^)(Tweet *tweet, NSError *error))completion {
    NSDictionary *params = @{@"include_my_retweet": @1};
    NSString *endpoint = [NSString stringWithFormat:@"1.1/statuses/show/%@.json", tweetId];

    [self GET:endpoint parameters:params success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        Tweet *tweet = [[Tweet alloc] initWithDictionary:responseObject];
        NSLog(@"Tweet %@ successfully fetched", tweet.tweetId);
        completion(tweet, nil);
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        completion(nil, error);
    }];
}

# pragma mark - Create tweet methods

- (void)createTweetWithText:(NSString *)text completion:(void (^)(Tweet *tweet, NSError *error))completion {
    [self createTweetWithText:text replyingTweetId:nil completion:completion];
}

- (void)createTweetWithText:(NSString *)text replyingTweetId:(NSString *)replyingTweetId completion:(void (^)(Tweet *tweet, NSError *error))completion {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:@{@"status": text}];

    if (replyingTweetId) {
        params[@"in_reply_to_status_id"] = replyingTweetId;
    }

    [self POST:@"1.1/statuses/update.json" parameters:params success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        NSLog(@"Tweet successfully created");
        completion([[Tweet alloc] initWithDictionary:responseObject], nil);
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        completion(nil, error);
    }];
}

- (void)removeTweetId:(NSString *)tweetId completion:(void (^)(NSError *error))completion {
    NSString *endpoint = [NSString stringWithFormat:@"1.1/statuses/destroy/%@.json", tweetId];

    [self POST:endpoint parameters:nil success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        NSLog(@"Tweet %@ successfully removed", tweetId);
        completion(nil);
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        completion(error);
    }];
}


# pragma mark - Retweet methods

- (void)retweetTweetId:(NSString *)tweetId completion:(void (^)(NSError *error))completion {
    NSString *endpoint = [NSString stringWithFormat:@"1.1/statuses/retweet/%@.json", tweetId];

    [self POST:endpoint parameters:nil success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        NSLog(@"Tweet %@ successfully retweeted", tweetId);
        completion(nil);
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        completion(error);
    }];
}

- (void)removeRetweetFromTweetId:(NSString *)tweetId completion:(void (^)(NSError *error))completion {
    [self getTweetWithTweetId:tweetId completion:^(Tweet *refreshedTweet, NSError *error) {
        if (error) {
            completion(error);
            return;
        }

        [self getTweetWithTweetId:refreshedTweet.originalTweetId completion:^(Tweet *originalTweet, NSError *error) {
            if (error) {
                completion(error);
                return;
            }

            if (!originalTweet.retweeted || originalTweet.retweetId == nil) {
                return;
            }
            
            [self removeTweetId:originalTweet.retweetId completion:completion];
        }];
    }];
}

# pragma mark - Favorite tweet methods

- (void)favoriteTweetId:(NSString *)tweetId completion:(void (^)(NSError *error))completion {
    NSDictionary *params = @{@"id": tweetId};
    [self POST:@"1.1/favorites/create.json" parameters:params success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        NSLog(@"Tweet %@ successfully favorited", tweetId);
        completion(nil);
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        completion(error);
    }];
}

- (void)removeFavoriteTweetId:(NSString *)tweetId completion:(void (^)(NSError *error))completion {
    NSDictionary *params = @{@"id": tweetId};
    [self POST:@"1.1/favorites/destroy.json" parameters:params success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        NSLog(@"Favorite for tweet %@ successfully removed", tweetId);
        completion(nil);
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        completion(error);
    }];
}

@end
