#import "LoadShapeController.h"
#import "LoadShapeCell.h"
#import "UIImageUtil.h"
#import "EditWeightsController.h"
#import "ShapeInfo.h"

static NSString *const SEGUE_WEIGHTS = @"edit_weights";

@interface LoadShapeController () <EditWeightsControllerDelegate>
@property(nonatomic, strong) NSMutableArray *imagePaths;
@property(nonatomic, strong) NSIndexPath *selectedImagePath;
@end

@implementation LoadShapeController {
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:YES];

    [self reloadData];
}


- (void)reloadData {
    self.imagePaths = [UIImageUtil loadImagePaths];
}


- (UIImage *)getImage:(NSIndexPath *)indexPath {
    NSString *imagePath = [self.imagePaths objectAtIndex:(NSUInteger) indexPath.item - 1];
    return [[UIImage alloc] initWithContentsOfFile:imagePath];
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
    return self.imagePaths.count + 1;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 0) {
        [self performSegueWithIdentifier:@"import_image" sender:nil];
        return;
    }

    [self doneWith:[self getImage:indexPath] weights:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:SEGUE_WEIGHTS]) {
        EditWeightsController *ec = segue.destinationViewController;
        ec.originalImage = [self getImage:self.selectedImagePath];
        ec.weightDelegate = self;
    }
}


- (void)edited:(UIImage *)image weights:(UIImage *)weights {
    [self doneWith:image weights:weights];
}

- (void)doneWith:(UIImage *)image weights:(UIImage *)weights {
    ShapeInfo *info = [ShapeInfo infoWithImage:image weights:weights];
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