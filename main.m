#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#include <dlfcn.h>
#include <sys/utsname.h>

static NSString* ZernLoc(NSString *key) {
    NSString *ret = NSLocalizedString(key, nil);
    return ret;
}

@interface ZernLogCell : UITableViewCell
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subLabel;
@property (nonatomic, strong) UILabel *tagLabel;
@property (nonatomic, strong) UIView *highlightOverlay;
@property (nonatomic, strong) UIViewPropertyAnimator *pressAnimator;
@property (nonatomic, assign) BOOL isHighRiskCell;
@end

@implementation ZernLogCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.isHighRiskCell = NO;
        self.containerView = [[UIView alloc] init];
        self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
        self.containerView.layer.cornerRadius = 12;
        self.containerView.clipsToBounds = YES;
        if (@available(iOS 13.0, *)) {
            self.containerView.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trait) {
                if (trait.userInterfaceStyle == UIUserInterfaceStyleDark) {
                    return [UIColor secondarySystemBackgroundColor];
                } else {
                    return [UIColor systemGroupedBackgroundColor];
                }
            }];
        } else {
            self.containerView.backgroundColor = [UIColor systemGroupedBackgroundColor];
        }
        
        [self.contentView addSubview:self.containerView];
        
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.titleLabel.font = [UIFont systemFontOfSize:14.5 weight:UIFontWeightSemibold];
        self.titleLabel.numberOfLines = 1;
        self.titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        [self.containerView addSubview:self.titleLabel];
        
        self.subLabel = [[UILabel alloc] init];
        self.subLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.subLabel.font = [UIFont systemFontOfSize:11.5];
        self.subLabel.textColor = [UIColor secondaryLabelColor];
        [self.containerView addSubview:self.subLabel];
        
        self.tagLabel = [[UILabel alloc] init];
        self.tagLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.tagLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
        self.tagLabel.textAlignment = NSTextAlignmentCenter;
        self.tagLabel.layer.cornerRadius = 4;
        self.tagLabel.clipsToBounds = YES;
        self.tagLabel.textColor = [UIColor whiteColor];
        self.tagLabel.preferredMaxLayoutWidth = 52;
        [self.containerView addSubview:self.tagLabel];
        
        self.highlightOverlay = [[UIView alloc] init];
        self.highlightOverlay.translatesAutoresizingMaskIntoConstraints = NO;
        self.highlightOverlay.backgroundColor = [UIColor systemGrayColor];
        self.highlightOverlay.alpha = 0;
        [self.containerView addSubview:self.highlightOverlay];
        [self.containerView bringSubviewToFront:self.highlightOverlay];
        
        [NSLayoutConstraint activateConstraints:@[
            [self.containerView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:14],
            [self.containerView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-14],
            [self.containerView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:5],
            [self.containerView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-5],
            
            [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:14],
            [self.titleLabel.topAnchor constraintEqualToAnchor:self.containerView.topAnchor constant:12],
            [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.tagLabel.leadingAnchor constant:-8],
            
            [self.subLabel.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:14],
            [self.subLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:4],
            [self.subLabel.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-14],
            [self.subLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.containerView.bottomAnchor constant:-12],
            
            [self.tagLabel.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-14],
            [self.tagLabel.centerYAnchor constraintEqualToAnchor:self.titleLabel.centerYAnchor],
            [self.tagLabel.widthAnchor constraintEqualToConstant:52],
            [self.tagLabel.heightAnchor constraintEqualToConstant:18],
            
            [self.highlightOverlay.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor],
            [self.highlightOverlay.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor],
            [self.highlightOverlay.topAnchor constraintEqualToAnchor:self.containerView.topAnchor],
            [self.highlightOverlay.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor]
        ]];
    }
    return self;
}

- (void)setTagStyle:(NSString *)tagName isPanic:(BOOL)isPanic {
    self.tagLabel.text = tagName;
    if (isPanic) {
        self.tagLabel.backgroundColor = [UIColor systemRedColor];
    } else if ([tagName isEqualToString:@"Jetsam"]) {
        self.tagLabel.backgroundColor = [UIColor systemOrangeColor];
    } else if ([tagName isEqualToString:@"CPUKill"]) {
        self.tagLabel.backgroundColor = [UIColor systemYellowColor];
    } else {
        self.tagLabel.backgroundColor = [UIColor systemBlueColor];
    }
}

- (void)runPressDown {
    if (self.pressAnimator && self.pressAnimator.isRunning) {
        [self.pressAnimator stopAnimation:YES];
    }
    self.pressAnimator = [[UIViewPropertyAnimator alloc] initWithDuration:0.2 dampingRatio:0.7 animations:^{
        self.containerView.transform = CGAffineTransformMakeScale(0.96, 0.96);
        self.containerView.layer.cornerRadius = 0;
        self.highlightOverlay.alpha = 0.12;
    }];
    [self.pressAnimator startAnimation];
}

- (void)runPressUp {
    if (self.pressAnimator && self.pressAnimator.isRunning) {
        [self.pressAnimator stopAnimation:YES];
    }
    self.pressAnimator = [[UIViewPropertyAnimator alloc] initWithDuration:0.35 dampingRatio:0.55 animations:^{
        self.containerView.transform = CGAffineTransformIdentity;
        self.containerView.layer.cornerRadius = 12;
        self.highlightOverlay.alpha = 0;
    }];
    __weak typeof(self) weakSelf = self;
    [self.pressAnimator addCompletion:^(UIViewAnimatingPosition finalPos) {
        if (finalPos == UIViewAnimatingPositionEnd && weakSelf.isHighRiskCell) {
            if (@available(iOS 13.0, *)) {
                weakSelf.containerView.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trait) {
                    if (trait.userInterfaceStyle == UIUserInterfaceStyleDark) {
                        return [UIColor colorWithRed:0.42 green:0.18 blue:0.18 alpha:0.75];
                    }else{
                        return [UIColor colorWithRed:1.00 green:0.88 blue:0.88 alpha:1.0];
                    }
                }];
            } else {
                weakSelf.containerView.backgroundColor = [UIColor colorWithRed:1.00 green:0.88 blue:0.88 alpha:1.0];
            }
        }
    }];
    [self.pressAnimator startAnimation];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self runPressDown];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    [self runPressUp];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    [self runPressUp];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        if (self.isHighRiskCell) {
            self.containerView.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trait) {
                if (trait.userInterfaceStyle == UIUserInterfaceStyleDark) {
                    return [UIColor colorWithRed:0.42 green:0.18 blue:0.18 alpha:0.75];
                }else{
                    return [UIColor colorWithRed:1.00 green:0.88 blue:0.88 alpha:1.0];
                }
            }];
        }else{
            self.containerView.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trait) {
                if (trait.userInterfaceStyle == UIUserInterfaceStyleDark) {
                    return [UIColor secondarySystemBackgroundColor];
                } else {
                    return [UIColor systemGroupedBackgroundColor];
                }
            }];
        }
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    if (self.pressAnimator && self.pressAnimator.isRunning) {
        [self.pressAnimator stopAnimation:YES];
    }
    self.containerView.transform = CGAffineTransformIdentity;
    self.containerView.layer.cornerRadius = 12;
    self.highlightOverlay.alpha = 0.0;
    self.tagLabel.text = nil;
    self.isHighRiskCell = NO;
    if (@available(iOS 13.0, *)) {
        self.containerView.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trait) {
            if (trait.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor secondarySystemBackgroundColor];
            } else {
                return [UIColor systemGroupedBackgroundColor];
            }
        }];
    }
}
@end

