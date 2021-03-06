//
//  CCControlCenterActivity.m
//  Nextcloud
//
//  Created by Marino Faggiana on 01/03/17.
//  Copyright © 2017 TWS. All rights reserved.
//

#import "CCControlCenterActivity.h"

#import "AppDelegate.h"
#import "CCSection.h"

#define fontSizeData    [UIFont boldSystemFontOfSize:15]
#define fontSizeAction  [UIFont systemFontOfSize:14]
#define fontSizeNote    [UIFont systemFontOfSize:14]

#define daysOfActivity  7

@interface CCControlCenterActivity ()
{
    BOOL _verbose;

    // Datasource
    NSArray *_sectionDataSource;
}
@end

@implementation CCControlCenterActivity

#pragma --------------------------------------------------------------------------------------------
#pragma mark ===== Init =====
#pragma --------------------------------------------------------------------------------------------

-  (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])  {
        
        app.controlCenterActivity = self;
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    _sectionDataSource = [NSArray new];
    
    [self reloadDatasource];
}

// Apparirà
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _verbose = [CCUtility getActivityVerboseHigh];
    
    app.controlCenter.labelMessageNoRecord.hidden = YES;
}

// E' arrivato
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self reloadDatasource];
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark - ==== Datasource ====
#pragma --------------------------------------------------------------------------------------------

- (void)reloadDatasource
{
    // test
    if (app.activeAccount.length == 0)
        return;
    
    if (app.controlCenter.isOpen) {
        
        NSPredicate *predicate;
        
        NSDate *sixDaysAgo = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:-daysOfActivity toDate:[NSDate date] options:0];
        
        if ([CCUtility getActivityVerboseHigh])
            predicate = [NSPredicate predicateWithFormat:@"((account == %@) || (account == '')) AND (date > %@)", app.activeAccount, sixDaysAgo];
        else
            predicate = [NSPredicate predicateWithFormat:@"(account == %@) AND (verbose == %lu) AND (date > %@)", app.activeAccount, k_activityVerboseDefault, sixDaysAgo];

        _sectionDataSource = [CCCoreData getAllTableActivityWithPredicate: predicate];
        
        [self reloadCollection];
    }
}

- (void)reloadCollection
{
    NSDate *dateActivity;
    
    if ([_sectionDataSource count] == 0) {
            
        app.controlCenter.labelMessageNoRecord.text = NSLocalizedString(@"_no_activity_",nil);
        app.controlCenter.labelMessageNoRecord.hidden = NO;
            
    } else {
            
        app.controlCenter.labelMessageNoRecord.hidden = YES;
        dateActivity = ((TableActivity *)[_sectionDataSource objectAtIndex:0]).date;
    }

    if ([dateActivity compare:_storeDateFirstActivity] == NSOrderedDescending || _storeDateFirstActivity == nil || dateActivity == nil) {
        _storeDateFirstActivity = dateActivity;
        [self.collectionView reloadData];
    }
}
    
