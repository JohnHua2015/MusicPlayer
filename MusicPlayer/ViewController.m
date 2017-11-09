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

@interface ViewController ()<AVAudioPlayerDelegate>

@property (strong, nonatomic) AVAudioPlayer *player;
@property (strong, nonatomic) NSTimer *timer;

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
    
    // 后台播放音乐时，控制音乐操作。也可以在 AppDelegate 的 didFinishLaunchingWithOptions，applicationWillResignActive 中处理
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

        
        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        [_player prepareToPlay];
        [_player setVolume:1];// The volume for the sound. The nominal range is from 0.0 to 1.0.
        _player.numberOfLoops = -1; //设置音乐播放次数  -1为一直循环
        [_player setEnableRate:YES];
        _player.currentTime = 5;
        _player.delegate = self;
        
        //        NSMutableArray *marr = [ViewController MusicInfoArrayWithFilePath: pathString];
        //        NSDictionary *dic = [self musicInfoFromUrl:url];
        
    }
    [self configNowPlayingCenter:@{@"title":@"千里明月光", @"artist":@"安琥"}];
    
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

#pragma mark - 处理中断事件
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

#pragma mark - 锁屏下的音乐控制
- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    switch (event.subtype)
    {
//            case UIEventSubtypeRemoteControlNextTrack: // 下一首
//            case UIEventSubtypeRemoteControlPreviousTrack: // 上一首
        case UIEventSubtypeRemoteControlPlay:// 播放
            NSLog(@"%s-%d",__FUNCTION__,__LINE__);
            [self.player play];
            break;
        case UIEventSubtypeRemoteControlPause:// 暂停
            NSLog(@"%s-%d",__FUNCTION__,__LINE__);
            [self.player pause];
            break;
        case UIEventSubtypeRemoteControlStop:// 停止
            NSLog(@"%s-%d",__FUNCTION__,__LINE__);
            break;
        default:
            break;
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
//    NSMutableDictionary * info = [NSMutableDictionary dictionary];
//    //音乐的标题
//    [info setObject:[dictionary objectForKey:@"title"] forKey:MPMediaItemPropertyTitle];
//    //音乐的艺术家
//    [info setObject:[dictionary objectForKey:@"artist"] forKey:MPMediaItemPropertyArtist];
//    //音乐已经播放的时间
//    [info setObject:@(_player.duration) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];//
//    NSLog(@"play back time: %lf", _player.duration);
//    //音乐的播放速度. 1.0 表示时间的1秒对应播放时间的1秒
//    [info setObject:@(1) forKey:MPNowPlayingInfoPropertyPlaybackRate];
    //音乐的总时间
//    [info setObject:@(self.totalTime) forKey:MPMediaItemPropertyPlaybackDuration];
    //音乐的封面
//    MPMediaItemArtwork * artwork = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:@"0.jpg"]];
//    [info setObject:artwork forKey:MPMediaItemPropertyArtwork];
    
    NSDictionary *info = @{
             MPMediaItemPropertyTitle : dictionary[@"title"],// 歌曲名
             MPMediaItemPropertyArtist : dictionary[@"artist"],// 艺术家名
             MPMediaItemPropertyAlbumTitle : dictionary[@"artist"],// 专辑名字
             MPMediaItemPropertyPlaybackDuration : @(_player.duration),//歌曲总时长
             MPNowPlayingInfoPropertyElapsedPlaybackTime : @(_player.currentTime),//当前播放的item所消逝的时间(歌曲当前时间). 由系统根据之前提供elapsed time和playback rate自动计算的. 
             MPNowPlayingInfoPropertyPlaybackRate: @(1)// 音乐的播放速度，0表示正常的播放速率.  
//             MPMediaItemPropertyArtwork : dictionary[@"artist"],//歌曲的插图, 类型是MPMeidaItemArtwork对象
             };
    //完成设置
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:info];
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
