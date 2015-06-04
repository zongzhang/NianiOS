//
//  TITokenField.m
//  TITokenField
//
//  Created by Tom Irving on 16/02/2010.
//  Copyright 2012 Tom Irving. All rights reserved.
//

#import "TITokenField.h"
#import <QuartzCore/QuartzCore.h>

@interface TITokenField ()
@property (nonatomic, assign) BOOL forcePickSearchResult;
@property (nonatomic, assign) BOOL alwaysShowSearchResult;
@end

//==========================================================
#pragma mark - TITokenFieldView -
//==========================================================

@interface TITokenFieldView (Private)
- (void)setup;
- (NSString *)displayStringForRepresentedObject:(id)object;
- (NSString *)searchResultStringForRepresentedObject:(id)object;
- (void)setSearchResultsVisible:(BOOL)visible;
- (void)resultsForSearchString:(NSString *)searchString;
- (void)presentpopoverAtTokenFieldCaretAnimated:(BOOL)animated;
@end

@implementation TITokenFieldView {
	UIView * _contentView;
	NSMutableArray * _resultsArray;
	UIPopoverController * _popoverController;
}
@dynamic delegate;
@synthesize showAlreadyTokenized = _showAlreadyTokenized;
@synthesize searchSubtitles = _searchSubtitles;
@synthesize subtitleIsPhoneNumber = _subtitleIsPhoneNumber;
@synthesize forcePickSearchResult = _forcePickSearchResult;
@synthesize alwaysShowSearchResult = _alwaysShowSearchResult;
@synthesize shouldSortResults = _shouldSortResults;
@synthesize shouldSearchInBackground = _shouldSearchInBackground;
@synthesize permittedArrowDirections = _permittedArrowDirections;
@synthesize tokenField = _tokenField;
@synthesize resultsTable = _resultsTable;
@synthesize contentView = _contentView;
@synthesize separator = _separator;
@synthesize sourceArray = _sourceArray;

#pragma mark Init
- (instancetype)initWithFrame:(CGRect)frame {
	
    if ((self = [super initWithFrame:frame])){
		[self setup];
	}
	
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	
	if ((self = [super initWithCoder:aDecoder])){
		[self setup];
	}
	
	return self;
}

