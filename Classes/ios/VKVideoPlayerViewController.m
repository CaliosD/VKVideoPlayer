//
//  Created by Viki.
//  Copyright (c) 2014 Viki Inc. All rights reserved.
//

#import "VKVideoPlayerViewController.h"
#import "VKVideoPlayerConfig.h"
#import "VKFoundation.h"
#import "VKVideoPlayerCaptionSRT.h"
#import "VKVideoPlayerAirPlay.h"
#import "VKVideoPlayerSettingsManager.h"


@interface VKVideoPlayerViewController ()

@property (assign) BOOL applicationIdleTimerDisabled;
@property (nonatomic, strong) NSString *currentLanguageCode;

@end

@implementation VKVideoPlayerViewController

- (id)init {
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self) {
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self initialize];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self initialize];
    }
    return self;
}

- (void)initialize {
    [VKSharedAirplay setup];
}
- (void)dealloc {
    [VKSharedAirplay deactivate];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.player = [[VKVideoPlayer alloc] init];
    self.player.delegate = self;
    CGRect bounds = [[UIScreen mainScreen] bounds];
    self.player.view.frame = CGRectMake(0, 0, MIN(bounds.size.width, bounds.size.height), MIN(bounds.size.width, bounds.size.height));
    self.player.forceRotate = YES;
    [self.view addSubview:self.player.view];
    
    if (VKSharedAirplay.isConnected) {
        [VKSharedAirplay activate:self.player];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.applicationIdleTimerDisabled = [UIApplication sharedApplication].isIdleTimerDisabled;
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [UIApplication sharedApplication].idleTimerDisabled = self.applicationIdleTimerDisabled;
    [super viewWillDisappear:animated];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)playVideoWithStreamURL:(NSURL*)streamURL {
    [self.player loadVideoWithTrack:[[VKVideoPlayerTrack alloc] initWithStreamURL:streamURL]];
}

- (void)setSubtitle:(VKVideoPlayerCaption*)subtitle {
    [self.player setCaptionToBottom:subtitle];
}

#pragma mark - App States

- (void)applicationWillResignActive {
    self.player.view.controlHideCountdown = -1;
    if (self.player.state == VKVideoPlayerStateContentPlaying) [self.player pauseContent:NO completionHandler:nil];
}

- (void)applicationDidBecomeActive {
    self.player.view.controlHideCountdown = kPlayerControlsDisableAutoHide;
}

#pragma mark - VKVideoPlayerControllerDelegate
- (void)videoPlayer:(VKVideoPlayer*)videoPlayer didControlByEvent:(VKVideoPlayerControlEvent)event {
    
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

- (VKVideoPlayerCaption*)testCaption:(NSString*)captionName {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:captionName ofType:@"srt"];
    NSData *testData = [NSData dataWithContentsOfFile:filePath];
    NSString *rawString = [[NSString alloc] initWithData:testData encoding:NSUTF8StringEncoding];
    
    VKVideoPlayerCaption *caption = [[VKVideoPlayerCaptionSRT alloc] initWithRawString:rawString];
    return caption;
}

#pragma mark - Orientation
- (BOOL)shouldAutorotate {
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (self.player.isFullScreen) {
        return UIInterfaceOrientationIsLandscape(interfaceOrientation);
    } else {
        return NO;
    }
}

@end
