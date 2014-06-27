#import "LoadShapeController.h"
#import "LoadShapeCell.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface LoadShapeController ()
@property(nonatomic, strong) NSMutableArray *images;
@end

@implementation LoadShapeController {

}

+ (NSString *)applicationDocumentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;

#ifdef TARGET_IPHONE_SIMULATOR
    NSArray *comps = [basePath pathComponents];
    return [NSString stringWithFormat:@"%@%@/%@/%@", comps[0], comps[1], comps[2], @"Documents/hc_images/"];
#endif
    return basePath;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:YES];

    [self reloadData];
}

- (void)reloadData {
    NSString *docDir = [LoadShapeController applicationDocumentsDirectory];
    NSError *error = nil;
    NSArray *docs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docDir error:&error];
    NSMutableArray *images = [NSMutableArray new];
    for (id doc in docs) {
        NSString *extension = [doc pathExtension];
        CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef) extension, NULL);

        if (UTTypeConformsTo(fileUTI, kUTTypeImage)) {
            [images addObject:[docDir stringByAppendingPathComponent:doc]];
        }
    }
    
    self.images = images;
}


- (UIImage *)getImage:(NSIndexPath *)indexPath {
    NSString *imagePath = [self.images objectAtIndex:(NSUInteger) indexPath.item];
    return [[UIImage alloc] initWithContentsOfFile:imagePath];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LoadShapeCell *result = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"shape" forIndexPath:indexPath];
    result.imageView.image = [self getImage:indexPath];
    return result;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.images.count;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UIImage *image = [self getImage:indexPath];
    [self.selectionDelegate imageSelected:image];
    [self.navigationController popViewControllerAnimated:YES];
}


@end