@interface ZernAboutCell : UITableViewCell
@property (nonatomic, strong) UILabel *leftLabel;
@property (nonatomic, strong) UILabel *rightLabel;
@property (nonatomic, strong) UIImageView *accessoryIcon;
@end
@implementation ZernAboutCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.leftLabel = [[UILabel alloc] init];
        self.leftLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.leftLabel.font = [UIFont systemFontOfSize:17];
        self.leftLabel.textColor = [UIColor labelColor];

        self.rightLabel = [[UILabel alloc] init];
        self.rightLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.rightLabel.font = [UIFont systemFontOfSize:17];
        self.rightLabel.textColor = [UIColor secondaryLabelColor];
        self.rightLabel.textAlignment = NSTextAlignmentRight;
        
        self.accessoryIcon = [[UIImageView alloc] init];
        self.accessoryIcon.translatesAutoresizingMaskIntoConstraints = NO;
        self.accessoryIcon.contentMode = UIViewContentModeScaleAspectFit;
        self.accessoryIcon.tintColor = [UIColor secondaryLabelColor];

        [self.contentView addSubview:self.leftLabel];
        [self.contentView addSubview:self.rightLabel];
        [self.contentView addSubview:self.accessoryIcon];

        [NSLayoutConstraint activateConstraints:@[
            [self.leftLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
            [self.leftLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [self.leftLabel.widthAnchor constraintLessThanOrEqualToAnchor:self.contentView.widthAnchor multiplier:0.45],

            [self.accessoryIcon.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
            [self.accessoryIcon.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [self.accessoryIcon.widthAnchor constraintEqualToConstant:20],
            [self.accessoryIcon.heightAnchor constraintEqualToConstant:20],
            
            [self.rightLabel.trailingAnchor constraintEqualToAnchor:self.accessoryIcon.trailingAnchor],
            [self.rightLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [self.rightLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leftLabel.trailingAnchor constant:12]
        ]];
    }
    return self;
}
@end

@interface ZernDetailVC : UIViewController
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, copy) NSString *rawLogText;
- (NSDictionary *)socMap;
- (NSNumber *)extractSocIdFromText:(NSString *)text;
- (NSString *)getDeviceHumanName;
- (NSString *)parseCrashContent:(NSString *)logText;
- (void)onParseTap;
- (void)textViewDidChangeSelection:(NSNotification *)noti;
@end

@implementation ZernDetailVC

- (NSDictionary *)socMap {
    return @{
        @8010: @[@"A10", @"iPhone 7 / 7 Plus"],
        @8015: @[@"A11", @"iPhone 8 / 8 Plus / iPhone X"],
        @8020: @[@"A12", @"iPhone XS / XS Max / XR"],
        @8027: @[@"A13", @"iPhone 11 series"],
        @8030: @[@"A14", @"iPhone 12 series"],
        @8032: @[@"A15", @"iPhone 13 / 14"],
        @8034: @[@"A16", @"iPhone 14 Pro"],
        @8036: @[@"A17 Pro", @"iPhone 15 Pro"]
    };
}

- (NSNumber *)extractSocIdFromText:(NSString *)text {
    NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:@"socId:\\s*(\\d+)" options:0 error:nil];
    NSTextCheckingResult *res = [reg firstMatchInString:text options:0 range:NSMakeRange(0, text.length)];
    if (res) {
        NSString *numStr = [text substringWithRange:[res rangeAtIndex:1]];
        return @(numStr.integerValue);
    }
    return nil;
}

- (NSString *)getDeviceHumanName {
    static NSString *name = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct utsname sysInfo;
        uname(&sysInfo);
        NSString *machine = [NSString stringWithUTF8String:sysInfo.machine];
        NSDictionary *modelMap = @{
            @"iPhone10,1": @"iPhone 8",
            @"iPhone10,4": @"iPhone 8",
            @"iPhone10,2": @"iPhone 8 Plus",
            @"iPhone10,5": @"iPhone 8 Plus",
            @"iPhone10,3": @"iPhone X",
            @"iPhone10,6": @"iPhone X"
        };
        name = modelMap[machine] ?: machine;
    });
    return name;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = ZernLoc(@"title_log_detail");
    
    UIBarButtonItem *parseItem = [[UIBarButtonItem alloc] initWithTitle:ZernLoc(@"parse_crash") style:UIBarButtonItemStylePlain target:self action:@selector(onParseTap)];
    self.navigationItem.rightBarButtonItem = parseItem;
    
    self.textView = [[UITextView alloc] init];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.editable = NO;
    self.textView.font = [UIFont fontWithName:@"Menlo" size:11];
    self.textView.text = self.rawLogText;
    self.textView.showsHorizontalScrollIndicator = NO;
    self.textView.alwaysBounceHorizontal = NO;
    self.textView.textContainer.lineBreakMode = NSLineBreakByCharWrapping;
    self.textView.textContainer.widthTracksTextView = YES;
    
    [self.view addSubview:self.textView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.textView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:10],
        [self.textView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:10],
        [self.textView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-10],
        [self.textView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-10]
    ]];
}

- (void)textViewDidChangeSelection:(NSNotification *)noti {
    UITextView *tv = noti.object;
    if (tv.selectedRange.location == 0 && tv.selectedRange.length == tv.text.length && tv.text.length > 0) {
    }
}

