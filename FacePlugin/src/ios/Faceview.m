#import "FaceView.h"
#import "facesdk.h"

CGSize m_frameSize;
NSMutableArray* m_faceResults;

@implementation FaceView

- (id)initWithFrame:(CGRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) 
    {

    }
    return self;
}
- (void)dealloc 
{
//    [super dealloc];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if(m_frameSize.width == 0 || m_frameSize.height == 0) return;
    if(rect.size.width == 0 || rect.size.height == 0) return;

    float x_scale = m_frameSize.width / rect.size.width;
    float y_scale = m_frameSize.height / rect.size.height;
    
    int face_cout = [m_faceResults count];
    for(int i = 0; i < face_cout; i ++) {
        FaceBox* face = (FaceBox*)[m_faceResults objectAtIndex:i];
        
        CGRect rectangle = CGRectMake(face.x1 / x_scale, face.y1 / y_scale, (face.x2 - face.x1) / x_scale, (face.y2 - face.y1) / y_scale);
        NSLog(@"rectangle: %f, %f, %f, %f", rectangle.origin.x, rectangle.origin.y, rectangle.size.width, rectangle.size.height);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
        CGContextSetLineWidth(context, 3);
        
        if(face.liveness > 0.8) {
            CGContextSetRGBStrokeColor(context, 0.0, 1.0, 0.0, 1.0);
        } else {
            CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
        }
        
        CGContextStrokeRect(context, rectangle);    //this will draw the border
        
        // String to display (REAL or SPOOF based on liveness)
        NSString *displayText;
        if(face.liveness > 0.8) {
            displayText = [NSString stringWithFormat:@"REAL"];
        } else {
            displayText = [NSString stringWithFormat:@"SPOOF"];
        }

        // Set the font and color attributes for the text
        NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:20],
                                     NSForegroundColorAttributeName: (face.liveness > 0.8 ? [UIColor greenColor] : [UIColor redColor])};

        // Draw the text at the top-left of the rectangle
        CGPoint textPoint = CGPointMake(rectangle.origin.x + 5, rectangle.origin.y - 25);
        [displayText drawAtPoint:textPoint withAttributes:attributes];

        // Continue with the stroke
        CGContextStrokePath(context);
    }
}

- (void) setFrameSize:(CGSize) size {
    m_frameSize = size;
}

- (void) setFaceResults:(NSMutableArray*) face_results {
    m_faceResults = face_results;
    [self setNeedsDisplay];
}


@end