- (void)setup {
	[self setBackgroundColor:[UIColor clearColor]];
	[self setDelaysContentTouches:NO];
	[self setMultipleTouchEnabled:NO];
	
	_showAlreadyTokenized = NO;
    _searchSubtitles = YES;
    _subtitleIsPhoneNumber = NO;
    _forcePickSearchResult = NO;
    _alwaysShowSearchResult = NO;
    _shouldSortResults = YES;
    _shouldSearchInBackground = NO;
    _permittedArrowDirections = UIPopoverArrowDirectionUp;
	_resultsArray = [NSMutableArray array];
	
	_tokenField = [[TITokenField alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 42)];
	[_tokenField addTarget:self action:@selector(tokenFieldDidBeginEditing:) forControlEvents:UIControlEventEditingDidBegin];
	[_tokenField addTarget:self action:@selector(tokenFieldDidEndEditing:) forControlEvents:UIControlEventEditingDidEnd];
	[_tokenField addTarget:self action:@selector(tokenFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
	[_tokenField addTarget:self action:@selector(tokenFieldFrameWillChange:) forControlEvents:(UIControlEvents)TITokenFieldControlEventFrameWillChange];
	[_tokenField addTarget:self action:@selector(tokenFieldFrameDidChange:) forControlEvents:(UIControlEvents)TITokenFieldControlEventFrameDidChange];
	[_tokenField setDelegate:self];
	[self addSubview:_tokenField];
	
	CGFloat tokenFieldBottom = CGRectGetMaxY(_tokenField.frame);
	
	_separator = [[UIView alloc] initWithFrame:CGRectMake(0, tokenFieldBottom, self.bounds.size.width, 1)];
    [_separator setBackgroundColor:[UIColor colorWithRed:0xe6/255.0 green:0xe6/255.0 blue:0xe6/255.0 alpha:1.0]];
	[self addSubview:_separator];
	
	// This view is created for convenience, because it resizes and moves with the rest of the subviews.
	_contentView = [[UIView alloc] initWithFrame:CGRectMake(0, tokenFieldBottom + 1, self.bounds.size.width,
														   self.bounds.size.height - tokenFieldBottom - 1)];
	[_contentView setBackgroundColor:[UIColor clearColor]];
	[self addSubview:_contentView];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
		
		UITableViewController * tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
        tableViewController.preferredContentSize = CGSizeMake(400, 400);
		[tableViewController.tableView setDelegate:self];
		[tableViewController.tableView setDataSource:self];
        [tableViewController preferredContentSize];
		
		_resultsTable = tableViewController.tableView;
		
		_popoverController = [[UIPopoverController alloc] initWithContentViewController:tableViewController];
	}
	else
	{
		_resultsTable = [[UITableView alloc] initWithFrame:CGRectMake(0, tokenFieldBottom + 1, self.bounds.size.width, 10)];
		[_resultsTable setSeparatorColor:[UIColor colorWithWhite:0.85 alpha:1]];
		[_resultsTable setDelegate:self];
		[_resultsTable setDataSource:self];
		[_resultsTable setHidden:YES];
        [_resultsTable setBackgroundColor:[UIColor whiteColor]];
		[self addSubview:_resultsTable];
		
		_popoverController = nil;
	}
	
	[self bringSubviewToFront:_separator];
	[self bringSubviewToFront:_tokenField];
	[self updateContentSize];
}

#pragma mark Property Overrides
- (void) setChildFrames:(CGRect)frame {
    CGFloat width = frame.size.width;
    [_separator setFrame:((CGRect){_separator.frame.origin, {width, _separator.bounds.size.height}})];
    [_resultsTable setFrame:((CGRect){_resultsTable.frame.origin, {width, _resultsTable.bounds.size.height}})];
    [_contentView setFrame:((CGRect){_contentView.frame.origin, {width, (frame.size.height - CGRectGetMaxY(_tokenField.frame))}})];
    [_tokenField setFrame:((CGRect){_tokenField.frame.origin, {width, _tokenField.bounds.size.height}})];
}

- (void)setFrame:(CGRect)frame {
	
	[super setFrame:frame];
	
    [self setChildFrames:frame];
	
	if (_popoverController.popoverVisible){
		[_popoverController dismissPopoverAnimated:NO];
		[self presentpopoverAtTokenFieldCaretAnimated:NO];
	}
	
	[self updateContentSize];
	[self setNeedsLayout];
}

- (void)setContentOffset:(CGPoint)offset {
	[super setContentOffset:offset];
	[self setNeedsLayout];
}

- (NSArray *)tokenTitles {
	return _tokenField.tokenTitles;
}

- (void)setForcePickSearchResult:(BOOL)forcePickSearchResult
{
    _tokenField.forcePickSearchResult = forcePickSearchResult;
    _forcePickSearchResult = forcePickSearchResult;
}

- (void)setAlwaysShowSearchResult:(BOOL)alwaysShowSearchResult
{
    _tokenField.alwaysShowSearchResult = alwaysShowSearchResult;
    _alwaysShowSearchResult = alwaysShowSearchResult;
    if (_alwaysShowSearchResult) [self resultsForSearchString:_tokenField.text];
}

#pragma mark Event Handling
- (void)layoutSubviews {
	
	[super layoutSubviews];
	
    [self setChildFrames:self.frame];
    
	CGFloat relativeFieldHeight = CGRectGetMaxY(_tokenField.frame) - self.contentOffset.y;
	CGFloat newHeight = self.bounds.size.height - relativeFieldHeight;
	if (newHeight > -1) [_resultsTable setFrame:((CGRect){_resultsTable.frame.origin, {_resultsTable.bounds.size.width, newHeight}})];
}

- (void)updateContentSize {
	[self setContentSize:CGSizeMake(self.bounds.size.width, CGRectGetMaxY(_contentView.frame) + 1)];
}

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (BOOL)becomeFirstResponder {
	return [_tokenField becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
	return [_tokenField resignFirstResponder];
}

#pragma mark TableView Methods
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if ([_tokenField.delegate respondsToSelector:@selector(tokenField:resultsTableView:heightForRowAtIndexPath:)]){
		return [_tokenField.delegate tokenField:_tokenField resultsTableView:tableView heightForRowAtIndexPath:indexPath];
	}
	
	return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	if ([_tokenField.delegate respondsToSelector:@selector(tokenField:didFinishSearch:)]){
		[_tokenField.delegate tokenField:_tokenField didFinishSearch:_resultsArray];
	}
	
	return _resultsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	id representedObject = [_resultsArray objectAtIndex:indexPath.row];
	
	if ([_tokenField.delegate respondsToSelector:@selector(tokenField:resultsTableView:cellForRepresentedObject:)]){
		return [_tokenField.delegate tokenField:_tokenField resultsTableView:tableView cellForRepresentedObject:representedObject];
	}
	
    static NSString * CellIdentifier = @"ResultsCell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    NSString * subtitle = [self searchResultSubtitleForRepresentedObject:representedObject];
	
	if (!cell) cell = [[UITableViewCell alloc] initWithStyle:(subtitle ? UITableViewCellStyleSubtitle : UITableViewCellStyleDefault) reuseIdentifier:CellIdentifier];
	
    [cell.imageView setImage:[self searchResultImageForRepresentedObject:representedObject]];
	[cell.textLabel setText:[self searchResultStringForRepresentedObject:representedObject]];
    [cell.textLabel setTextColor:[UIColor colorWithRed:0xaf/255.0 green:0xaf/255.0 blue:0xaf/255.0 alpha:1]];
	[cell.detailTextLabel setText:subtitle];
    [cell.detailTextLabel setFont:[UIFont systemFontOfSize:14]];
    [cell.detailTextLabel setTextColor:[UIColor colorWithRed:0x33/255.0 green:0x33/255.0 blue:0x33/255.0 alpha:1]];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	id representedObject = [_resultsArray objectAtIndex:indexPath.row];
    TIToken * token = [[TIToken alloc] initWithTitle:[self displayStringForRepresentedObject:representedObject] representedObject:representedObject];
    [_tokenField addToken:token];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (!_alwaysShowSearchResult) [self setSearchResultsVisible:NO];
}

#pragma mark TextField Methods

- (void)tokenFieldDidBeginEditing:(TITokenField *)field {
    if (!_alwaysShowSearchResult) {
        [_resultsArray removeAllObjects];
    }
    
	[_resultsTable reloadData];
}

- (void)tokenFieldDidEndEditing:(TITokenField *)field {
	[self tokenFieldDidBeginEditing:field];
}

- (void)tokenFieldTextDidChange:(TITokenField *)field {
    [self resultsForSearchString:_tokenField.text];
    
    if (_forcePickSearchResult || _alwaysShowSearchResult) {
        [self setSearchResultsVisible:YES];
    } else {
        [self setSearchResultsVisible:(_resultsArray.count > 0)];
    }
}

- (void)tokenFieldFrameWillChange:(TITokenField *)field {
	
	CGFloat tokenFieldBottom = CGRectGetMaxY(_tokenField.frame);
	[_separator setFrame:((CGRect){{_separator.frame.origin.x, tokenFieldBottom}, _separator.bounds.size})];
	[_resultsTable setFrame:((CGRect){{_resultsTable.frame.origin.x, (tokenFieldBottom + 1)}, _resultsTable.bounds.size})];
	[_contentView setFrame:((CGRect){{_contentView.frame.origin.x, (tokenFieldBottom + 1)}, _contentView.bounds.size})];
}

- (void)tokenFieldFrameDidChange:(TITokenField *)field {
	[self updateContentSize];
    
    if ([_tokenField.delegate respondsToSelector:@selector(tokenField:didChangeFrame:)]) {
        [_tokenField.delegate tokenField:_tokenField didChangeFrame:_tokenField.frame];
    }
    
}

#pragma mark Results Methods
- (NSString *)displayStringForRepresentedObject:(id)object {
	
	if ([_tokenField.delegate respondsToSelector:@selector(tokenField:displayStringForRepresentedObject:)]){
		return [_tokenField.delegate tokenField:_tokenField displayStringForRepresentedObject:object];
	}
	
	if ([object isKindOfClass:[NSString class]]){
		return (NSString *)object;
	}
	
	return [NSString stringWithFormat:@"%@", object];
}

- (NSString *)searchResultStringForRepresentedObject:(id)object {
	
	if ([_tokenField.delegate respondsToSelector:@selector(tokenField:searchResultStringForRepresentedObject:)]){
		return [_tokenField.delegate tokenField:_tokenField searchResultStringForRepresentedObject:object];
	}
	
	return [self displayStringForRepresentedObject:object];
}

- (NSString *)searchResultSubtitleForRepresentedObject:(id)object {
	
	if ([_tokenField.delegate respondsToSelector:@selector(tokenField:searchResultSubtitleForRepresentedObject:)]){
		return [_tokenField.delegate tokenField:_tokenField searchResultSubtitleForRepresentedObject:object];
	}
	
	return nil;
}

- (UIImage *)searchResultImageForRepresentedObject:(id)object {
    if ([_tokenField.delegate respondsToSelector:@selector(tokenField:searchResultImageForRepresentedObject:)]) {
        return [_tokenField.delegate tokenField:_tokenField searchResultImageForRepresentedObject:object];
    }
    
    return nil;
}


- (void)setSearchResultsVisible:(BOOL)visible {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
		
		if (visible) [self presentpopoverAtTokenFieldCaretAnimated:YES];
		else [_popoverController dismissPopoverAnimated:YES];
	}
	else
	{
		[_resultsTable setHidden:!visible];
		[_tokenField setResultsModeEnabled:visible];
	}
}