- (NSString *)parseCrashContent:(NSString *)logText {
    NSRegularExpression *regBug = [NSRegularExpression regularExpressionWithPattern:@"bug_type\":\"(\\d+)\"" options:0 error:nil];
    NSRegularExpression *regProcName = [NSRegularExpression regularExpressionWithPattern:@"procName\"\\s*:\\s*\"([^\"]+)\"" options:0 error:nil];
    NSRegularExpression *regCPUKilled = [NSRegularExpression regularExpressionWithPattern:@"cpu usage.*Process killed" options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSString *bugNumStr = nil;
    NSString *procName = nil;
    
    NSTextCheckingResult *resBug = [regBug firstMatchInString:logText options:0 range:NSMakeRange(0, logText.length)];
    if (resBug) {
        bugNumStr = [logText substringWithRange:[resBug rangeAtIndex:1]];
    }
    NSTextCheckingResult *resProc = [regProcName firstMatchInString:logText options:0 range:NSMakeRange(0, logText.length)];
    if (resProc) {
        procName = [logText substringWithRange:[resProc rangeAtIndex:1]];
    }
    NSString *proc = procName ?: ZernLoc(@"text_unknown_proc");

    if ([regCPUKilled numberOfMatchesInString:logText options:0 range:NSMakeRange(0, logText.length)] > 0) {
        return [NSString stringWithFormat:ZernLoc(@"parse_bug206"), proc];
    }

    if ([logText containsString:@"\"name\":\"Reset count\""]) {
        NSNumber *socIdNum = [self extractSocIdFromText:logText];
        NSArray *socInfo = [self socMap][socIdNum];
        NSString *chipName = @"Unknown Chip";
        NSString *devName = [self getDeviceHumanName];
        if (socInfo) {
            chipName = socInfo[0];
        }
        return [NSString stringWithFormat:@"115 - Watchdog hard reset.\nTrigger: voltage drop, overheat or kernel deadlock, not single app crash!\nsocId:%@ (%@, %@), check battery and temperature", socIdNum, chipName, devName];
    }
    if ([logText containsString:@"WatchdogEvent"]) {
        return ZernLoc(@"parse_watchdog");
    }
    if ([logText containsString:@"Library not loaded"] || [logText containsString:@"dlopen failure"]) {
        return ZernLoc(@"parse_dlopen_fail");
    }
    if ([logText containsString:@"CDHash mismatch"]) {
        return ZernLoc(@"parse_cdhash_mismatch");
    }
    if ([logText containsString:@"sandbox violation"]) {
        return ZernLoc(@"parse_sandbox");
    }
    if ([logText containsString:@"__pthread_kill"]) {
        return ZernLoc(@"parse_pthread_kill");
    }

    if (bugNumStr) {
        int bugType = bugNumStr.intValue;
        if (bugType == 115) {
            return ZernLoc(@"parse_bug115");
        }
        else if (bugType == 206) {
            return [NSString stringWithFormat:ZernLoc(@"parse_bug206"), proc];
        }
        else if (bugType >= 100 && bugType <= 199) {
            if (bugType == 120) {
                return ZernLoc(@"parse_bug120");
            }
            if (bugType == 134) {
                return ZernLoc(@"parse_bug134");
            }
            if ([logText containsString:@"memory"]) {
                return [NSString stringWithFormat:ZernLoc(@"parse_mem_issue"), proc];
            } else if ([logText containsString:@"disk"] || [logText containsString:@"write"]) {
                return [NSString stringWithFormat:ZernLoc(@"parse_disk_err"), proc];
            } else {
                return [NSString stringWithFormat:ZernLoc(@"parse_general_crash"), bugType];
            }
        }
        else if (bugType >= 200 && bugType <= 299) {
            if ([logText containsString:@"panic"]) {
                return ZernLoc(@"parse_kernel_panic");
            } else {
                return [NSString stringWithFormat:ZernLoc(@"parse_sys_exception"), bugType];
            }
        }
        else if (bugType >= 300 && bugType <= 399) {
            if (bugType == 302) {
                return [NSString stringWithFormat:ZernLoc(@"parse_bug302"), proc];
            }
            if (bugType == 305) {
                return [NSString stringWithFormat:ZernLoc(@"parse_bug305"), proc];
            }
            if (bugType == 309) {
                return [NSString stringWithFormat:ZernLoc(@"parse_bug309"), proc];
            }
            if (bugType == 310) {
                return [NSString stringWithFormat:ZernLoc(@"parse_bug310"), proc];
            }
            if (procName && [procName isEqualToString:@"parsecd"]) {
                return ZernLoc(@"parse_parsecd_crash");
            } else {
                return [NSString stringWithFormat:ZernLoc(@"parse_app_crash"), bugType, proc];
            }
        }
        else {
            return [NSString stringWithFormat:ZernLoc(@"parse_unknown_bugtype"), bugType];
        }
    }
    
    if ([logText containsString:@"Jetsam"]) {
        return ZernLoc(@"parse_jetsam");
    }
    if ([logText containsString:@"SIGABRT"]) {
        return ZernLoc(@"parse_sigabrt");
    }
    if ([logText containsString:@"SIGSEGV"]) {
        return ZernLoc(@"parse_sigsegv");
    }
    if ([logText containsString:@"SIGBUS"]) {
        return ZernLoc(@"parse_sigbus");
    }
    if ([logText containsString:@"SIGTRAP"]) {
        return ZernLoc(@"parse_sigtrap");
    }
    if ([logText containsString:@"SIGKILL"]) {
        return ZernLoc(@"parse_sigkill");
    }
    if ([logText containsString:@"code signature"]) {
        return ZernLoc(@"parse_codesign_err");
    }
    if ([logText containsString:@"dlopen"] || [logText containsString:@"Library not loaded"]) {
        return ZernLoc(@"parse_dylib_load_fail");
    }
    if ([logText containsString:@"EXC_CRASH"]) {
        return ZernLoc(@"parse_exc_crash");
    }
    if ([logText containsString:@"EXC_BAD_INSTRUCTION"]) {
        return ZernLoc(@"parse_bad_inst");
    }
    if ([logText containsString:@"SIGPIPE"]) {
        return ZernLoc(@"parse_sigpipe");
    }
    if ([logText containsString:@"SIGHUP"]) {
        return ZernLoc(@"parse_sighup");
    }
    if ([logText containsString:@"SIGINT"]) {
        return ZernLoc(@"parse_sigint");
    }
    if ([logText containsString:@"SIGUSR1"]) {
        return ZernLoc(@"parse_sigusr1");
    }
    if ([logText containsString:@"SIGUSR2"]) {
        return ZernLoc(@"parse_sigusr2");
    }
    if ([logText containsString:@"EXC_BAD_ACCESS"]) {
        return ZernLoc(@"parse_mach_bad_access");
    }
    if ([logText containsString:@"EXC_BAD_INSTRUCTION"]) {
        return ZernLoc(@"parse_mach_bad_inst");
    }
    if ([logText containsString:@"EXC_BREAKPOINT"]) {
        return ZernLoc(@"parse_mach_breakpoint");
    }
    if ([logText containsString:@"EXC_RESOURCE"]) {
        return ZernLoc(@"parse_mach_resource");
    }
    if ([logText containsString:@"EXC_GUARD"]) {
        return ZernLoc(@"parse_mach_guard");
    }
    if ([logText containsString:@"stack corruption"]) {
        return ZernLoc(@"parse_stack_corrupt");
    }
    if ([logText containsString:@"NSException"]) {
        return ZernLoc(@"parse_ns_exception");
    }
    if ([logText containsString:@"out of bounds"]) {
        return ZernLoc(@"parse_out_of_bounds");
    }
    if ([logText containsString:@"double free"]) {
        return ZernLoc(@"parse_double_free");
    }
    if ([logText containsString:@"dangling pointer"]) {
        return ZernLoc(@"parse_dangling_ptr");
    }
    if ([logText containsString:@"deadlock"]) {
        return ZernLoc(@"parse_deadlock");
    }
    if ([logText containsString:@"heap corruption"]) {
        return ZernLoc(@"parse_heap_corrupt");
    }
    if ([logText containsString:@"mmap failed"]) {
        return ZernLoc(@"parse_mmap_fail");
    }
    if ([logText containsString:@"mach_msg failed"]) {
        return ZernLoc(@"parse_bad_mach_msg");
    }
    if ([logText containsString:@"thread limit"]) {
        return ZernLoc(@"parse_thread_limit");
    }
    if ([logText containsString:@"file descriptor limit"]) {
        return ZernLoc(@"parse_file_limit");
    }
    if ([logText containsString:@"kext panic"]) {
        return ZernLoc(@"parse_kext_pan");
    }
    if ([logText containsString:@"power loss"]) {
        return ZernLoc(@"parse_power_loss");
    }
    if ([logText containsString:@"battery overheat"]) {
        return ZernLoc(@"parse_bat_overheat");
    }
    if ([logText containsString:@"SMC fault"]) {
        return ZernLoc(@"parse_smc_fault");
    }
    
    return ZernLoc(@"parse_unknown_crash");
}

- (void)onParseTap {
    NSString *res = [self parseCrashContent:self.rawLogText];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:ZernLoc(@"parse_title") message:res preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:ZernLoc(@"parse_close") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

typedef NS_ENUM(NSInteger, LogFilterMode) {
    LogFilterModeAll,
    LogFilterModeApp,
    LogFilterModeSystem
};

typedef NS_ENUM(NSInteger, LogTimeRange) {
    LogTimeRangeAny,
    LogTimeRangeToday,
    LogTimeRange3Days
};

typedef NS_ENUM(NSInteger, AppSubFilter) {
    AppSubFilterAll,
    AppSubFilterNormal,
    AppSubFilterJetsam,
    AppSubFilterCPUKill
};

typedef NS_ENUM(NSInteger, SysLogSubFilter) {
    SysLogSubFilterAll,
    SysLogSubFilterPanic,
    SysLogSubFilterDaemon,
    SysLogSubFilterResourceKill,
    SysLogSubFilterWatchdogReset,
    SysLogSubFilterOther
};

@interface ZernMainVC : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSMutableArray *allLogArray;
@property (nonatomic, strong) NSMutableArray *filteredLogArray;
@property (nonatomic, assign) LogFilterMode filterMode;
@property (nonatomic, assign) LogTimeRange timeRange;
@property (nonatomic, assign) AppSubFilter appSubFilter;
@property (nonatomic, assign) SysLogSubFilter sysSubFilter;
@property (nonatomic, strong) UIBarButtonItem *filterItem;
@property (nonatomic, assign) LogFilterMode lastFilterMode;
@property (nonatomic, assign) LogTimeRange lastTimeRange;
@property (nonatomic, assign) AppSubFilter lastAppSubFilter;
@property (nonatomic, assign) SysLogSubFilter lastSysSubFilter;
@property (nonatomic, copy) NSString *lastKeyword;
@property (nonatomic, assign) BOOL hasLogDirPermission;
- (void)loadLogList;
- (BOOL)isAppLogFile:(NSString *)fileName;
- (NSString *)getTagTextForLog:(NSString *)fileName content:(NSString *)content isPanic:(BOOL *)isPanic;
- (BOOL)isHighRiskLogFile:(NSString *)filePath content:(NSString**)outContent;
- (void)reloadUIAfterLangChange;
- (BOOL)filzaIsInstalled;
- (void)openFileInFilza:(NSString *)filePath;
- (void)removeLogItem:(NSDictionary *)item;
- (UIImage *)appStoreAIcon;
- (void)rebuildFilterMenu;
- (void)exportLogFile:(NSString *)filePath fileName:(NSString *)logName;
- (UIViewController *)topMostViewController;
- (void)checkCrashDirPermission;
@end

@implementation ZernMainVC

- (UIViewController *)topMostViewController {
    UIViewController *top = nil;
    UIWindow *keyWin = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                keyWin = scene.windows.firstObject;
                break;
            }
        }
    }
    if (!keyWin) {
        keyWin = [UIApplication sharedApplication].keyWindow;
    }
    top = keyWin.rootViewController;
    while (top.presentedViewController) {
        top = top.presentedViewController;
    }
    return top;
}

