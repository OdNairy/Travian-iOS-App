// This code is distributed under the terms and conditions of the MIT license.

/* * Copyright (C) 2011 - 2013 Matej Kramny <matejkramny@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
 * associated documentation files (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge, publish, distribute,
 * sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial
 * portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
 * NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
 * OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <UIKit/UIKit.h>

#ifndef AppDelegate
	#define DEBUG_APP false
	#define DEBUG_ANIMATION false
#endif

#ifdef DEBUG
	#define APN_URL @"http://apn.sandbox.matej.me/" // used when running the app without the distribution prov. profile
#else
	#define APN_URL @"http://apn.matej.me/" // ad-hoc and app store mode.
#endif

@class TMStorage;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (weak, nonatomic) TMStorage *storage;

@end

@interface AppDelegate (Appearance)

- (void)customizeAppearance;
+ (void)setCellAppearance:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath;
+ (void)setRoundedCellAppearance:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath forLastRow:(bool)lastRow;
+ (UIView *)setDetailAccessoryViewForTarget:(id)target action:(SEL)selector;

@end