- (void)resultsForSearchString:(NSString *)searchString {

	// The brute force searching method.
	// Takes the input string and compares it against everything in the source array.
	// If the source is massive, this could take some time.
	// You could always subclass and override this if needed or do it on a background thread.
	// GCD would be great for that.

	[_resultsArray removeAllObjects];
	[_resultsTable reloadData];

	searchString = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	if (searchString.length || _forcePickSearchResult || _alwaysShowSearchResult){

        if ([_tokenField.delegate respondsToSelector:@selector(tokenField:shouldUseCustomSearchForSearchString:)] && [_tokenField.delegate tokenField:_tokenField shouldUseCustomSearchForSearchString:searchString]) {
            if ([_tokenField.delegate respondsToSelector:@selector(tokenField:performCustomSearchForSearchString:withCompletionHandler:)]) {
                [_tokenField.delegate tokenField:_tokenField performCustomSearchForSearchString:searchString withCompletionHandler:^(NSArray *results) {
                    [self searchDidFinish:results];
                }];
            }
        } else {
            if (_shouldSearchInBackground) {
                [self performSelectorInBackground:@selector(performSearch:) withObject:searchString];
            } else {
                [self performSearch:searchString];
            }
        }
	}
}

- (void) performSearch:(NSString *)searchString {
  NSMutableArray * resultsToAdd = [[NSMutableArray alloc] init];
  [_sourceArray enumerateObjectsUsingBlock:^(id sourceObject, NSUInteger idx, BOOL *stop){

    NSString * query = [self searchResultStringForRepresentedObject:sourceObject];
    NSString * querySubtitle = [self searchResultSubtitleForRepresentedObject:sourceObject];
    if (!querySubtitle || !_searchSubtitles) {
        querySubtitle = @"";
    } else if (_subtitleIsPhoneNumber) {
        querySubtitle = [querySubtitle stringByReplacingOccurrencesOfString:@" " withString:@""];
    }
    
    if ([query rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
				[querySubtitle rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
        (_forcePickSearchResult && searchString.length == 0) ||
        (_alwaysShowSearchResult && searchString.length == 0)){

      __block BOOL shouldAdd = ![resultsToAdd containsObject:sourceObject];
      if (shouldAdd && !_showAlreadyTokenized){

        [_tokenField.tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *secondStop){
          if ([token.representedObject isEqual:sourceObject]){
            shouldAdd = NO;
            *secondStop = YES;
          }
        }];
      }

      if (shouldAdd) [resultsToAdd addObject:sourceObject];
    }
  }];

    [self searchDidFinish:resultsToAdd];
}

- (void)searchDidFinish:(NSArray *)results
{
    [_resultsArray addObjectsFromArray:results];
    if (_resultsArray.count > 0) {
        if (_shouldSortResults) {
            [_resultsArray sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                return [[self searchResultStringForRepresentedObject:obj1] localizedCaseInsensitiveCompare:[self searchResultStringForRepresentedObject:obj2]];
            }];
        }
        
        [self setSearchResultsVisible:(_resultsArray.count > 0)];
        [self performSelectorOnMainThread:@selector(reloadResultsTable) withObject:nil waitUntilDone:YES];
    }
}


-(void) reloadResultsTable {
  [_resultsTable setHidden:NO];
  [_resultsTable reloadData];
}

