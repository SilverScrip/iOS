#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "OxyCore.h"

@class Oxy;

@protocol oxyDelegate <NSObject>

@required
- (void) oxyIdWith:(NSString *)oxy_id  ;
@end

@interface Oxy : NSObject <NSURLConnectionDelegate> {

    OxyCore *_oxyCore;

}
    +(Oxy *) instance;

    // Public methods
    -(void) listen;
    -(void) stop;
    -(void) play:(NSString *) code withType:(int)type;
    -(void) configure:(id)object withMode:(OxyMode)mode;

    -(float) ConfidenceNoise;
    -(float) ConfidenceError;
    -(float) DistanceVol;

    - (int) TimeStamp;
    - (int) setCustomBaseFreq:(float)baseFreq withSeparation:(int)Separation;
    - (int) setCustomAudio:(CFURLRef)urlAudioFile;

    // Delegate object
    @property (nonatomic, weak) id<oxyDelegate>delegate;

@end
