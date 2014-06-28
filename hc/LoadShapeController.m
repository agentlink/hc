#import <MobileCoreServices/MobileCoreServices.h>
#import "LoadShapeController.h"
#import "LoadShapeCell.h"
#import "UIImageUtil.h"
#import "EditWeightsController.h"
#import "ShapeInfo.h"
#import "ShapePath.h"

static NSString *const SEGUE_WEIGHTS = @"edit_weights";

@interface LoadShapeController () <EditWeightsControllerDelegate>
@property(nonatomic, strong) NSMutableArray *shapePaths;
@property(nonatomic, strong) NSIndexPath *selectedImagePath;
@end

@implementation LoadShapeController {
}

+ (NSMutableArray *)loadShapePaths {
    NSString *docDir = [UIImageUtil applicationDocumentsDirectory];
    NSError *error = nil;
    NSFileManager *manager = [NSFileManager defaultManager];

    NSArray *docs = [manager contentsOfDirectoryAtPath:docDir error:&error];
    NSMutableArray *shapePaths = [NSMutableArray new];
    for (id doc in docs) {
        NSString *extension = [doc pathExtension];
        if ([extension isEqualToString:@"hc"]) {
            NSString *shapeDir = [docDir stringByAppendingPathComponent:doc];
            BOOL isDir = YES;
            [manager fileExistsAtPath:shapeDir isDirectory:&isDir];
            if (isDir) {
                NSArray *shapeFiles = [manager contentsOfDirectoryAtPath:shapeDir error:&error];
                NSString *imagePath = nil;
                for (NSString *name in shapeFiles) {
                    if (![name isEqualToString:[ShapePath weightsFileName]]) {
                        NSString *ne = [name pathExtension];
                        CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef) ne, NULL);
                        if (UTTypeConformsTo(fileUTI, kUTTypeImage)) {
                            imagePath = [shapeDir stringByAppendingPathComponent:name];
                        }
                    }
                }

                if (imagePath) {
                    [shapePaths addObject:[ShapePath pathWithImagePath:imagePath]];
                }
            }
        }
    }

    return shapePaths;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:YES];

    [self reloadData];
}


- (void)reloadData {
    self.shapePaths = [LoadShapeController loadShapePaths];
    [self.collectionView reloadData];
}


- (UIImage *)getImage:(NSIndexPath *)indexPath {
    ShapePath *shapePath = [self getShapePath:indexPath];
    return [shapePath loadImage];
}

- (ShapePath *)getShapePath:(NSIndexPath *)indexPath {
    return [self.shapePaths objectAtIndex:(NSUInteger) indexPath.item - 1];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 0) {
        return [self.collectionView dequeueReusableCellWithReuseIdentifier:@"import" forIndexPath:indexPath];
    }

    LoadShapeCell *result = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"shape" forIndexPath:indexPath];
    result.imageView.image = [self getImage:indexPath];
    return result;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.shapePaths.count + 1;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 0) {
        [self performSegueWithIdentifier:@"import_image" sender:nil];
        return;
    }

    [self doneWith:indexPath];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:SEGUE_WEIGHTS]) {
        EditWeightsController *ec = segue.destinationViewController;
        ec.originalImage = [self getImage:self.selectedImagePath];
        ec.weightDelegate = self;
    }
}


- (void)edited:(UIImage *)image weights:(UIImage *)weights {
    NSIndexPath *indexPath = self.selectedImagePath;
    if (weights) {
        ShapePath *shapePath = [self getShapePath:indexPath];
        NSData *data = UIImagePNGRepresentation(weights);
        [data writeToFile:shapePath.weightsPath atomically:YES];
    }

    [self doneWith:indexPath];
}

- (void)doneWith:(NSIndexPath *)path {
    ShapePath *shapePath = [self getShapePath:path];
    ShapeInfo *info = [shapePath loadShape];
    [self.selectionDelegate shapeSelected:info];
}

- (IBAction)editWeights:(UITapGestureRecognizer *)gr {
    CGPoint point = [gr locationInView:self.collectionView];
    NSIndexPath *path = [self.collectionView indexPathForItemAtPoint:point];
    if (path && path.item != 0) {
        self.selectedImagePath = path;
        [self performSegueWithIdentifier:SEGUE_WEIGHTS sender:nil];
    }
}
@end