#pragma --------------------------------------------------------------------------------------------
#pragma mark - ==== Table ====
#pragma --------------------------------------------------------------------------------------------

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [_sectionDataSource count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    TableActivity *activity = [_sectionDataSource objectAtIndex:section];
        
    if ([activity.action isEqual: k_activityDebugActionDownload] || [activity.action isEqual: k_activityDebugActionUpload]) {
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/%@.ico", app.directoryUser, activity.fileID]])
            return 1;
        else
            return 0;
    }
    
    return 0;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    TableActivity *activity = [_sectionDataSource objectAtIndex:section];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, collectionView.frame.size.width - 40, CGFLOAT_MAX)];
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    [label sizeToFit];
    
    // Action
    [label setFont:fontSizeAction];
    label.text = [NSString stringWithFormat:@"%@ %@", activity.action, activity.file];
    int heightAction = [[self class] getLabelHeight:label width:self.collectionView.frame.size.width];
    
    // Note
    [label setFont:fontSizeNote];
    
    if (_verbose && activity.idActivity == 0)
        label.text = [NSString stringWithFormat:@"%@ Selector: %@", activity.note, activity.selector];
    else
        label.text = activity.note;
    
    int heightNote = [[self class] getLabelHeight:label width:self.collectionView.frame.size.width];
    
    int heightView = 40 + heightAction + heightNote;
    
    return CGSizeMake(collectionView.frame.size.width, heightView);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview;
    
    if (kind == UICollectionElementKindSectionHeader) {
    
        reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"header" forIndexPath:indexPath];
        
        TableActivity *activity = [_sectionDataSource objectAtIndex:indexPath.section];
    
        UILabel *dateLabel = (UILabel *)[reusableview viewWithTag:100];
        UILabel *actionLabel = (UILabel *)[reusableview viewWithTag:101];
        UILabel *noteLabel = (UILabel *)[reusableview viewWithTag:102];
        UIImageView *typeImage = (UIImageView *) [reusableview viewWithTag:103];
    
        [dateLabel setFont:fontSizeData];
        dateLabel.textColor = [UIColor colorWithRed:100.0/255.0 green:100.0/255.0 blue:100.0/255.0 alpha:1.0];
    
        if ([CCUtility getActivityVerboseHigh]) {
        
            dateLabel.text = [NSDateFormatter localizedStringFromDate:activity.date dateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterMediumStyle];
        
        } else {
        
            NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:activity.date];
            dateLabel.text = [CCUtility getTitleSectionDate:[[NSCalendar currentCalendar] dateFromComponents:comps]];
        }
    
        [actionLabel setFont:fontSizeAction];
        [actionLabel sizeToFit];
        actionLabel.text = [NSString stringWithFormat:@"%@ %@", activity.action, activity.file];

        if ([activity.type isEqualToString:k_activityTypeInfo]) {
        
            actionLabel.textColor = COLOR_BRAND;
        
            if (activity.idActivity == 0)
                typeImage.image = [UIImage imageNamed:@"activityTypeInfo"];
            else
                typeImage.image = [UIImage imageNamed:@"activityTypeInfoServer"];
        }
    
        if ([activity.type isEqualToString:k_activityTypeSuccess]) {
        
            actionLabel.textColor = [UIColor colorWithRed:87.0/255.0 green:187.0/255.0 blue:57.0/255.0 alpha:1.0];;
            typeImage.image = [UIImage imageNamed:@"activityTypeSuccess"];
        }
    
        if ([activity.type isEqualToString:k_activityTypeFailure]) {
        
            actionLabel.textColor = [UIColor redColor];
            typeImage.image = [UIImage imageNamed:@"activityTypeFailure"];
        }
    
        [noteLabel setFont:fontSizeNote];
        [noteLabel sizeToFit];
        noteLabel.textColor = COLOR_TEXT_ANTHRACITE;
        noteLabel.numberOfLines = 0;
        noteLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
        if ([CCUtility getActivityVerboseHigh] && activity.idActivity == 0) noteLabel.text = [NSString stringWithFormat:@"%@ Selector: %@", activity.note, activity.selector];
        else noteLabel.text = activity.note;
    }
    
    if (kind == UICollectionElementKindSectionFooter) {
        
         reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"footer" forIndexPath:indexPath];
    }
    
    return reusableview;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:104];

    TableActivity *activity = [_sectionDataSource objectAtIndex:indexPath.section];
    
    imageView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.ico", app.directoryUser, activity.fileID]];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    TableActivity *activity = [_sectionDataSource objectAtIndex:indexPath.section];
    
    CCMetadata *metadata = [CCCoreData getMetadataWithPreficate:[NSPredicate predicateWithFormat:@"(account == %@) AND (fileID == %@)", activity.account, activity.fileID] context:nil];
    
    if (metadata) {
        
        if (!self.splitViewController.isCollapsed && app.activeMain.detailViewController.isViewLoaded && app.activeMain.detailViewController.view.window)
            [app.activeMain.navigationController popToRootViewControllerAnimated:NO];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            
            [app.activeMain performSegueWithIdentifier:@"segueDetail" sender:metadata];
            
            [app.controlCenter closeControlCenter];
        });
        
    } else {
        
        [app messageNotification:@"_info_" description:@"_activity_file_not_present_" visible:YES delay:k_dismissAfterSecond type:TWMessageBarMessageTypeInfo];
    }
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark - ==== Utility ====
#pragma --------------------------------------------------------------------------------------------

+ (CGFloat)getLabelHeight:(UILabel*)label width:(int)width
{
    CGSize constraint = CGSizeMake(width, CGFLOAT_MAX);
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    NSDictionary *attributes = @{NSFontAttributeName : label.font, NSParagraphStyleAttributeName: paragraph};
    
    NSStringDrawingContext *context = [NSStringDrawingContext new];
    CGSize boundingBox = [label.text boundingRectWithSize:constraint options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:context].size;
    
    CGSize size = CGSizeMake(ceil(boundingBox.width), ceil(boundingBox.height));
    
    return size.height;
}

@end