- (void)checkCrashDirPermission {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *logDirs = @[
        @"/private/var/mobile/Library/Logs/CrashReporter",
        @"/private/var/mobile/Library/Logs/DiagnosticReports"
    ];
    BOOL canRead = NO;
    for (NSString *dir in logDirs) {
        if ([fm fileExistsAtPath:dir] && [fm isReadableFileAtPath:dir]) {
            canRead = YES;
            break;
        }
    }
    self.hasLogDirPermission = canRead;
    if (!canRead) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:ZernLoc(@"perm_title") message:ZernLoc(@"perm_msg") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:ZernLoc(@"text_ok") style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        });
    }
}

- (BOOL)isAppLogFile:(NSString *)fileName {
    NSString *lower = fileName.lowercaseString;
    if ([lower containsString:@"jetsamevent"]
        || [lower containsString:@"resetcounter"]
        || [lower containsString:@"panic-full"]
        || [lower containsString:@"kernelpanic"]
        || [lower containsString:@"daemon"]
        || [lower containsString:@"resource"]
        || [lower containsString:@"watchdogevent"])
    {
        return NO;
    }
    NSString *pattern = @"^[^.]+-\\d{4}-\\d{2}-\\d{2}-\\d{6}\\.ips$";
    NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    NSTextCheckingResult *result = [reg firstMatchInString:fileName options:0 range:NSMakeRange(0, fileName.length)];
    return result != nil;
}

- (BOOL)filzaIsInstalled {
    NSURL *filzaURL = [NSURL URLWithString:@"filza://"];
    return [[UIApplication sharedApplication] canOpenURL:filzaURL];
}

- (void)openFileInFilza:(NSString *)filePath {
    NSString *encodedPath = [filePath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *urlStr = [NSString stringWithFormat:@"filza://view%@", encodedPath];
    NSURL *url = [NSURL URLWithString:urlStr];
    if (url) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

- (void)exportLogFile:(NSString *)filePath fileName:(NSString *)logName {
    NSString *rawText = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    if (!rawText) return;
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:logName];
    [rawText writeToFile:tempPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSURL *fileURL = [NSURL fileURLWithPath:tempPath];
    if (!fileURL) return;
    
    UIActivityViewController *actVC = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL] applicationActivities:nil];
    if (actVC.popoverPresentationController) {
        actVC.popoverPresentationController.sourceView = self.view;
        actVC.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 1, 1);
    }
    actVC.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
        });
    };
    UIViewController *topVC = [self topMostViewController];
    [topVC presentViewController:actVC animated:YES completion:nil];
}

- (BOOL)isHighRiskLogFile:(NSString *)filePath content:(NSString**)outContent {
    NSString *logText = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    *outContent = logText;
    if (!logText) return NO;

    if ([logText containsString:@"bug_type"]) {
        NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:@"bug_type\"\\s*:\\s*\"115\"" options:0 error:nil];
        if ([reg numberOfMatchesInString:logText options:0 range:NSMakeRange(0, logText.length)] > 0) {
            return YES;
        }
    }
    if ([logText containsString:@"panic-full"]) return YES;
    if ([logText containsString:@"spinlock_timeout"]) return YES;
    if ([logText containsString:@"panicString"]) return YES;
    if ([logText containsString:@"panicBacktrace"]) return YES;
    if ([logText containsString:@"kernel-panic"]) return YES;
    return NO;
}

- (NSString *)getTagTextForLog:(NSString *)fileName content:(NSString *)content isPanic:(BOOL *)isPanic {
    *isPanic = NO;
    NSString *fnameLow = fileName.lowercaseString;
    if ([fnameLow containsString:@"panic"] || [fnameLow containsString:@"115"]) {
        *isPanic = YES;
        return @"Panic";
    }
    if ([content containsString:@"cpu usage"] && [content containsString:@"Process killed"]) {
        return @"CPUKill";
    }
    if ([fnameLow containsString:@"jetsamevent"]) {
        return @"Jetsam";
    }
    return @"Crash";
}

- (void)tapToHideKeyboard:(UITapGestureRecognizer *)tap {
    [self.searchBar resignFirstResponder];
}

- (void)reloadUIAfterLangChange {
    self.title = ZernLoc(@"text_log_list");
    self.filterItem.title = ZernLoc(@"text_btn_filter");
    self.searchBar.placeholder = ZernLoc(@"text_search_placeholder");
    [self rebuildFilterMenu];
    [self filterLogs:self.searchBar.text];
}

