//
//  ViewController.m
//  MusicPlayer
//
//  Created by jackey on 2017/11/5.
//  Copyright © 2017年 jackey. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController ()

@property (strong, nonatomic) AVAudioPlayer *player;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self registerAudioSessionNotification];
}

- (void)dealloc {
    [self removeAudioSessionNotification];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 后台播放音乐时，控制音乐操作
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)handlePlay:(UIButton *)sender {
    [self playMusic];
}
- (IBAction)handleStop:(UIButton *)sender {
    [self stopMusic];
}

- (AVAudioPlayer *)player {
    if (_player == nil) {
        NSString *pathString= [[NSBundle mainBundle] pathForResource:@"安琥 - 千里明月光.mp3" ofType:nil];
        if (pathString == nil) {
            NSLog(@"can't find music file");
            return nil;
        }
        
        NSURL *url = [NSURL fileURLWithPath:pathString];
        NSMutableArray *marr = [ViewController MusicInfoArrayWithFilePath: pathString];
//        NSDictionary *dic = [self musicInfoFromUrl:url];
        [self configNowPlayingCenter:nil];
        
        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        [_player prepareToPlay];
        [_player setVolume:1];// The volume for the sound. The nominal range is from 0.0 to 1.0.
        _player.numberOfLoops = -1; //设置音乐播放次数  -1为一直循环
    }
    
    return _player;
}

- (void)playMusic {
    if (!self.player.playing ) {
        [self.player play]; //播放
    }
    
}

- (void)stopMusic {
    if (self.player.playing) {
        [self.player stop];
    }
    
}

/* 处理中断事件，如：电话、拍照
 * 如果不处理，在收到电话等中断事件后，等这些事件结束后，音频不会自动重新播放
 */
- (void)registerAudioSessionNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(handleInterreption:) 
                                                 name:AVAudioSessionInterruptionNotification 
                                               object:[AVAudioSession sharedInstance]];
}
- (void)removeAudioSessionNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:AVAudioSessionInterruptionNotification 
                                                  object:[AVAudioSession sharedInstance]];
}
-(void)handleInterreption:(NSNotification *)sender
{
    
    AVAudioSession *session = (AVAudioSession *)sender.userInfo;
    NSLog(@"===%s, userInfo:%@, %@", __func__, session, sender);
    if(self.player.playing) {
        [self.player stop];
    } 
    else {
        [self.player play]; //播放
    }
}


/* 传递信息到锁屏状态下 此方法在播放歌曲与切换歌曲时调用即可
 */
- (NSDictionary *)musicInfoFromUrl:(NSURL *)musicUrl {
    NSMutableDictionary *mdic = [NSMutableDictionary dictionary];
    
    AVAsset *asset = [AVURLAsset URLAssetWithURL:musicUrl options:nil];
    for (NSString *format in [asset availableMetadataFormats]) {
        for (AVMetadataItem *metadataitem in [asset metadataForFormat:format]) {  
            NSLog(@"music info: %@", metadataitem.value);
            
            if ([metadataitem.commonKey isEqualToString:@"artwork"]) {  
                NSData *data = [(NSDictionary *)metadataitem.value objectForKey:@"data"];  
                NSString *mime = [(NSDictionary *)metadataitem.value objectForKey:@"MIME"];  

                [mdic setObject:[UIImage imageWithData:data] forKey:@"kImage"];
                
                break;  
            }  
            else if([metadataitem.commonKey isEqualToString:@"title"])  
            {  
                NSString *title = (NSString *)metadataitem.value;  
                [mdic setObject:title forKey:@"kTitle"];
            }  
            else if([metadataitem.commonKey isEqualToString:@"artist"])  
            {  
                NSString *artist = (NSString *)metadataitem.value;  
                [mdic setObject:artist forKey:@"kArtist"];
            }  
            else if([metadataitem.commonKey isEqualToString:@"albumName"])  
            {  
                NSString *albumName = (NSString *)metadataitem.value;  
                [mdic setObject:albumName forKey:@"kAlbumName"];
            }  
        }  
    }
    return mdic;
}
- (void)configNowPlayingCenter:(NSDictionary *)dictionary {
    NSLog(@"锁屏设置: %@", dictionary);
    
    // BASE_INFO_FUN(@"配置NowPlayingCenter");
    NSMutableDictionary * info = [NSMutableDictionary dictionary];
    //音乐的标题
    [info setObject:@"title" forKey:MPMediaItemPropertyTitle];
    //音乐的艺术家
    [info setObject:@"artist" forKey:MPMediaItemPropertyArtist];
    //音乐的播放时间
    [info setObject:[NSDate date] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    //音乐的播放速度
    [info setObject:@(1) forKey:MPNowPlayingInfoPropertyPlaybackRate];
    //音乐的总时间
//    [info setObject:@(self.totalTime) forKey:MPMediaItemPropertyPlaybackDuration];
    //音乐的封面
//    MPMediaItemArtwork * artwork = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:@"0.jpg"]];
//    [info setObject:artwork forKey:MPMediaItemPropertyArtwork];
    //完成设置
    [[MPNowPlayingInfoCenter defaultCenter]setNowPlayingInfo:info];
}

+ (NSMutableArray *)MusicInfoArrayWithFilePath:(NSString *)filePath
{
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    
    {
        
        NSURL *url = [NSURL fileURLWithPath:filePath];
        
        NSString *MusicName = [filePath lastPathComponent];
        
        AVURLAsset *mp3Asset = [AVURLAsset URLAssetWithURL:url options:nil];
        
        NSLog(@"%@",mp3Asset);
        
        for (NSString *format in [mp3Asset availableMetadataFormats]) {
            
            NSMutableDictionary *infoDict = [[NSMutableDictionary alloc] init];
            
            [infoDict setObject:MusicName forKey:@"MusicName"];
            
            NSLog(@"format type = %@",format);
            
            for (AVMetadataItem *metadataItem in [mp3Asset metadataForFormat:format]) {
                
                metadataItem.commonKey ? NSLog(@"commonKey = %@",metadataItem.commonKey) : nil;
                
                
                
                if ([metadataItem.commonKey isEqualToString:@"artwork"]) {
                    
                    NSString *mime = [(NSDictionary *)metadataItem.value objectForKey:@"MIME"];
                    
                    NSLog(@"mime: %@",mime);
                    
                    
                    
                    [infoDict setObject:mime forKey:@"artwork"];
                    
                }
                
                else if([metadataItem.commonKey isEqualToString:@"title"])
                    
                {
                    
                    NSString *title = (NSString *)metadataItem.value;
                    
                    NSLog(@"title: %@",title);
                    
                    
                    
                    [infoDict setObject:title forKey:@"title"];
                    
                }
                
                else if([metadataItem.commonKey isEqualToString:@"artist"])
                    
                {
                    
                    NSString *artist = (NSString *)metadataItem.value;
                    
                    NSLog(@"artist: %@",artist);
                    
                    
                    
                    [infoDict setObject:artist forKey:@"artist"];
                    
                }
                
                else if([metadataItem.commonKey isEqualToString:@"albumName"])
                    
                {
                    
                    NSString *albumName = (NSString *)metadataItem.value;
                    
                    NSLog(@"albumName: %@",albumName);
                    
                    
                    
                    [infoDict setObject:albumName forKey:@"albumName"];
                    
                }
                
            }
        
            [resultArray addObject:infoDict];
            
        }
        
    }
    
    return resultArray;   
}


@end
