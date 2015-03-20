//
//  DVBThreadModel.m
//  dvach-browser
//
//  Created by Andy on 20/03/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBThreadModel.h"
#import "DVBNetworking.h"
#import "DVBConstants.h"
#import "DVBPostObj.h"
#import "DVBPostPreparation.h"
#import "DVBBadPostStorage.h"
#import "DVBBadPost.h"

@interface DVBThreadModel ()

@property (nonatomic, strong) NSString *boardCode;
@property (nonatomic, strong) NSString *threadNum;
@property (nonatomic, strong) NSMutableArray *privatePostsArray;
@property (nonatomic, strong) DVBNetworking *networking;
@property (nonatomic, strong) DVBPostPreparation *postPreparation;
// storage for bad posts, marked on this specific device
@property (nonatomic, strong) DVBBadPostStorage *badPostsStorage;

@end

@implementation DVBThreadModel

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Need board code and thread num" reason:@"Use -[[DVBThreadModel alloc] initWithBoardCode:andThreadNum:]" userInfo:nil];
    
    return nil;
}

- (instancetype)initWithBoardCode:(NSString *)boardCode
                     andThreadNum:(NSString *)threadNum
{
    self = [super init];
    if (self)
    {
        _boardCode = boardCode;
        _threadNum = threadNum;
        _networking = [[DVBNetworking alloc] init];
        _privatePostsArray = [NSMutableArray array];
        _postPreparation = [[DVBPostPreparation alloc] init];
        
        /**
         Handling bad posts on this device
         */
        _badPostsStorage = [[DVBBadPostStorage alloc] init];
        NSString *badPostsPath = [_badPostsStorage badPostsArchivePath];
        
        _badPostsStorage.badPostsArray = [NSKeyedUnarchiver unarchiveObjectWithFile:badPostsPath];
        if (!_badPostsStorage.badPostsArray)
        {
            _badPostsStorage.badPostsArray = [[NSMutableArray alloc] initWithObjects:nil];
        }
        
    }
    
    return self;
}

- (void)reloadThreadWithCompletion:(void (^)(NSArray *))completion
{
    if (_boardCode && _threadNum)
    {
        [_networking getPostsWithBoard:_boardCode
                             andThread:_threadNum
                         andCompletion:^(NSDictionary *postsDictionary)
        {
            NSMutableArray *postsFullMutArray = [NSMutableArray array];
            
            _thumbImagesArray = [[NSMutableArray alloc] init];
            _fullImagesArray = [[NSMutableArray alloc] init];
            
            NSMutableDictionary *resultDict = [postsDictionary mutableCopy];
            
            NSArray *threadsDict = resultDict[@"threads"];
            NSDictionary *postsArray = threadsDict[0];
            NSArray *posts2Array = postsArray[@"posts"];
            
            for (id key in posts2Array)
            {
                NSString *num = [key[@"num"] stringValue];
                
                // server gives me number but I need string
                NSString *tmpNumForPredicate = [key[@"num"] stringValue];
                
                //searching for bad posts
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.num contains[cd] %@", tmpNumForPredicate];
                NSArray *filtered = [_badPostsStorage.badPostsArray filteredArrayUsingPredicate:predicate];
                
                if ([filtered count] > 0)
                {
                    continue;
                }
                
                NSString *comment = key[@"comment"];
                NSString *subject = key[@"subject"];
                
                NSAttributedString *attributedComment = [_postPreparation commentWithMarkdownWithComments:comment];
                
                NSDictionary *files = key[@"files"][0];
                
                NSString *thumbPath = [[NSMutableString alloc] init];
                NSString *picPath = [[NSMutableString alloc] init];
                
                if (files != nil)
                {
                    
                    // check webm or not
                    NSString *fullFileName = files[@"path"];
                    
                    thumbPath = [[NSString alloc] initWithFormat:@"%@%@/%@", DVACH_BASE_URL, _boardCode, files[@"thumbnail"]];
                    
                    [_thumbImagesArray addObject:thumbPath];
                    
                    if ([fullFileName rangeOfString:@".webm" options:NSCaseInsensitiveSearch].location != NSNotFound)
                    {
                        // if contains .webm
                        
                        // make VLC webm link
                        picPath = [[NSString alloc] initWithFormat:@"vlc://%@%@/%@", DVACH_BASE_URL_WITHOUT_SCHEME, _boardCode, files[@"path"]];
                    }
                    else
                    {
                        // if not contains .webm - regular pic link
                        picPath = [[NSString alloc] initWithFormat:@"%@%@/%@", DVACH_BASE_URL, _boardCode, files[@"path"]];
                    }
                    
                    [_fullImagesArray addObject:picPath];
                    
                }
                
                DVBPostObj *postObj = [[DVBPostObj alloc] initWithNum:num
                                                              subject:subject
                                                              comment:attributedComment
                                                                 path:picPath
                                                            thumbPath:thumbPath];
                [postsFullMutArray addObject:postObj];
                postObj = nil;
            }
            
            NSArray *resultArr = [[NSArray alloc] initWithArray:postsFullMutArray];
            
            completion(resultArr);
        }];
    }
    else
    {
        NSLog(@"No Board code or Thread number");
        completion(nil);
    }
}

- (void)flagPostWithIndex:(NSUInteger)index
        andFlaggedPostNum:(NSString *)flaggedPostNum
      andOpAlreadyDeleted:(BOOL)opAlreadyDeleted
{
    [_postsArray removeObjectAtIndex:index];
    BOOL threadOrNot = NO;
    if ((index == 0)&&(!opAlreadyDeleted))
    {
        threadOrNot = YES;
        opAlreadyDeleted = YES;
    }
    DVBBadPost *tmpBadPost = [[DVBBadPost alloc] initWithNum:flaggedPostNum
                                                 threadOrNot:threadOrNot];
    [_badPostsStorage.badPostsArray addObject:tmpBadPost];
    BOOL badPostsSavingSuccess = [_badPostsStorage saveChanges];
    if (badPostsSavingSuccess)
    {
        NSLog(@"Bad Posts saved to file");
    }
    else
    {
        NSLog(@"Couldn't save bad posts to file");
    }
}

@end