- (void)rebuildFilterMenu {
    UIAction *actionAll = [UIAction actionWithTitle:ZernLoc(@"text_filter_all") image:[UIImage systemImageNamed:@"circle.circle"] identifier:nil handler:^(UIAction * _Nonnull action) {
        self.filterMode = LogFilterModeAll;
        self.appSubFilter = AppSubFilterAll;
        self.sysSubFilter = SysLogSubFilterAll;
        [self rebuildFilterMenu];
        [self filterLogs:self.searchBar.text];
    }];
    actionAll.state = (self.filterMode == LogFilterModeAll) ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    UIImage *appStoreAImg = [self appStoreAIcon];
    UIAction *appSubAllAct = [UIAction actionWithTitle:ZernLoc(@"text_app_all") image:[UIImage systemImageNamed:@"circle.circle"] identifier:nil handler:^(UIAction * _Nonnull action) {
        self.filterMode = LogFilterModeApp;
        self.appSubFilter = AppSubFilterAll;
        [self rebuildFilterMenu];
        [self filterLogs:self.searchBar.text];
    }];
    appSubAllAct.state = (self.filterMode == LogFilterModeApp && self.appSubFilter == AppSubFilterAll) ? UIMenuElementStateOn : UIMenuElementStateOff;

    UIAction *appSubNormalAct = [UIAction actionWithTitle:ZernLoc(@"text_app_normal") image:[UIImage systemImageNamed:@"exclamationmark.triangle"] identifier:nil handler:^(UIAction * _Nonnull action) {
        self.filterMode = LogFilterModeApp;
        self.appSubFilter = AppSubFilterNormal;
        [self rebuildFilterMenu];
        [self filterLogs:self.searchBar.text];
    }];
    appSubNormalAct.state = (self.filterMode == LogFilterModeApp && self.appSubFilter == AppSubFilterNormal) ? UIMenuElementStateOn : UIMenuElementStateOff;

    UIAction *appSubJetsamAct = [UIAction actionWithTitle:ZernLoc(@"text_app_jetsam") image:[UIImage systemImageNamed:@"memorychip"] identifier:nil handler:^(UIAction * _Nonnull action) {
        self.filterMode = LogFilterModeApp;
        self.appSubFilter = AppSubFilterJetsam;
        [self rebuildFilterMenu];
        [self filterLogs:self.searchBar.text];
    }];
    appSubJetsamAct.state = (self.filterMode == LogFilterModeApp && self.appSubFilter == AppSubFilterJetsam) ? UIMenuElementStateOn : UIMenuElementStateOff;

    UIAction *appSubCPUAct = [UIAction actionWithTitle:ZernLoc(@"text_app_cpukill") image:[UIImage systemImageNamed:@"speedometer"] identifier:nil handler:^(UIAction * _Nonnull action) {
        self.filterMode = LogFilterModeApp;
        self.appSubFilter = AppSubFilterCPUKill;
        [self rebuildFilterMenu];
        [self filterLogs:self.searchBar.text];
    }];
    appSubCPUAct.state = (self.filterMode == LogFilterModeApp && self.appSubFilter == AppSubFilterCPUKill) ? UIMenuElementStateOn : UIMenuElementStateOff;

    UIMenu *appSubMenu = [UIMenu menuWithTitle:ZernLoc(@"text_filter_app") children:@[appSubAllAct, appSubNormalAct, appSubJetsamAct, appSubCPUAct]];
    UIAction *actionApp = [UIAction actionWithTitle:ZernLoc(@"text_filter_app") image:appStoreAImg identifier:nil handler:^(UIAction * _Nonnull action) {
        self.filterMode = LogFilterModeApp;
        self.appSubFilter = AppSubFilterAll;
        [self rebuildFilterMenu];
        [self filterLogs:self.searchBar.text];
    }];
    actionApp.state = (self.filterMode == LogFilterModeApp) ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    UIAction *actionSys = [UIAction actionWithTitle:ZernLoc(@"text_filter_sys") image:[UIImage systemImageNamed:@"gearshape.2"] identifier:nil handler:^(UIAction * _Nonnull action) {
        self.filterMode = LogFilterModeSystem;
        [self rebuildFilterMenu];
        [self filterLogs:self.searchBar.text];
    }];
    actionSys.state = (self.filterMode == LogFilterModeSystem) ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    UIAction *sysSubAllAct = [UIAction actionWithTitle:ZernLoc(@"text_sys_all") image:[UIImage systemImageNamed:@"circle.circle"] identifier:nil handler:^(UIAction * _Nonnull action) {
        self.filterMode = LogFilterModeSystem;
        self.sysSubFilter = SysLogSubFilterAll;
        [self rebuildFilterMenu];
        [self filterLogs:self.searchBar.text];
    }];
    sysSubAllAct.state = (self.filterMode == LogFilterModeSystem && self.sysSubFilter == SysLogSubFilterAll) ? UIMenuElementStateOn : UIMenuElementStateOff;

    UIAction *sysSubPanicAct = [UIAction actionWithTitle:ZernLoc(@"text_sys_panic") image:[UIImage systemImageNamed:@"bolt.trianglebadge.exclamationmark"] identifier:nil handler:^(UIAction * _Nonnull action) {
        self.filterMode = LogFilterModeSystem;
        self.sysSubFilter = SysLogSubFilterPanic;
        [self rebuildFilterMenu];
        [self filterLogs:self.searchBar.text];
    }];
    sysSubPanicAct.state = (self.filterMode == LogFilterModeSystem && self.sysSubFilter == SysLogSubFilterPanic) ? UIMenuElementStateOn : UIMenuElementStateOff;

    UIAction *sysSubDaemonAct = [UIAction actionWithTitle:ZernLoc(@"text_sys_daemon") image:[UIImage systemImageNamed:@"server.rack"] identifier:nil handler:^(UIAction * _Nonnull action) {
        self.filterMode = LogFilterModeSystem;
        self.sysSubFilter = SysLogSubFilterDaemon;
        [self rebuildFilterMenu];
        [self filterLogs:self.searchBar.text];
    }];
    sysSubDaemonAct.state = (self.filterMode == LogFilterModeSystem && self.sysSubFilter == SysLogSubFilterDaemon) ? UIMenuElementStateOn : UIMenuElementStateOff;

    UIAction *sysSubResourceAct = [UIAction actionWithTitle:ZernLoc(@"text_sys_resource") image:[UIImage systemImageNamed:@"chart.line.downtrend.xyaxis"] identifier:nil handler:^(UIAction * _Nonnull action) {
        self.filterMode = LogFilterModeSystem;
        self.sysSubFilter = SysLogSubFilterResourceKill;
        [self rebuildFilterMenu];
        [self filterLogs:self.searchBar.text];
    }];
    sysSubResourceAct.state = (self.filterMode == LogFilterModeSystem && self.sysSubFilter == SysLogSubFilterResourceKill) ? UIMenuElementStateOn : UIMenuElementStateOff;

    UIAction *sysSubWatchdogAct = [UIAction actionWithTitle:ZernLoc(@"text_sys_watchdog") image:[UIImage systemImageNamed:@"clock.arrow.circlepath"] identifier:nil handler:^(UIAction * _Nonnull action) {
        self.filterMode = LogFilterModeSystem;
        self.sysSubFilter = SysLogSubFilterWatchdogReset;
        [self rebuildFilterMenu];
        [self filterLogs:self.searchBar.text];
    }];
    sysSubWatchdogAct.state = (self.filterMode == LogFilterModeSystem && self.sysSubFilter == SysLogSubFilterWatchdogReset) ? UIMenuElementStateOn : UIMenuElementStateOff;

    UIAction *sysSubOtherAct = [UIAction actionWithTitle:ZernLoc(@"text_sys_other") image:[UIImage systemImageNamed:@"ellipsis"] identifier:nil handler:^(UIAction * _Nonnull action) {
        self.filterMode = LogFilterModeSystem;
        self.sysSubFilter = SysLogSubFilterOther;
        [self rebuildFilterMenu];
        [self filterLogs:self.searchBar.text];
    }];
    sysSubOtherAct.state = (self.filterMode == LogFilterModeSystem && self.sysSubFilter == SysLogSubFilterOther) ? UIMenuElementStateOn : UIMenuElementStateOff;

    UIMenu *sysSubMenu = [UIMenu menuWithTitle:ZernLoc(@"text_filter_sys") children:@[sysSubAllAct, sysSubPanicAct, sysSubDaemonAct, sysSubResourceAct, sysSubWatchdogAct, sysSubOtherAct]];
    UIMenu *menuAppWrap = [UIMenu menuWithTitle:ZernLoc(@"text_filter_app") image:appStoreAImg identifier:nil options:UIMenuOptionsDisplayInline children:@[appSubAllAct, appSubNormalAct, appSubJetsamAct, appSubCPUAct]];
UIMenu *menuSysWrap = [UIMenu menuWithTitle:ZernLoc(@"text_filter_sys") image:[UIImage systemImageNamed:@"gearshape.2"] identifier:nil options:UIMenuOptionsDisplayInline children:@[sysSubAllAct, sysSubPanicAct, sysSubDaemonAct, sysSubResourceAct, sysSubWatchdogAct, sysSubOtherAct]];
UIMenu *typeSubMenu = [UIMenu menuWithTitle:ZernLoc(@"text_menu_type") children:@[actionAll, menuAppWrap, menuSysWrap]];

    UIAction *actionTimeAny = [UIAction actionWithTitle:ZernLoc(@"text_time_all") image:[UIImage systemImageNamed:@"clock"] identifier:nil handler:^(UIAction * _Nonnull action) {
        self.timeRange = LogTimeRangeAny;
        [self rebuildFilterMenu];
        [self filterLogs:self.searchBar.text];
    }];
    actionTimeAny.state = (self.timeRange == LogTimeRangeAny) ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    UIAction *actionTimeToday = [UIAction actionWithTitle:ZernLoc(@"text_time_today") image:[UIImage systemImageNamed:@"sun.max"] identifier:nil handler:^(UIAction * _Nonnull action) {
        self.timeRange = LogTimeRangeToday;
        [self rebuildFilterMenu];
        [self filterLogs:self.searchBar.text];
    }];
    actionTimeToday.state = (self.timeRange == LogTimeRangeToday) ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    UIAction *actionTime3Day = [UIAction actionWithTitle:ZernLoc(@"text_time_3day") image:[UIImage systemImageNamed:@"calendar.badge.clock"] identifier:nil handler:^(UIAction * _Nonnull action) {
        self.timeRange = LogTimeRange3Days;
        [self rebuildFilterMenu];
        [self filterLogs:self.searchBar.text];
    }];
    actionTime3Day.state = (self.timeRange == LogTimeRange3Days) ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    UIMenu *timeSubMenu = [UIMenu menuWithTitle:ZernLoc(@"text_menu_time") children:@[actionTimeAny, actionTimeToday, actionTime3Day]];
    
    UIMenu *rootFilterMenu = [UIMenu menuWithChildren:@[timeSubMenu, typeSubMenu]];
    self.filterItem.menu = rootFilterMenu;
}

