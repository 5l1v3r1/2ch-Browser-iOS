//
//  DVBCommonTableViewController.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 13/06/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBConstants.h"
#import "DVBAlertViewGenerator.h"

#import "DVBCommonTableViewController.h"

@interface DVBCommonTableViewController ()

@property (nonatomic, assign) BOOL eulaAgreed;

@end

@implementation DVBCommonTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _eulaAgreed = [[NSUserDefaults standardUserDefaults] boolForKey:USER_AGREEMENT_ACCEPTED];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(defaultsChanged)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSUserDefaultsDidChangeNotification
                                                  object:nil];
}

- (void)defaultsChanged
{
    UIViewController *vc = [[self.navigationController viewControllers] firstObject];

    BOOL isEulaAcceptedNow = [[NSUserDefaults standardUserDefaults] boolForKey:USER_AGREEMENT_ACCEPTED];

    BOOL isUserAgreementUserDefaultTheSame = _eulaAgreed == isEulaAcceptedNow;

    _eulaAgreed = isEulaAcceptedNow;

    // Check if current VC is last one in stack - so we will not present the same message over and over
    // And there is no need to present message when user just accepted EULA
    if ([vc isEqual:self] && isUserAgreementUserDefaultTheSame) {
        DVBAlertViewGenerator *alertGenerator = [[DVBAlertViewGenerator alloc] init];
        NSString *restartAppAlertTitle = NSLocalizedString(@"Настройки изменены", @"Настройки изменены");
        NSString *restartAppAlertDescription = NSLocalizedString(@"Для правильной работы закройте приложение и запустите его заново.", @"Для правильной работы закройте приложение и запустите его заново.");
        UIAlertView *alertView = [alertGenerator alertViewWithTitle:restartAppAlertTitle description:restartAppAlertDescription buttons:@[@"OK"]];
        [alertView show];
    }
}

#pragma mark - Messages about state

- (void)showMessageAboutDataLoading
{
    NSString *loadingTitle = NSLocalizedString(@"Загрузка", @"Загрузка");
    [self showUserMessageWithTitle:loadingTitle];
}

- (void)showMessageAboutError
{
    NSString *errorTitle = NSLocalizedString(@"Ошибка загрузки", @"Ошибка загрузки");
    [self showUserMessageWithTitle:errorTitle];
}

- (void)showUserMessageWithTitle:(NSString *)title
{
    // Display a message when the table is empty
    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];

    messageLabel.text = title;
    messageLabel.textColor = [UIColor grayColor];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
        messageLabel.textColor = [UIColor whiteColor];
    }
    messageLabel.numberOfLines = 0;
    messageLabel.textAlignment = NSTextAlignmentCenter;
    [messageLabel sizeToFit];

    self.tableView.backgroundView = messageLabel;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

@end
