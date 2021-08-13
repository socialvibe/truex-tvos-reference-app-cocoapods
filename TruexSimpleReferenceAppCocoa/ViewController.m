//
//  ViewController.m
//  TruexSimpleReferenceApp
//
//  Copyright © 2021 true[X]. All rights reserved.
//

#import "ViewController.h"

@import AVKit;
@import TruexAdRenderer;

@interface ViewController () <TruexAdRendererDelegate>

@property AVPlayer *player;
@property AVPlayerViewController *playerController;
@property TruexAdRenderer *adRenderer;
@property NSString *currentAdSlotType;

@end

@implementation ViewController

static NSString* const StreamURLString = @"https://ctv.truex.com/assets/reference-app-stream-no-cards-1080p.mp4";

// business logic constants:
static int const AdBreakEndSeconds = 93;
static int const MidrollAdBreakDimensionValue = 2;

- (void)viewDidLoad {
    [super viewDidLoad];

    self.playerController = [AVPlayerViewController new];
    NSURL* streamUrl = [NSURL URLWithString:StreamURLString];
    self.player = [AVPlayer playerWithURL:streamUrl];
    self.playerController.player = self.player;
    [self.view addSubview:self.playerController.view];
    self.playerController.view.frame = self.view.frame;

    [self setAdBreaks:self.player];

    self.adRenderer = [self initializeAdRenderer:MIDROLL];
}

- (void)setAdBreaks:(AVPlayer *)player {
    AVPlayerItem *content = player.currentItem;
    content.interstitialTimeRanges = @[
        // time: 0:00
        [[AVInterstitialTimeRange alloc] initWithTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(90, 1))],
        // time: 9:52
        [[AVInterstitialTimeRange alloc] initWithTimeRange:CMTimeRangeMake(CMTimeMake(592, 1), CMTimeMake(90, 1))]
    ];
}

- (TruexAdRenderer*)initializeAdRenderer:(NSString *)adSlotType {
    TruexAdRenderer *renderer = [[TruexAdRenderer alloc] initWithUrl:@""
                                                        adParameters:[self getFakeAdParams]
                                                            slotType:adSlotType];
    self.currentAdSlotType = adSlotType;
    renderer.delegate = self;
    return renderer;
}

// Fake response from an ad server
- (NSDictionary*)getFakeAdParams {
    // In a real app, this vastConfigUrl would be obtained by first making a request to the tag: https://get.truex.com/93be986246043e37135f943c107dbe967a9df3f4/vast?dimension_2=1&dimension_5=truex_sold&stream_position=midroll (some macros omitted here for ease of use)
    // It's inside the <AdParameters> XML tag of the response
    // As part of the JSON blob, the value mapped ot the "vast_config_url" key
    NSString *vastConfigUrl = @"https://get.truex.com/93be986246043e37135f943c107dbe967a9df3f4/vast/config?asnw=&cpx_url=&dimension_2=2&stream_prosition=midroll&flag=%2Bamcb%2Bemcr%2Bslcb%2Bvicb%2Baeti-exvt&fw_key_values=&metr=0&network_user_id=98307EBE-BA32-45D2-ABD0-8E292FC78519&prof=g_as3_truex&ptgt=a&pvrn=&resp=vmap1&slid=fw_truex&ssnw=&stream_id=136083572&vdur=&vprn=";
    
    NSLog(@"[TRUEX DEBUG] requesting ad from Vast Config URL: %@", vastConfigUrl);
    
    return @{
          @"placement_hash" : @"93be986246043e37135f943c107dbe967a9df3f4",
          @"vast_config_url" : vastConfigUrl
    };
}

// MARK: - true[X] Ad Renderer Delegate Methods
-(void) onAdStarted:(NSString*)campaignName {
    NSLog(@"Showing ad: %@", campaignName);
}

-(void) onAdFreePod {
    CMTime seekTime = CMTimeMakeWithSeconds(AdBreakEndSeconds, 1000);
    [self.player seekToTime:seekTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    // TODO: add logic to handle skip linear ads not at start of video
}

-(void) onAdCompleted:(NSInteger)timeSpent {
    [self.player play];
}

-(void) onAdError:(NSString *)errorMessage {
    [self.player play];
}

-(void) onNoAdsAvailable {
    [self.player play];
}

-(void) onUserCancelStream {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) onFetchAdComplete {
    [self.adRenderer start:self.playerController];
}

@end