- (void)loadLogList {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSMutableArray *result = [NSMutableArray array];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *logDirs = @[
            @"/private/var/mobile/Library/Logs/CrashReporter",
            @"/private/var/mobile/Library/Logs/DiagnosticReports"
        ];
        for (NSString *dir in logDirs) {
            if (![fm fileExistsAtPath:dir]) continue;
            NSArray *files = [fm contentsOfDirectoryAtPath:dir error:nil];
            for (NSString *fname in files) {
                if (![fname hasSuffix:@".ips"]) continue;
                NSString *fullPath = [dir stringByAppendingPathComponent:fname];
                NSDictionary *attr = [fm attributesOfItemAtPath:fullPath error:nil];
                if (!attr) continue;
                NSDate *mdate = attr[NSFileModificationDate];
                [result addObject:@{
                    @"name": fname,
                    @"path": fullPath,
                    @"date": mdate
                }];
            }
        }
        NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
        [result sortUsingDescriptors:@[sortDesc]];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.allLogArray = result;
            [self filterLogs:self.searchBar.text];
        });
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = ZernLoc(@"text_log_list");
    self.allLogArray = [NSMutableArray array];
    self.filteredLogArray = [NSMutableArray array];
    self.filterMode = LogFilterModeAll;
    self.timeRange = LogTimeRangeAny;
    self.appSubFilter = AppSubFilterAll;
    self.sysSubFilter = SysLogSubFilterAll;
    self.lastFilterMode = -1;
    self.lastTimeRange = -1;
    self.lastAppSubFilter = -1;
    self.lastSysSubFilter = -1;
    self.lastKeyword = @"";
    self.hasLogDirPermission = NO;
    
    [self checkCrashDirPermission];
    
    UIMenu *emptyMenu = [UIMenu menuWithChildren:@[]];
    self.filterItem = [[UIBarButtonItem alloc] initWithTitle:ZernLoc(@"text_btn_filter") menu:emptyMenu];
    [self rebuildFilterMenu];
    
    UIBarButtonItem *refreshItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(loadLogList)];
    self.navigationItem.leftBarButtonItem = self.filterItem;
    self.navigationItem.rightBarButtonItem = refreshItem;
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchBar.placeholder = ZernLoc(@"text_search_placeholder");
    self.searchBar.delegate = self;
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    [self.view addSubview:self.searchBar];
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 74;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.alwaysBounceHorizontal = NO;
    self.tableView.backgroundColor = [UIColor systemBackgroundColor];
    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    [self.tableView registerClass:[ZernLogCell class] forCellReuseIdentifier:@"ZernLogCell"];
    [self.view addSubview:self.tableView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToHideKeyboard:)];
    tap.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tap];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.searchBar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.searchBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.searchBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        
        [self.tableView.topAnchor constraintEqualToAnchor:self.searchBar.bottomAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];
    
    [self loadLogList];
}

- (UIImage *)appStoreAIcon {
    CGSize size = CGSizeMake(22,22);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return nil;
    CGContextSetFillColorWithColor(ctx, [UIColor labelColor].CGColor);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineWidth(ctx, 2.4);
    
    CGContextMoveToPoint(ctx, 4, 17);
    CGContextAddLineToPoint(ctx, 11, 4);
    CGContextAddLineToPoint(ctx, 18, 17);
    CGContextMoveToPoint(ctx, 7, 11);
    CGContextAddLineToPoint(ctx, 15, 11);
    CGContextStrokePath(ctx);
    
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}


