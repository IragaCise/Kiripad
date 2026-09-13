#import "KiriPadViewController.h"
#import "EngineBridge.h"
#import "EngineRenderView.h"
#import "EngineRuntimeHost.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface KiriPadViewController () <UIDocumentPickerDelegate, EngineRuntimeHostDelegate>
@property(nonatomic, strong) UITextView *logView;
@property(nonatomic, strong) UIButton *selectButton;
@property(nonatomic, strong) UIButton *probeButton;
@property(nonatomic, strong) UIButton *runButton;
@property(nonatomic, strong) EngineRenderView *renderView;
@property(nonatomic, strong) EngineRuntimeHost *runtimeHost;
@property(nonatomic, strong, nullable) NSURL *selectedFolderURL;
@property(nonatomic, strong, nullable) NSURL *gameRootURL;
@property(nonatomic) BOOL securityScopeActive;
@end

@implementation KiriPadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"KiriPad Phase 2A";
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    self.runtimeHost = [[EngineRuntimeHost alloc] init];
    self.runtimeHost.delegate = self;

    UILabel *subtitle = [[UILabel alloc] init];
    subtitle.text = @"吉里吉里作品：起動前プローブ＋実験ランタイム";
    subtitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    subtitle.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *help = [[UILabel alloc] init];
    help.text = @"自分で所有しているゲームフォルダを選択してください。Phase 2Aは実ゲームルートを自動判定し、平文スクリプトのプラグイン要求と、ランタイム起動時のログを確認します。XP3の復号・改変は行いません。";
    help.numberOfLines = 0;
    help.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    help.translatesAutoresizingMaskIntoConstraints = NO;

    self.selectButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.selectButton setTitle:@"ゲームフォルダを選択" forState:UIControlStateNormal];
    [self.selectButton addTarget:self action:@selector(selectFolder) forControlEvents:UIControlEventTouchUpInside];

    self.probeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.probeButton setTitle:@"起動前プローブ" forState:UIControlStateNormal];
    self.probeButton.enabled = NO;
    [self.probeButton addTarget:self action:@selector(probePressed) forControlEvents:UIControlEventTouchUpInside];

    self.runButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.runButton setTitle:@"ランタイム起動" forState:UIControlStateNormal];
    self.runButton.enabled = NO;
    [self.runButton addTarget:self action:@selector(runPressed) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *buttons = [[UIStackView alloc] initWithArrangedSubviews:@[self.selectButton, self.probeButton, self.runButton]];
    buttons.axis = UILayoutConstraintAxisHorizontal;
    buttons.spacing = 10;
    buttons.distribution = UIStackViewDistributionFillEqually;
    buttons.translatesAutoresizingMaskIntoConstraints = NO;

    self.renderView = [[EngineRenderView alloc] init];
    self.renderView.runtimeHost = self.runtimeHost;
    self.renderView.layer.borderColor = UIColor.separatorColor.CGColor;
    self.renderView.layer.borderWidth = 1.0;
    self.renderView.layer.cornerRadius = 8.0;
    self.renderView.clipsToBounds = YES;
    self.renderView.translatesAutoresizingMaskIntoConstraints = NO;

    self.logView = [[UITextView alloc] init];
    self.logView.editable = NO;
    self.logView.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    self.logView.text = [EngineBridge runtimeStatusText];
    self.logView.layer.borderWidth = 1.0;
    self.logView.layer.borderColor = UIColor.separatorColor.CGColor;
    self.logView.layer.cornerRadius = 8.0;
    self.logView.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[subtitle, help, buttons, self.renderView, self.logView]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 10;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stack];

    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    NSLayoutConstraint *aspect = [self.renderView.heightAnchor constraintEqualToAnchor:self.renderView.widthAnchor multiplier:9.0/16.0];
    aspect.priority = UILayoutPriorityDefaultHigh;
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-16],
        [stack.topAnchor constraintEqualToAnchor:guide.topAnchor constant:12],
        [stack.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor constant:-12],
        aspect,
        [self.renderView.heightAnchor constraintLessThanOrEqualToConstant:420],
        [self.logView.heightAnchor constraintGreaterThanOrEqualToConstant:190]
    ]];
}

- (void)selectFolder {
    if (self.runtimeHost.isRunning) [self.runtimeHost stop];
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc]
        initForOpeningContentTypes:@[UTTypeFolder] asCopy:NO];
    picker.delegate = self;
    picker.allowsMultipleSelection = NO;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)probePressed {
    if (!self.selectedFolderURL) return;
    NSString *probe = [EngineBridge startupProbeForGameFolderURL:self.selectedFolderURL];
    self.logView.text = [self.logView.text stringByAppendingFormat:@"\n%@", probe];
    [self scrollLogToBottom];
}

- (void)runPressed {
    if (self.runtimeHost.isRunning) {
        [self.runtimeHost stop];
        return;
    }
    if (!self.gameRootURL) return;
    NSError *error = nil;
    if (![self.runtimeHost startGameAtURL:self.gameRootURL error:&error]) {
        [self appendLog:[NSString stringWithFormat:@"\n[Phase2A] 起動できません: %@\n", error.localizedDescription ?: @"unknown"]];
    }
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    (void)controller;
    NSURL *url = urls.firstObject;
    if (!url) return;

    if (self.securityScopeActive && self.selectedFolderURL) {
        [self.selectedFolderURL stopAccessingSecurityScopedResource];
        self.securityScopeActive = NO;
    }
    self.securityScopeActive = [url startAccessingSecurityScopedResource];
    self.selectedFolderURL = url;
    self.gameRootURL = [EngineBridge resolvedGameRootURLForSelectedURL:url];
    self.logView.text = [EngineBridge diagnoseGameFolderURL:url];
    self.probeButton.enabled = YES;
    self.runButton.enabled = [EngineBridge isRuntimeLinked] && self.gameRootURL != nil;
    [self.runButton setTitle:self.runtimeHost.isRunning ? @"ランタイム停止" : @"ランタイム起動" forState:UIControlStateNormal];
    [self scrollLogToBottom];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller { (void)controller; }

- (void)appendLog:(NSString *)text {
    if (!text.length) return;
    self.logView.text = [self.logView.text stringByAppendingString:text];
    [self scrollLogToBottom];
}

- (void)scrollLogToBottom {
    if (self.logView.text.length == 0) return;
    NSRange range = NSMakeRange(self.logView.text.length - 1, 1);
    [self.logView scrollRangeToVisible:range];
}

#pragma mark - EngineRuntimeHostDelegate

- (void)engineRuntimeHost:(EngineRuntimeHost *)host didAppendLog:(NSString *)text {
    (void)host;
    [self appendLog:text];
}

- (void)engineRuntimeHost:(EngineRuntimeHost *)host didProduceImage:(UIImage *)image pixelSize:(CGSize)pixelSize {
    (void)host;
    self.renderView.enginePixelSize = pixelSize;
    self.renderView.image = image;
}

- (void)engineRuntimeHost:(EngineRuntimeHost *)host didChangeRunning:(BOOL)running {
    (void)host;
    [self.runButton setTitle:running ? @"ランタイム停止" : @"ランタイム起動" forState:UIControlStateNormal];
    self.selectButton.enabled = !running;
    self.probeButton.enabled = !running && self.selectedFolderURL != nil;
    self.runButton.enabled = [EngineBridge isRuntimeLinked] && self.gameRootURL != nil;
}

- (void)dealloc {
    [self.runtimeHost stop];
    if (self.securityScopeActive && self.selectedFolderURL) {
        [self.selectedFolderURL stopAccessingSecurityScopedResource];
    }
}

@end
