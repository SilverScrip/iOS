#import <UIKit/UIKit.h>

// Enum for modes passed to configure function
typedef NS_ENUM(NSInteger, OxyMode) {
  MODE_AUDIBLE = 0,
  MODE_NONAUDIBLE = 1,
  MODE_COMPRESSION = 2,
  MODE_ALL = 3,
  MODE_CUSTOM = 4,
    
    TOKEN_START = 0,
    TOKEN_END_OK = 1,
    TOKEN_END_BAD = 2,
    END_PLAY = 3
};

// Project version number for Core.
FOUNDATION_EXPORT double OxyCoreVersionNumber;

// Project version string for Core.
FOUNDATION_EXPORT const unsigned char OxyCoreVersionString[];

@interface OxyCore : NSObject
{
  @public
    void *mOxyCore;
    float mSampleRate;
    int mBufferSize;
    
    int mEncoding;
    int mDecoding;
    
    float *mAudioBuffer; //nchannels = 1
    
    int mDecodedOK;
    
    NSString *mDecodedString;

    SEL mOxyCallback;
}
- (id)init:(SEL)selector;

- (void)configure:(id)object withMode:(OxyMode)mode;

- (int)setCustomBaseFreq:(float)baseFreq withOxysSeparation:(int)oxysSeparation;

-(float)getDecodingBeginFreq; // For Begin Frequency

-(float)getDecodingEndFreq; // For End Frequency

- (int)setCustomAudio:(CFURLRef)urlAudioFile;

- (void)startOxyListen;

- (void)stopOxyListen;

- (void)playOxy:(NSString *) code withType:(int)type;

- (NSString *)getDecodedString;

- (NSString *)getDecodedKey;

- (int)getDecodedTimeStamp;

- (NSString *)getVersionCoreLib;

- (NSString *)getVersionCoreFramework;

- (float)getConfidence;

- (float)getConfidenceError;

- (float)getConfidenceNoise;

- (float)getReceivedOxysVolume;

- (int)getDecodedMode;

@end