- (void)presentpopoverAtTokenFieldCaretAnimated:(BOOL)animated {
	
    UITextPosition * position = [_tokenField positionFromPosition:_tokenField.beginningOfDocument offset:2];
	
	[_popoverController presentPopoverFromRect:[_tokenField caretRectForPosition:position]
                                        inView:_tokenField
					 permittedArrowDirections:[self permittedArrowDirections]
                                      animated:animated];
}

#pragma mark Other
- (NSString *)description {
	return [NSString stringWithFormat:@"<TITokenFieldView %p; Token count = %lu>", self, (unsigned long)self.tokenTitles.count];
}

- (void)dealloc {
	[self setDelegate:nil];
}

@end

//==========================================================
#pragma mark - TITokenField -
//==========================================================
NSString * const kTextEmpty = @"\u200B"; // Zero-Width Space
NSString * const kTextHidden = @"\u200D"; // Zero-Width Joiner

@interface TITokenFieldInternalDelegate ()
@property (nonatomic, weak) id <UITextFieldDelegate> delegate;
@property (nonatomic, weak) TITokenField * tokenField;
@end

@interface TITokenField ()
@property (nonatomic, readonly) CGFloat leftViewWidth;
@property (nonatomic, readonly) CGFloat rightViewWidth;
@property (weak, nonatomic, readonly) UIScrollView * scrollView;
@end

@interface TITokenField (Private)
- (void)setup;
- (CGFloat)layoutTokensInternal;
@end

@implementation TITokenField {
	id __weak delegate;
	TITokenFieldInternalDelegate * _internalDelegate;
	NSMutableArray * _tokens;
	CGPoint _tokenCaret;
    UILabel * _placeHolderLabel;
}
@synthesize delegate = delegate;
@synthesize editable = _editable;
@synthesize resultsModeEnabled = _resultsModeEnabled;
@synthesize removesTokensOnEndEditing = _removesTokensOnEndEditing;
@synthesize numberOfLines = _numberOfLines;
@synthesize selectedToken = _selectedToken;
@synthesize tokenizingCharacters = _tokenizingCharacters;
@synthesize forcePickSearchResult = _forcePickSearchResult;
@synthesize alwaysShowSearchResult = _alwaysShowSearchResult;

#pragma mark Init
- (instancetype)initWithFrame:(CGRect)frame {
	
    if ((self = [super initWithFrame:frame])){
		[self setup];
    }
	
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	
	if ((self = [super initWithCoder:aDecoder])){
		[self setup];
	}
	
	return self;
}

- (void)setup {
	
	[self setBorderStyle:UITextBorderStyleNone];
	[self setFont:[UIFont systemFontOfSize:14]];
    [self setTextColor:[UIColor colorWithRed:0xaf/255.0 green:0xaf/255.0 blue:0xaf/255.0 alpha:1.0]];
	[self setBackgroundColor:[UIColor whiteColor]];
	[self setAutocorrectionType:UITextAutocorrectionTypeNo];
	[self setAutocapitalizationType:UITextAutocapitalizationTypeNone];
	[self setContentVerticalAlignment:UIControlContentVerticalAlignmentTop];
    
	
	[self addTarget:self action:@selector(didBeginEditing) forControlEvents:UIControlEventEditingDidBegin];
	[self addTarget:self action:@selector(didEndEditing) forControlEvents:UIControlEventEditingDidEnd];
	[self addTarget:self action:@selector(didChangeText) forControlEvents:UIControlEventEditingChanged];

	[self setPromptText:@"To:"];
    [self setText:kTextEmpty];
	
	_internalDelegate = [[TITokenFieldInternalDelegate alloc] init];
	[_internalDelegate setTokenField:self];
	[super setDelegate:_internalDelegate];
	
	_tokens = [NSMutableArray array];
	_editable = YES;
	_removesTokensOnEndEditing = NO;
	_tokenizingCharacters = [NSCharacterSet characterSetWithCharactersInString:@","];
    _tokenLimit = -1;
}

#pragma mark Property Overrides
- (void)setFrame:(CGRect)frame {
	[super setFrame:frame];
//	[self.layer setShadowPath:[[UIBezierPath bezierPathWithRect:self.bounds] CGPath]];
	[self layoutTokensAnimated:NO];
}

- (void)setText:(NSString *)text {
	[super setText:(text.length == 0 ? kTextEmpty : text)];
}

- (void)setFont:(UIFont *)font {
	[super setFont:font];
	
	if ([self.leftView isKindOfClass:[UILabel class]]){
		[self setPromptText:((UILabel *)self.leftView).text];
	}
}

- (void)setDelegate:(id<TITokenFieldDelegate>)del {
	delegate = del;
	[_internalDelegate setDelegate:delegate];
}

- (NSArray *)tokens {
	return [_tokens copy];
}

- (NSArray *)tokenTitles {
	
	NSMutableArray * titles = [NSMutableArray array];
	[_tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop){
		if (token.title) [titles addObject:token.title];
	}];
	return titles;
}

- (NSArray *)tokenObjects {
	
	NSMutableArray * objects = [NSMutableArray array];
	[_tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop){
		if (token.representedObject) [objects addObject:token.representedObject];
		else if (token.title) [objects addObject:token.title];
	}];
	return objects;
}

- (UIScrollView *)scrollView {
	return ([self.superview isKindOfClass:[UIScrollView class]] ? (UIScrollView *)self.superview : nil);
}

#pragma mark Event Handling
- (BOOL)becomeFirstResponder {
	return (_editable ? [super becomeFirstResponder] : NO);
}

- (void)didBeginEditing {
    if (_removesTokensOnEndEditing) {
        	[_tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop){[self addToken:token];}];
    }
}

