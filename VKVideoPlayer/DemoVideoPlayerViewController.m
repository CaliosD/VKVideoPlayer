//
//  Created by Viki.
//  Copyright (c) 2014 Viki Inc. All rights reserved.
//

#import "DemoVideoPlayerViewController.h"
#import "VKVideoPlayer.h"
#import "VKVideoPlayerCaptionSRT.h"
#import <MediaPlayer/MediaPlayer.h>

@interface DemoVideoPlayerViewController ()
@property (nonatomic, strong) NSString *currentLanguageCode;
@end

@implementation DemoVideoPlayerViewController


- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.player = [[VKVideoPlayer alloc] init];
  self.player.delegate = self;
  self.player.view.frame = self.view.bounds;
  self.player.view.playerControlsAutoHideTime = @10;
  [self.view addSubview:self.player.view];
  
  [self addDemoControl];
}

- (void)viewDidAppear:(BOOL)animated {
  [self playSampleClip1];
}

- (BOOL)prefersStatusBarHidden {
  return NO;
}

- (BOOL)shouldAutorotate {
  return YES;
}

- (void)playSampleClip1 {
  [self playStream:[NSURL URLWithString:@"http://localhost:12345/SimpleLove.mp4"]];
//    [self playStream:[NSURL URLWithString:@"http://192.168.1.157:5080/Chungking.mp4"]];
  
  [self setLanguageCode:@"ZH"];
//  [self.player setCaptionToTop:[self testCaption:@"testCaptionTop"]];
}
- (void)playSampleClip2 {
//  [self playStream:[NSURL URLWithString:@"http://devimages.apple.com/samplecode/adDemo/ad.m3u8"]];
//    [self playStream:[NSURL URLWithString:@"rtmp://192.168.1.169/live"]];
//  [self setLanguageCode:@"JP"];
//  [self.player setCaptionToTop:[self testCaption:@"testCaptionTop"]];
}

- (void)playStream:(NSURL*)url {
  VKVideoPlayerTrack *track = [[VKVideoPlayerTrack alloc] initWithStreamURL:url];
  track.hasNext = YES;
  [self.player loadVideoWithTrack:track];
}

- (VKVideoPlayerCaption*)testCaption:(NSString*)captionName {
  NSString *filePath = [[NSBundle mainBundle] pathForResource:captionName ofType:@"srt"];
  NSData *testData = [NSData dataWithContentsOfFile:filePath];
  NSString *rawString = [[NSString alloc] initWithData:testData encoding:NSUTF8StringEncoding];
  
  VKVideoPlayerCaption *caption = [[VKVideoPlayerCaptionSRT alloc] initWithRawString:rawString];
  return caption;
}

- (void)addDemoControl {
  
  UIButton *playSample1Button = [UIButton buttonWithType:UIButtonTypeCustom];
  playSample1Button.frame = CGRectMake(10,40,80,40);
  [playSample1Button setTitle:@"sample1" forState:UIControlStateNormal];
  [playSample1Button addTarget:self action:@selector(playSampleClip1) forControlEvents:UIControlEventTouchUpInside];
  [self.player.view addSubviewForControl:playSample1Button];

  UIButton *playSample2Button = [UIButton buttonWithType:UIButtonTypeCustom];
  playSample2Button.frame = CGRectMake(100,40,80,40);
  [playSample2Button setTitle:@"sample2" forState:UIControlStateNormal];
  [playSample2Button addTarget:self action:@selector(playSampleClip2) forControlEvents:UIControlEventTouchUpInside];
  [self.player.view addSubviewForControl:playSample2Button];
}


#pragma mark - VKVideoPlayerControllerDelegate
- (void)videoPlayer:(VKVideoPlayer*)videoPlayer didControlByEvent:(VKVideoPlayerControlEvent)event {
  NSLog(@"%s event:%d", __FUNCTION__, event);
  __weak __typeof(self) weakSelf = self;

  if (event == VKVideoPlayerControlEventTapDone) {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
  
  if (event == VKVideoPlayerControlEventTapCaption) {
    RUN_ON_UI_THREAD(^{
      VKPickerButton *button = self.player.view.captionButton;
      NSArray *subtitleList = @[@"JP", @"EN"];
      
      if (button.isPresented) {
        [button dismiss];
      } else {
        weakSelf.player.view.controlHideCountdown = -1;
        [button presentFromViewController:weakSelf title:@"请选择字幕" items:subtitleList formatCellBlock:^(UITableViewCell *cell, id item) {
          
          NSString* code = (NSString*)item;
          cell.textLabel.text = code;
          cell.detailTextLabel.text = [NSString stringWithFormat:@"%@%%", @"50"];
        } isSelectedBlock:^BOOL(id item) {
          return [item isEqualToString:weakSelf.currentLanguageCode];
        } didSelectItemBlock:^(id item) {
          [weakSelf setLanguageCode:item];
          [button dismiss];
        } didDismissBlock:^{
          weakSelf.player.view.controlHideCountdown = [weakSelf.player.view.playerControlsAutoHideTime integerValue];
        }];
      }
    });
  }
    
    if (event == VKVideoPlayerControlEventTapPlayerView) {
        self.player.view.bigPlayButton.hidden = NO;
        [self.player.view.bigPlayButton setImage:[UIImage imageNamed:@"VKVideoPlayer_pause_big"] forState:UIControlStateNormal];
    }

}

- (void)setLanguageCode:(NSString*)code {
  self.currentLanguageCode = code;
  VKVideoPlayerCaption *caption = nil;
  if ([code isEqualToString:@"JP"]) {
    caption = [self testCaption:@"Japanese"];
  } else if ([code isEqualToString:@"EN"]) {
    caption = [self testCaption:@"English"];
  }
  if (caption) {
    [self.player setCaptionToBottom:caption];
    [self.player.view.captionButton setTitle:[code uppercaseString] forState:UIControlStateNormal];
  }
}

@end
