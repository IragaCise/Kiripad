#import "KiriPadViewController.h"
#import "EngineBridge.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface KiriPadViewController () <UIDocumentPickerDelegate>
@property(nonatomic, strong) UITextView *logView;
@property(nonatomic, strong) UIButton *selectButton;
@property(nonatomic, strong) UIButton *runButton;
@property(nonatomic, strong, nullable) NSURL *selectedFolderURL;
@end

@implementation KiriPadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"KiriPad Phase 1";
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    UILabel *subtitle = [[UILabel alloc] init];
    subtitle.text = @"吉里吉里作品のiPad互換性診断";
    subtitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    subtitle.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *help = [[UILabel alloc] init];
    help.text = @"自分で所有しているゲームのフォルダを選択してください。Phase 1はファイル構成を読むだけで、展開・復号・改変は行いません。";
    help.numberOfLines = 0;
    help.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    help.translatesAutoresizingMaskIntoConstraints = NO;

    self.selectButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.selectButton setTitle:@"ゲームフォルダを選択" forState:UIControlStateNormal];
    self.selectButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    [self.selectButton addTarget:self action:@selector(selectFolder) forControlEvents:UIControlEventTouchUpInside];
    self.selectButton.translatesAutoresizingMaskIntoConstraints = NO;

    self.runButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.runButton setTitle:@"ランタイム起動（Phase 2）" forState:UIControlStateNormal];
    self.runButton.enabled = NO;
    [self.runButton addTarget:self action:@selector(runPressed) forControlEvents:UIControlEventTouchUpInside];
    self.runButton.translatesAutoresizingMaskIntoConstraints = NO;

    self.logView = [[UITextView alloc] init];
    self.logView.editable = NO;
    self.logView.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
    self.logView.text = [EngineBridge runtimeStatusText];
    self.logView.layer.borderWidth = 1.0;
    self.logView.layer.borderColor = UIColor.separatorColor.CGColor;
    self.logView.layer.cornerRadius = 8.0;
    self.logView.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *buttons = [[UIStackView alloc] initWithArrangedSubviews:@[self.selectButton, self.runButton]];
    buttons.axis = UILayoutConstraintAxisHorizontal;
    buttons.spacing = 16;
    buttons.distribution = UIStackViewDistributionFillEqually;
    buttons.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[subtitle, help, buttons, self.logView]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 16;
    stack.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:stack];
    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-20],
        [stack.topAnchor constraintEqualToAnchor:guide.topAnchor constant:20],
        [stack.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor constant:-20],
        [self.logView.heightAnchor constraintGreaterThanOrEqualToConstant:300]
    ]];
}

- (void)selectFolder {
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc]
        initForOpeningContentTypes:@[UTTypeFolder] asCopy:NO];
    picker.delegate = self;
    picker.allowsMultipleSelection = NO;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)runPressed {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Phase 2"
        message:[EngineBridge runtimeStatusText]
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    (void)controller;
    NSURL *url = urls.firstObject;
    if (!url) return;

    BOOL scoped = [url startAccessingSecurityScopedResource];
    self.selectedFolderURL = url;
    self.logView.text = [EngineBridge diagnoseGameFolderURL:url];
    self.runButton.enabled = [EngineBridge isRuntimeLinked];
    if (scoped) [url stopAccessingSecurityScopedResource];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    (void)controller;
}

@end