- (void)didEndEditing {
	
	[_selectedToken setSelected:NO];
	_selectedToken = nil;
	
	[self tokenizeText];
	
	if (_removesTokensOnEndEditing){
		
		[_tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop){[token removeFromSuperview];}];
		
		NSString * untokenized = kTextEmpty;
		if (_tokens.count){
			
			NSArray * titles = self.tokenTitles;
			untokenized = [titles componentsJoinedByString:@", "];
            NSDictionary *dict = @{NSFontAttributeName: [UIFont systemFontOfSize:14]};
			CGSize untokSize = [untokenized sizeWithAttributes:dict];
			CGFloat availableWidth = self.bounds.size.width - self.leftView.bounds.size.width - self.rightView.bounds.size.width;
			
			if (_tokens.count > 1 && untokSize.width > availableWidth){
				untokenized = [NSString stringWithFormat:@"%lu recipients", (unsigned long)titles.count];
			}
		}
		
		[self setText:untokenized];
	}

	[self setResultsModeEnabled:NO];
	if (_tokens.count < 1 && self.forcePickSearchResult) {
		[self becomeFirstResponder];
	}
    
//    CGFloat topMargin = floor(self.font.lineHeight * 4 / 7);
//    CGFloat leftMargin = self.leftViewWidth + 18;
//    CGFloat lineHeight = ceilf(self.font.lineHeight) + topMargin + 5;
//	
//    // 如果最后一行没有 token, 移除最后一行
//    if (_numberOfLines > 1) {
//        if (_tokenCaret.x <= leftMargin) {
//            [UIView animateWithDuration:0.3
//                             animations:^{
//                                 self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.bounds.size.height - lineHeight);       // seheight = self.bounds.size.height - lineHeight;
//                                 [(TITokenFieldView *)self.superview tokenFieldFrameWillChange:self];
//                             } completion:^(BOOL finished) {
//                                 if (finished) {
//                                     [self sendActionsForControlEvents:(UIControlEvents)TITokenFieldControlEventFrameDidChange];
//                                 }
//                             }];
//        }
//    }
}

- (void)didChangeText {
	if (!self.text.length)[self setText:kTextEmpty];
	[self showOrHidePlaceHolderLabel];
}

- (void) showOrHidePlaceHolderLabel {
	[_placeHolderLabel setHidden:!(([self.text isEqualToString:kTextEmpty]) && !_tokens.count)];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	
	// Stop the cut, copy, select and selectAll appearing when the field is 'empty'.
	if (action == @selector(cut:) || action == @selector(copy:) || action == @selector(select:) || action == @selector(selectAll:))
		return ![self.text isEqualToString:kTextEmpty];
	
	return [super canPerformAction:action withSender:sender];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	
	if (_selectedToken && touch.view == self) [self deselectSelectedToken];
	return [super beginTrackingWithTouch:touch withEvent:event];
}

#pragma mark Token Handling
- (TIToken *)addTokenWithTitle:(NSString *)title {
	return [self addTokenWithTitle:title representedObject:nil];
}

- (TIToken *)addTokenWithTitle:(NSString *)title representedObject:(id)object {
	
	if (title.length){
		TIToken * token = [[TIToken alloc] initWithTitle:title representedObject:object font:self.font];
		[self addToken:token];
		return token;
	}
	
	return nil;
}

- (void)addTokensWithTitleList:(NSString *)titleList {
    if ([titleList length] > 0) {
        self.text = titleList;
        [self tokenizeText];
    }
}

- (void)addTokensWithTitleArray:(NSArray *)titleArray {
    for (NSString *title in titleArray) {
        [self addTokenWithTitle:title];
    }
}

- (void)addToken:(TIToken *)token {
	
	BOOL shouldAdd = YES;
	if ([delegate respondsToSelector:@selector(tokenField:willAddToken:)]){
		shouldAdd = [delegate tokenField:self willAddToken:token];
	}
	
	if (shouldAdd){
		
		//[self becomeFirstResponder];
		
		[token addTarget:self action:@selector(tokenTouchDown:) forControlEvents:UIControlEventTouchDown];
		[token addTarget:self action:@selector(tokenTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:token];
		
		if (![_tokens containsObject:token]) {
			[_tokens addObject:token];
            [self layoutTokensAnimated:YES];
            
			if ([delegate respondsToSelector:@selector(tokenField:didAddToken:)]){
				[delegate tokenField:self didAddToken:token];
			}
            
			[self showOrHidePlaceHolderLabel];
		}
		
		[self setResultsModeEnabled:NO];
		[self deselectSelectedToken];
	}
}

- (void)removeToken:(TIToken *)token {
	
	if (token == _selectedToken) [self deselectSelectedToken];
	
	BOOL shouldRemove = YES;
	if ([delegate respondsToSelector:@selector(tokenField:willRemoveToken:)]){
		shouldRemove = [delegate tokenField:self willRemoveToken:token];
	}
	
	if (shouldRemove){
		
		[token removeFromSuperview];
		[_tokens removeObject:token];
        [self layoutTokensAnimated:YES];

		if ([delegate respondsToSelector:@selector(tokenField:didRemoveToken:)]){
			[delegate tokenField:self didRemoveToken:token];
		}
		
		[self showOrHidePlaceHolderLabel];
		[self setResultsModeEnabled:_forcePickSearchResult || _alwaysShowSearchResult];
	}
}

- (void)removeAllTokens {
	
	[_tokens enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop) {
		[self removeToken:token];
	}];
	
    [self setText:@""];
}

- (void)selectToken:(TIToken *)token {
	
	[self deselectSelectedToken];
	
	_selectedToken = token;
	[_selectedToken setSelected:YES];
	
	[self becomeFirstResponder];
	[self setText:kTextHidden];
}

- (void)deselectSelectedToken {
	
	[_selectedToken setSelected:NO];
	_selectedToken = nil;
	
	[self setText:kTextEmpty];
}