- (void)removeLogItem:(NSDictionary *)item {
    NSString *path = item[@"path"];
    NSError *err = nil;
    BOOL delOk = [[NSFileManager defaultManager] removeItemAtPath:path error:&err];
    if (!delOk) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlert:@"Delete Failed" msg:err.localizedDescription];
        });
        return;
    }

    NSInteger filteredIdx = [self.filteredLogArray indexOfObject:item];
    NSInteger allIdx = [self.allLogArray indexOfObject:item];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (filteredIdx != NSNotFound) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:filteredIdx inSection:0];
            [self.filteredLogArray removeObjectAtIndex:filteredIdx];
            [UIView animateWithDuration:0.3 animations:^{
                [self.tableView deleteRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationFade];
            }];
        } else {
            [self filterLogs:self.searchBar.text];
        }
        if (allIdx != NSNotFound) {
            [self.allLogArray removeObjectAtIndex:allIdx];
        }
    });
}

- (void)filterLogs:(NSString *)keyword {
    if ([self.lastKeyword isEqualToString:keyword] && self.lastFilterMode == self.filterMode && self.lastTimeRange == self.timeRange && self.lastAppSubFilter == self.appSubFilter && self.lastSysSubFilter == self.sysSubFilter) {
        return;
    }
    self.lastKeyword = keyword;
    self.lastFilterMode = self.filterMode;
    self.lastTimeRange = self.timeRange;
    self.lastAppSubFilter = self.appSubFilter;
    self.lastSysSubFilter = self.sysSubFilter;
    
    NSString *kw = keyword.lowercaseString;
    NSDate *now = [NSDate date];
    NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSMutableArray *result = [NSMutableArray array];
        for (NSDictionary *item in self.allLogArray) {
            NSString *fname = item[@"name"];
            NSString *fnameLow = fname.lowercaseString;
            BOOL matchKw = (kw.length == 0) || [fnameLow containsString:kw];
            
            BOOL isAppLog = [self isAppLogFile:fname];
            BOOL matchType = NO;
            if (self.filterMode == LogFilterModeAll) {
                matchType = YES;
            } else if (self.filterMode == LogFilterModeApp) {
                matchType = isAppLog;
            } else if (self.filterMode == LogFilterModeSystem) {
                matchType = !isAppLog;
            }
            
            BOOL matchTime = YES;
            NSDate *fileDate = item[@"date"];
            if (self.timeRange == LogTimeRangeToday) {
                matchTime = [cal isDate:fileDate inSameDayAsDate:now];
            }else if(self.timeRange == LogTimeRange3Days){
                NSTimeInterval threeDaySec = 3 * 24 * 3600;
                NSTimeInterval delta = fabs([now timeIntervalSinceDate:fileDate]);
                matchTime = delta <= threeDaySec;
            }

            BOOL matchSub = YES;
            if (self.filterMode == LogFilterModeApp && self.appSubFilter != AppSubFilterAll) {
                NSString *fullPath = item[@"path"];
                NSString *logText = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:nil];
                if (!logText) logText = @"";
                if (self.appSubFilter == AppSubFilterNormal) {
                    BOOL isJetsam = [logText containsString:@"Jetsam"] || [fnameLow containsString:@"jetsamevent"];
                    BOOL isCPUKill = [logText containsString:@"cpu usage"] && [logText containsString:@"Process killed"];
                    matchSub = !isJetsam && !isCPUKill;
                } else if (self.appSubFilter == AppSubFilterJetsam) {
                    matchSub = [logText containsString:@"Jetsam"] || [fnameLow containsString:@"jetsamevent"];
                } else if (self.appSubFilter == AppSubFilterCPUKill) {
                    matchSub = [logText containsString:@"cpu usage"] && [logText containsString:@"Process killed"];
                }
            }
            if (self.filterMode == LogFilterModeSystem && self.sysSubFilter != SysLogSubFilterAll) {
                NSString *fullPath = item[@"path"];
                NSString *logText = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:nil];
                if (!logText) logText = @"";
                if (self.sysSubFilter == SysLogSubFilterPanic) {
                    matchSub = [logText containsString:@"panic"] || [logText containsString:@"panic-full"];
                } else if (self.sysSubFilter == SysLogSubFilterDaemon) {
                    matchSub = [logText containsString:@"daemon"] || [logText containsString:@"launchd"];
                } else if (self.sysSubFilter == SysLogSubFilterResourceKill) {
                    matchSub = [logText containsString:@"Jetsam"]
                               || [logText containsString:@"cpu usage"]
                               || [logText containsString:@"resource limit"];
                } else if (self.sysSubFilter == SysLogSubFilterWatchdogReset) {
                    matchSub = [logText containsString:@"bug_type\":\"115\""]
                               || [logText containsString:@"Reset count"];
                } else if (self.sysSubFilter == SysLogSubFilterOther) {
                    BOOL hitSpecial = [logText containsString:@"panic"]
                                   || [logText containsString:@"panic-full"]
                                   || [logText containsString:@"daemon"]
                                   || [logText containsString:@"launchd"]
                                   || [logText containsString:@"Jetsam"]
                                   || [logText containsString:@"cpu usage"]
                                   || [logText containsString:@"resource limit"]
                                   || [logText containsString:@"bug_type\":\"115\""]
                                   || [logText containsString:@"Reset count"];
                    matchSub = !hitSpecial;
                }
            }
            
            if (matchKw && matchType && matchTime && matchSub) {
                [result addObject:item];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.filteredLogArray = result;
            [self.tableView reloadData];
        });
    });
}

