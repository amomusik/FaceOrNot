//  Created by Sean Heber on 10/24/11.
#import "ViewController.h"

@implementation ViewController

- (NSString *)APIKey
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"APIToken"];
}

- (void)resetPhotoIndex
{
    photoIndex = 0;
}

- (void)loadNextPhoto
{
    // yay for quick and dirty hacks!
    
    NSString *URLString = [NSString stringWithFormat:@"https://api.singly.com/%@/Me/photos/?offset=%d&limit=%d", [self APIKey], photoIndex, 1];
    photoIndex++;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *photosJSON = [NSData dataWithContentsOfURL:[NSURL URLWithString:URLString]];
        NSArray *photosArray = [NSJSONSerialization JSONObjectWithData:photosJSON options:0 error:nil];

        if ([photosArray isKindOfClass:[NSArray class]]) {
            if ([photosArray count] == 0) {
                // no more photos... start over, I guess?
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self resetPhotoIndex];
                });
            } else {
                for (id object in photosArray) {
                    if ([object isKindOfClass:[NSDictionary class]]) {
                        NSString *photoID = [object objectForKey:@"id"];

                        if ([photoID isKindOfClass:[NSString class]]) {
                            NSString *imageURLString = [NSString stringWithFormat:@"https://api.singly.com/%@/Me/photos/image/%@", [self APIKey], photoID];
                            NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageURLString]];
                            
                            NSArray *features = [[CIDetector detectorOfType:CIDetectorTypeFace context:nil options:nil] featuresInImage:[CIImage imageWithData:imageData]];
                            
                            UIImage *image = [UIImage imageWithData:imageData];
                            BOOL hasFace = ([features count] > 0);
                            
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                if (hasFace) {
                                    imageView.image = image;
                                } else {
                                    rejectImageView.image = image;
                                }
                                [self loadNextPhoto];
                            });
                        }
                    }
                }
            }
        }
    });
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:imageView];
    
    rejectImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 120, 120)];
    rejectImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:rejectImageView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    imageView = nil;
    rejectImageView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self resetPhotoIndex];
    [self loadNextPhoto];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}










@end