- (void)tokenizeText {
	
	__block BOOL textChanged = NO;
	
	if (![self.text isEqualToString:kTextEmpty] && ![self.text isEqualToString:kTextHidden] && !_forcePickSearchResult){
		[[self.text componentsSeparatedByCharactersInSet:_tokenizingCharacters] enumerateObjectsUsingBlock:^(NSString * component, NSUInteger idx, BOOL *stop){
			[self addTokenWithTitle:[component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
			textChanged = YES;
		}];
	}
	
	if (textChanged) [self sendActionsForControlEvents:UIControlEventEditingChanged];
}

- (void)tokenTouchDown:(TIToken *)token {
	
	if (_selectedToken != token){
		[_selectedToken setSelected:NO];
		_selectedToken = nil;
	}
}

- (void)tokenTouchUpInside:(TIToken *)token {
	if (_editable) [self selectToken:token];
}

- (CGFloat)layoutTokensInternal {
	
	CGFloat topMargin = floor(self.font.lineHeight * 4 / 7);
	CGFloat leftMargin = self.leftViewWidth + 18;
	CGFloat hPadding = 16;
	CGFloat rightMargin = self.rightViewWidth + hPadding;
	CGFloat lineHeight = ceilf(self.font.lineHeight) + topMargin + 5;
	
	_numberOfLines = 1;
	_tokenCaret = (CGPoint){leftMargin, (topMargin - 1)};
	
	[_tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop){
		
		[token setFont:self.font];
		[token setMaxWidth:(self.bounds.size.width - rightMargin - (_numberOfLines > 1 ? hPadding : leftMargin))];
		
		if (token.superview){
			
			if (_tokenCaret.x + token.bounds.size.width + rightMargin > self.bounds.size.width){
				_numberOfLines++;
				_tokenCaret.x = (_numberOfLines > 1 ? hPadding : leftMargin);
				_tokenCaret.y += lineHeight;
			}
			
			[token setFrame:(CGRect){_tokenCaret, token.bounds.size}];
			_tokenCaret.x += token.bounds.size.width + 4;
			
			if (self.bounds.size.width - _tokenCaret.x - rightMargin < 50){
				_numberOfLines++;
				_tokenCaret.x = (_numberOfLines > 1 ? hPadding : leftMargin);
				_tokenCaret.y += lineHeight;
			}
		}
	}];
//    NSLog(@"_tokenCaret.x = %f, _tokenCaret.y = %f", _tokenCaret.x, _tokenCaret.y);
	
	return ceilf(_tokenCaret.y + lineHeight);
}

#pragma mark View Handlers
- (void)layoutTokensAnimated:(BOOL)animated {
	
	CGFloat newHeight = [self layoutTokensInternal];
	if (self.bounds.size.height != newHeight){
		
		// Animating this seems to invoke the triple-tap-delete-key-loop-problem-thing™
		[UIView animateWithDuration:(animated ? 0.3 : 0) animations:^{
			[self setFrame:((CGRect){self.frame.origin, {self.bounds.size.width, newHeight}})];
			[self sendActionsForControlEvents:(UIControlEvents)TITokenFieldControlEventFrameWillChange];
			
		} completion:^(BOOL complete){
            if (complete) {
                [self sendActionsForControlEvents:(UIControlEvents)TITokenFieldControlEventFrameDidChange];
            }
            
		}];
	}
}

- (void)setResultsModeEnabled:(BOOL)flag {
	[self setResultsModeEnabled:flag animated:YES];
}

- (void)setResultsModeEnabled:(BOOL)flag animated:(BOOL)animated {
	
	[self layoutTokensAnimated:animated];
	
	if (_resultsModeEnabled != flag){
		
		//Hide / show the shadow
		[self.layer setMasksToBounds:!flag];
		
		UIScrollView * scrollView = self.scrollView;
		[scrollView setScrollsToTop:!flag];
		[scrollView setScrollEnabled:!flag];
		
		CGFloat offset = ((_numberOfLines == 1 || !flag) ? 0 : _tokenCaret.y - floor(self.font.lineHeight * 4 / 7) + 1);
		[scrollView setContentOffset:CGPointMake(0, self.frame.origin.y + offset) animated:animated];
        
	}
	
	_resultsModeEnabled = flag;
}

#pragma mark Left / Right view stuff
- (void)setPromptText:(NSString *)text {
	
	if (text){
		
		UILabel * label = (UILabel *)self.leftView;
		if (!label || ![label isKindOfClass:[UILabel class]]){
			label = [[UILabel alloc] initWithFrame:CGRectZero];
			[label setTextColor:[UIColor colorWithWhite:0.5 alpha:1]];
			[self setLeftView:label];

			[self setLeftViewMode:UITextFieldViewModeAlways];
		}
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 2, 16, 16)];
        imageView.image = [UIImage imageNamed:@"tag-1"];
        imageView.contentMode = UIViewContentModeCenter;
        [label addSubview:imageView];
        
		[label setText:text];
		[label setFont:[UIFont systemFontOfSize:(self.font.pointSize + 1)]];
		[label sizeToFit];
	}
	else
	{
		[self setLeftView:nil];
	}
	
	[self layoutTokensAnimated:YES];
}

- (void)setPlaceholder:(NSString *)placeholder {
	
	if (placeholder){
        
        UILabel * label =  _placeHolderLabel;
		if (!label || ![label isKindOfClass:[UILabel class]]){
			label = [[UILabel alloc] initWithFrame:CGRectMake(_tokenCaret.x + 3, _tokenCaret.y + 2, self.rightView.bounds.size.width, self.rightView.bounds.size.height)];
            [label setTextColor:[UIColor colorWithRed:0x99/255.0 green:0x99/255.0 blue:0x99/255.0 alpha:1]]; // colorWithWhite:0.75 alpha:1]];
			 _placeHolderLabel = label;
            [self addSubview: _placeHolderLabel];
		}
		
		[label setText:placeholder];
		[label setFont:[UIFont systemFontOfSize:(self.font.pointSize + 1)]];
		[label sizeToFit];
	}
	else
	{
		[_placeHolderLabel removeFromSuperview];
		_placeHolderLabel = nil;
	}
    
    [self layoutTokensAnimated:YES];
}