- (void)showAlert:(NSString *)title msg:(NSString *)msg {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:ZernLoc(@"text_ok") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark SearchBar
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self filterLogs:searchText];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark TableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredLogArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZernLogCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ZernLogCell" forIndexPath:indexPath];
    NSDictionary *info = self.filteredLogArray[indexPath.row];
    NSString *fileName = info[@"name"];
    cell.titleLabel.text = fileName;
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd HH:mm";
    cell.subLabel.text = [fmt stringFromDate:info[@"date"]];
    
    NSString *fileContent = nil;
    BOOL isRisk = [self isHighRiskLogFile:info[@"path"] content:&fileContent];
    cell.isHighRiskCell = isRisk;
    BOOL isPanicTag = NO;
    NSString *tagText = [self getTagTextForLog:fileName content:fileContent isPanic:&isPanicTag];
    [cell setTagStyle:tagText isPanic:isPanicTag];
    
    if (isRisk) {
        if (@available(iOS 13.0, *)) {
            cell.containerView.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trait) {
                if (trait.userInterfaceStyle == UIUserInterfaceStyleDark) {
                    return [UIColor colorWithRed:0.42 green:0.18 blue:0.18 alpha:0.75];
                }else{
                    return [UIColor colorWithRed:1.00 green:0.88 blue:0.88 alpha:1.0];
                }
            }];
        } else {
            cell.containerView.backgroundColor = [UIColor colorWithRed:1.00 green:0.88 blue:0.88 alpha:1.0];
        }
    } else {
        if (@available(iOS 13.0, *)) {
            cell.containerView.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trait) {
                if (trait.userInterfaceStyle == UIUserInterfaceStyleDark) {
                    return [UIColor secondarySystemBackgroundColor];
                } else {
                    return [UIColor systemGroupedBackgroundColor];
                }
            }];
        } else {
            cell.containerView.backgroundColor = [UIColor systemGroupedBackgroundColor];
        }
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *info = self.filteredLogArray[indexPath.row];
    NSString *path = info[@"path"];
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (!content) {
        [self showAlert:ZernLoc(@"text_read_fail") msg:ZernLoc(@"text_read_fail_msg")];
        return;
    }
    ZernDetailVC *vc = [[ZernDetailVC alloc] init];
    vc.rawLogText = content;
    [self.navigationController pushViewController:vc animated:YES];
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point API_AVAILABLE(ios(13.0)){
    NSDictionary *logItem = self.filteredLogArray[indexPath.row];
    NSString *filePath = logItem[@"path"];
    NSString *logName = logItem[@"name"];
    UIContextMenuConfiguration *config = [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> *suggestedActions) {
        NSMutableArray *actions = [NSMutableArray array];
        UIAction *exportAct = [UIAction actionWithTitle:ZernLoc(@"text_export") image:[UIImage systemImageNamed:@"square.and.arrow.up"] identifier:nil handler:^(UIAction * _Nonnull action) {
            [self exportLogFile:filePath fileName:logName];
        }];
        [actions addObject:exportAct];
        
        if ([self filzaIsInstalled]) {
            UIAction *openFilzaAct = [UIAction actionWithTitle:ZernLoc(@"text_open_filza") image:[UIImage systemImageNamed:@"folder"] identifier:nil handler:^(UIAction * _Nonnull action) {
                [self openFileInFilza:filePath];
            }];
            [actions addObject:openFilzaAct];
        }
        UIAction *delAct = [UIAction actionWithTitle:ZernLoc(@"text_delete") image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(UIAction * _Nonnull action) {
            [self removeLogItem:logItem];
        }];
        delAct.attributes = UIMenuElementAttributesDestructive;
        [actions addObject:delAct];
        return [UIMenu menuWithChildren:actions];
    }];
    return config;
}

@end

@interface ZernAboutVC : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
- (void)refreshAboutText;
- (void)openGithub;
- (void)showFeedbackAlert;
- (void)showFeatureIntroAlert;
@end

@implementation ZernAboutVC
- (void)viewDidLoad {
    [super viewDidLoad];
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    } else {
        self.view.backgroundColor = [UIColor lightGrayColor];
    }
    self.title = ZernLoc(@"text_tab_about");
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 52;
    if (@available(iOS 13.0, *)) {
        self.tableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
    } else {
        self.tableView.backgroundColor = [UIColor lightGrayColor];
    }
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 0);
    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    [self.tableView registerClass:[ZernAboutCell class] forCellReuseIdentifier:@"ZernAboutCell"];
    
    [self.view addSubview:self.tableView];
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];
}

- (void)refreshAboutText {
    [self.tableView reloadData];
}

- (void)showFeatureIntroAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:ZernLoc(@"text_feature_intro") message:ZernLoc(@"text_feature_content") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:ZernLoc(@"text_ok") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return ZernLoc(@"text_info");
    } else {
        return ZernLoc(@"text_other");
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 4;
    } else {
        return 2;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZernAboutCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ZernAboutCell" forIndexPath:indexPath];
    if (indexPath.section == 0) {
        NSArray *leftTexts = @[
            ZernLoc(@"text_author"),
            ZernLoc(@"text_version"),
            ZernLoc(@"text_support_ios"),
            ZernLoc(@"text_feature_intro")
        ];
        NSArray *rightTexts = @[@"Feng", @"1.0", @"15.0.0+", @""];
        cell.leftLabel.text = leftTexts[indexPath.row];
        cell.rightLabel.text = rightTexts[indexPath.row];
        if (indexPath.row == 0) {
            cell.rightLabel.textColor = [UIColor systemBlueColor];
        }else{
            cell.rightLabel.textColor = [UIColor secondaryLabelColor];
        }
        if (indexPath.row == 3) {
            cell.accessoryIcon.image = [UIImage systemImageNamed:@"doc.text"];
            cell.accessoryIcon.tintColor = [UIColor secondaryLabelColor];
        } else {
            cell.accessoryIcon.image = [UIImage systemImageNamed:@"chevron.right"];
            cell.accessoryIcon.tintColor = [UIColor clearColor];
        }
    } else {
        NSArray *leftTexts = @[ZernLoc(@"text_github"), ZernLoc(@"text_feedback")];
        cell.leftLabel.text = leftTexts[indexPath.row];
        cell.rightLabel.text = nil;
        if (indexPath.row == 0) {
            cell.accessoryIcon.image = [UIImage systemImageNamed:@"chevron.right"];
            cell.accessoryIcon.tintColor = [UIColor secondaryLabelColor];
        } else {
            cell.accessoryIcon.image = [UIImage systemImageNamed:@"pencil"];
            cell.accessoryIcon.tintColor = [UIColor secondaryLabelColor];
        }
    }
    cell.backgroundColor = [UIColor systemBackgroundColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0 && indexPath.row == 3) {
        [self showFeatureIntroAlert];
        return;
    }
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            [self openGithub];
        } else if (indexPath.row == 1) {
            [self showFeedbackAlert];
        }
    }
}

- (void)openGithub {
    NSURL *url = [NSURL URLWithString:@"https://github.com/Feng117-dev/Zern"];
    if (url) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

- (void)showFeedbackAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:ZernLoc(@"text_feedback_title") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = ZernLoc(@"text_feedback_placeholder");
    }];
    [alert addAction:[UIAlertAction actionWithTitle:ZernLoc(@"text_cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:ZernLoc(@"text_feedback_submit") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *content = alert.textFields.firstObject.text;
        NSLog(@"Feedback submit: %@", content);
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}
@end

@interface ZernTabBarController : UITabBarController <UITabBarControllerDelegate>
@end

@implementation ZernTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = self;
    self.tabBar.translucent = YES;
    self.tabBar.backgroundColor = [UIColor systemBackgroundColor];
    self.tabBar.tintColor = [UIColor systemBlueColor];
    self.tabBar.unselectedItemTintColor = [UIColor secondaryLabelColor];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation SceneDelegate
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if ([scene isKindOfClass:[UIWindowScene class]]) {
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
        
        ZernMainVC *logVC = [[ZernMainVC alloc] init];
        UINavigationController *logNav = [[UINavigationController alloc] initWithRootViewController:logVC];
        logNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:ZernLoc(@"text_tab_log") image:[UIImage systemImageNamed:@"list.bullet"] tag:0];
        
        ZernAboutVC *aboutVC = [[ZernAboutVC alloc] init];
        UINavigationController *aboutNav = [[UINavigationController alloc] initWithRootViewController:aboutVC];
        aboutNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:ZernLoc(@"text_tab_about") image:[UIImage systemImageNamed:@"info.circle"] tag:1];
        
        ZernTabBarController *tab = [[ZernTabBarController alloc] init];
        tab.viewControllers = @[logNav, aboutNav];
        
        self.window.rootViewController = tab;
        [self.window makeKeyAndVisible];
    }
}
- (void)sceneDidDisconnect:(UIScene *)scene {}
- (void)sceneDidBecomeActive:(UIScene *)scene {}
- (void)sceneWillResignActive:(UIScene *)scene {}
- (void)sceneWillEnterForeground:(UIScene *)scene {}
- (void)sceneDidEnterBackground:(UIScene *)scene {}
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([SceneDelegate class]));
    }
}