#pragma mark Layout
- (CGRect)textRectForBounds:(CGRect)bounds {
	
	if ([self.text isEqualToString:kTextHidden]) return CGRectMake(0, -20, 0, 0);
	
	CGRect frame = CGRectOffset(bounds, _tokenCaret.x + 2, _tokenCaret.y + 3);
	frame.size.width -= (_tokenCaret.x + self.rightViewWidth + 10);
	
	return frame;
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
	return [self textRectForBounds:bounds];
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds {
	return [self textRectForBounds:bounds];
}

- (CGRect)leftViewRectForBounds:(CGRect)bounds {
	return ((CGRect){{8, ceilf(self.font.lineHeight * 4 / 7)}, self.leftView.bounds.size});
}

- (CGRect)rightViewRectForBounds:(CGRect)bounds {
	return ((CGRect){{bounds.size.width - self.rightView.bounds.size.width - 6,
		bounds.size.height - self.rightView.bounds.size.height - 6}, self.rightView.bounds.size});
}

- (CGFloat)leftViewWidth {
	
	if (self.leftViewMode == UITextFieldViewModeNever ||
		(self.leftViewMode == UITextFieldViewModeUnlessEditing && self.editing) ||
		(self.leftViewMode == UITextFieldViewModeWhileEditing && !self.editing)) return 0;
	
	return self.leftView.bounds.size.width;
}

- (CGFloat)rightViewWidth {
	
	if (self.rightViewMode == UITextFieldViewModeNever ||
		(self.rightViewMode == UITextFieldViewModeUnlessEditing && self.editing) ||
		(self.rightViewMode == UITextFieldViewModeWhileEditing && !self.editing)) return 0;
	
	return self.rightView.bounds.size.width;
}

#pragma mark Other
- (NSString *)description {
	return [NSString stringWithFormat:@"<TITokenField %p; prompt = \"%@\">", self, ((UILabel *)self.leftView).text];
}

- (void)dealloc {
	[self setDelegate:nil];
}

@end

//==========================================================
#pragma mark - TITokenFieldInternalDelegate -
//==========================================================
@implementation TITokenFieldInternalDelegate
@synthesize delegate = _delegate;
@synthesize tokenField = _tokenField;

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	
	if ([_delegate respondsToSelector:@selector(textFieldShouldBeginEditing:)]){
		return [_delegate textFieldShouldBeginEditing:textField];
	}
	
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	
	if ([_delegate respondsToSelector:@selector(textFieldDidBeginEditing:)]){
		[_delegate textFieldDidBeginEditing:textField];
	}
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	
	if ([_delegate respondsToSelector:@selector(textFieldShouldEndEditing:)]){
		return [_delegate textFieldShouldEndEditing:textField];
	}
	
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	
	if ([_delegate respondsToSelector:@selector(textFieldDidEndEditing:)]){
		[_delegate textFieldDidEndEditing:textField];
	}
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	
	if (_tokenField.tokens.count && [string isEqualToString:@""] && [_tokenField.text isEqualToString:kTextEmpty]){
		[_tokenField selectToken:[_tokenField.tokens lastObject]];
		return NO;
	}
	
	if ([textField.text isEqualToString:kTextHidden]){
		[_tokenField removeToken:_tokenField.selectedToken];
		return (![string isEqualToString:@""]);
	}
	
	if ([string rangeOfCharacterFromSet:_tokenField.tokenizingCharacters].location != NSNotFound && !_tokenField.forcePickSearchResult){
		[_tokenField tokenizeText];
		return NO;
	}
	
	if ([_delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]){
		return [_delegate textField:textField shouldChangeCharactersInRange:range replacementString:string];
	}
    
    if (_tokenField.tokenLimit!=-1 &&
        [_tokenField.tokens count] >= _tokenField.tokenLimit) {
        return NO;
    }
	
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	
	[_tokenField tokenizeText];
	
	if ([_delegate respondsToSelector:@selector(textFieldShouldReturn:)]){
		return [_delegate textFieldShouldReturn:textField];
	}
	
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
	
	if ([_delegate respondsToSelector:@selector(textFieldShouldClear:)]){
		return [_delegate textFieldShouldClear:textField];
	}
	
	return YES;
}

@end


//==========================================================
#pragma mark - TIToken -
//==========================================================

CGFloat const hTextPadding = 14;
CGFloat const vTextPadding = 8;
CGFloat const kDisclosureThickness = 2.5;
NSLineBreakMode const kLineBreakMode = NSLineBreakByTruncatingTail;

@implementation TIToken

@synthesize title = _title;
@synthesize representedObject = _representedObject;
@synthesize font = _font;
@synthesize tintColor = _tintColor;
@synthesize textColor = _textColor;
@synthesize highlightedTextColor = _highlightedTextColor;
@synthesize accessoryType = _accessoryType;
@synthesize maxWidth = _maxWidth;
@synthesize boardColor = _boardColor;

#pragma mark Init
- (instancetype)initWithTitle:(NSString *)aTitle {
	return [self initWithTitle:aTitle representedObject:nil];
}

- (instancetype)initWithTitle:(NSString *)aTitle representedObject:(id)object {
	return [self initWithTitle:aTitle representedObject:object font:[UIFont systemFontOfSize:14]];
}

- (instancetype)initWithTitle:(NSString *)aTitle representedObject:(id)object font:(UIFont *)aFont {
	
	if ((self = [super init])){
		
		_title = [aTitle copy];
		_representedObject = object;
        
		_font = aFont;
        _tintColor = [[UIColor alloc] initWithRed:0xe6/255.0 green:0xe6/255.0 blue:0xe6/255.0 alpha:1.0];
        _textColor = [[UIColor alloc] initWithRed:0x99/255.0 green:0x99/255.0 blue:0x99/255.0 alpha:1.0];
		_highlightedTextColor = [UIColor whiteColor];
		
		_accessoryType = TITokenAccessoryTypeNone;
		_maxWidth = 200;
        _boardColor = [[UIColor alloc] initWithRed:0xe6/255.0 green:0xe6/255.0 blue:0xe6/255.0 alpha:1.0];
        self.boardWidth = 0.5f;
		
		[self setBackgroundColor:[UIColor clearColor]];
		[self sizeToFit];
	}
	
	return self;
}

#pragma mark Property Overrides
- (void)setHighlighted:(BOOL)flag {
	
	if (self.highlighted != flag){
		[super setHighlighted:flag];
		[self setNeedsDisplay];
	}
}

- (void)setSelected:(BOOL)flag {
	
	if (self.selected != flag){
		[super setSelected:flag];
		[self setNeedsDisplay];
	}
}

- (void)setTitle:(NSString *)newTitle {
	
	if (newTitle){
		_title = [newTitle copy];
		[self sizeToFit];
        [self setNeedsDisplay];
	}
}

- (void)setFont:(UIFont *)newFont {
	
	if (!newFont) newFont = [UIFont systemFontOfSize:14];
	
	if (_font != newFont){
		_font = newFont;
		[self sizeToFit];
        [self setNeedsDisplay];
	}
}

- (void)setTintColor:(UIColor *)newTintColor {
	
	if (!newTintColor) newTintColor = [TIToken blueTintColor];
	
	if (_tintColor != newTintColor){
		_tintColor = newTintColor;
		[self setNeedsDisplay];
	}
}

- (void)setAccessoryType:(TITokenAccessoryType)type {
	
	if (_accessoryType != type){
		_accessoryType = type;
		[self sizeToFit];
        [self setNeedsDisplay];
	}
}

- (void)setMaxWidth:(CGFloat)width {
	
	if (_maxWidth != width){
		_maxWidth = width;
		[self sizeToFit];
        [self setNeedsDisplay];
	}
}

#pragma Tint Color Convenience

+ (UIColor *)blueTintColor {
	return [UIColor colorWithRed:0.216 green:0.373 blue:0.965 alpha:1];
}

+ (UIColor *)redTintColor {
	return [UIColor colorWithRed:1 green:0.15 blue:0.15 alpha:1];
}

+ (UIColor *)greenTintColor {
	return [UIColor colorWithRed:0.333 green:0.741 blue:0.235 alpha:1];
}

#pragma mark Layout
- (CGSize)sizeThatFits:(CGSize)size {
    
    NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    textStyle.lineBreakMode = NSLineBreakByTruncatingTail;
//    textStyle.lineHeightMultiple = 40.0;
//    textStyle.maximumLineHeight = 40.0;
//    textStyle.minimumLineHeight = 40.0;
    CGSize titleSize = [_title boundingRectWithSize:CGSizeMake(_maxWidth - hTextPadding, MAXFLOAT)
                                     options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                         attributes:@{NSFontAttributeName: _font, NSParagraphStyleAttributeName: textStyle}
                                     context:nil].size;
	CGFloat height = floorf(titleSize.height + vTextPadding);
	
    return (CGSize){MAX(floorf(titleSize.width + hTextPadding), height - 3), height};
}

#pragma mark Drawing
- (void)drawRect:(CGRect)rect {
    
    // vPadding: 上下边填充距离
	
	CGContextRef context = UIGraphicsGetCurrentContext();

	BOOL drawHighlighted = (self.selected || self.highlighted);
    
    UIBezierPath *rectanglePath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius: 4.0];
    UIColor *backgroundColor;
    
    if (drawHighlighted) {
        backgroundColor = _tintColor;
    } else {
        backgroundColor = [UIColor whiteColor];
    }
    
    [backgroundColor setFill];
    [rectanglePath fill];
	
    NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    textStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    CGSize titleSize = [_title boundingRectWithSize:CGSizeMake(_maxWidth - hTextPadding, MAXFLOAT)
                                            options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                         attributes:@{NSFontAttributeName: _font, NSParagraphStyleAttributeName: textStyle}
                                            context:nil].size;
	CGFloat vPadding = floor((self.bounds.size.height - titleSize.height) / 2);
	CGFloat titleWidth = ceilf(self.bounds.size.width - hTextPadding);
	CGRect textBounds = CGRectMake(floorf(hTextPadding / 2), vPadding, titleWidth + 5, floorf(self.bounds.size.height - (vPadding * 2)));
	
	CGContextSetFillColorWithColor(context, (drawHighlighted ? _highlightedTextColor : _textColor).CGColor);
    UIColor *_fontColor = [[UIColor alloc] initWithRed:0x99/255.0 green:0x99/255.0 blue:0x99/255.0 alpha:1];

    [_title drawInRect:textBounds withAttributes:@{NSParagraphStyleAttributeName: textStyle, NSForegroundColorAttributeName: _fontColor, NSFontAttributeName: _font}];
    
    [_boardColor setStroke];
    rectanglePath.lineWidth = self.boardWidth;
    [rectanglePath stroke];

}

#pragma mark Other
- (NSString *)description {
	return [NSString stringWithFormat:@"<TIToken %p; title = \"%@\"; representedObject = \"%@\">", self, _title, _representedObject];
}


@end
