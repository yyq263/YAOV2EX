//
//  SlideMenuBar.swift
//  YAOV2EX
//
//  Created by Yiqin Yao on 29/11/2016.
//  Copyright © 2016 Yiqin Yao. All rights reserved.
//

import UIKit

class MenuItemView: UIView {
    // MARK: - Menu item view
    
    var titleLabel : UILabel?
    var menuItemSeparator : UIView?
    
     func setUpMenuItemView(menuItemWidth: CGFloat,
                            menuScrollViewHeight: CGFloat,
                            indicatorHeight: CGFloat,
                            separatorPercentageHeight: CGFloat,
                            separatorWidth: CGFloat,
                            separatorRoundEdges: Bool,
                            menuItemSeparatorColor: UIColor) {
        
        titleLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: menuItemWidth, height: menuScrollViewHeight - indicatorHeight)) // Create title label
        
        menuItemSeparator = UIView(frame: CGRect(x: menuItemWidth - (separatorWidth / 2),
                                                 y: floor(menuScrollViewHeight * (1.0 - separatorPercentageHeight) / 2.0),
                                                 width: separatorWidth,
                                                 height: floor(menuScrollViewHeight * separatorPercentageHeight)))
        
        menuItemSeparator!.backgroundColor = menuItemSeparatorColor
        
        if separatorRoundEdges {
            menuItemSeparator!.layer.cornerRadius = menuItemSeparator!.frame.width / 2
        }
        
        menuItemSeparator!.isHidden = true
        
        self.addSubview(menuItemSeparator!)
        self.addSubview(titleLabel!)
    }
    
    func setTitleText(text: String) {
        if let title = titleLabel {
            title.text = text
            title.numberOfLines = 0
            title.sizeToFit()
        }
    }
}

public enum CAPSPageMenuOption {
    case SelectionIndicatorHeight(CGFloat)
    case MenuItemSeparatorWidth(CGFloat)
    case ScrollMenuBackgroundColor(UIColor)
    case ViewBackgroundColor(UIColor)
    case BottomMenuHairlineColor(UIColor)
    case SelectionIndicatorColor(UIColor)
    case MenuItemSeparatorColor(UIColor)
    case MenuMargin(CGFloat)
    case MenuItemMargin(CGFloat)
    case MenuHeight(CGFloat)
    case SelectedMenuItemLabelColor(UIColor)
    case UnselectedMenuItemLabelColor(UIColor)
    case UseMenuLikeSegmentedControl(Bool)
    case MenuItemSeparatorRoundEdges(Bool)
    case MenuItemFont(UIFont)
    case MenuItemSeparatorPercentageHeight(CGFloat)
    case MenuItemWidth(CGFloat)
    case EnableHorizontalBounce(Bool)
    case AddBottomMenuHairline(Bool)
    case MenuItemWidthBasedOnTitleTextWidth(Bool)
    case TitleTextSizeBasedOnMenuItemWidth(Bool)
    case ScrollAnimationDurationOnMenuItemTap(Int)
    case CenterMenuItems(Bool)
    case HideTopMenuBar(Bool)
}

public class CAPSPageMenu: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    // MARK: - Properties
    
    
    let menuScrollView = UIScrollView()
    let controllerScrollView = UIScrollView()
    var controllerArray: [UIViewController] = []
    var menuItems: [MenuItemView] = []
    var menuItemWidths: [CGFloat] = []
    
    public var menuHeight: CGFloat = 34.0
    public var menuMargin: CGFloat = 15.0
    public var menuItemWidth: CGFloat = 111.0
    public var selectionIndicatorHeight: CGFloat = 3.0
    var totalMenuItemWidthIfDifferentWidths: CGFloat = 0.0
    public var scrollAnimationDurationOnMenuItemTap: Int = 500 // Milliseconds
    var startingMenuMargin : CGFloat = 0.0
    var menuItemMargin: CGFloat = 0.0
    
    var selectionIndicatorView: UIView = UIView()
    
    var currentPageIndex: Int = 0
    var lastPageIndex: Int = 0
    
    public var selectionIndicatorColor : UIColor = UIColor.white
    public var selectedMenuItemLabelColor : UIColor = UIColor.white
    public var unselectedMenuItemLabelColor : UIColor = UIColor.lightGray
    public var scrollMenuBackgroundColor : UIColor = UIColor.black
    public var viewBackgroundColor : UIColor = UIColor.white
    public var bottomMenuHairlineColor : UIColor = UIColor.white
    public var menuItemSeparatorColor : UIColor = UIColor.lightGray
    
    public var menuItemFont : UIFont = UIFont.systemFont(ofSize: 15.0)
    public var menuItemSeparatorPercentageHeight : CGFloat = 0.2
    public var menuItemSeparatorWidth : CGFloat = 0.5
    public var menuItemSeparatorRoundEdges : Bool = false
    
    public var addBottomMenuHairline : Bool = true
    public var menuItemWidthBasedOnTitleTextWidth : Bool = false
    public var titleTextSizeBasedOnMenuItemWidth : Bool = false
    public var useMenuLikeSegmentedControl : Bool = false
    public var centerMenuItems : Bool = false
    public var enableHorizontalBounce : Bool = true
    public var hideTopMenuBar : Bool = false
    
    var currentOrientationIsPortrait : Bool = true
    var pageIndexForOrientationChange : Int = 0
    var didLayoutSubviewsAfterRotation : Bool = false
    var didScrollAlready : Bool = false
    
    var lastControllerScrollViewContentOffset: CGFloat = 0.0
    
    var lastScrollDirection : CAPSPageMenuScrollDirection = .Other
    var startingPageForScroll : Int = 0
    var didTapMenuItemToScroll : Bool = false
    
    var pagesAddedDictionary : [Int : Int] = [:]
    
    public weak var delegate : CAPSPageMenuDelegate?
    
    var tapTimer : Timer?
    
    enum CAPSPageMenuScrollDirection : Int {
        case Left
        case Right
        case Other
    }
    
    // MARK: - View life cycle
    
    /**
     Initialize PageMenu with view controllers
     
     :param: viewControllers List of view controllers that must be subclasses of UIViewController
     :param: frame Frame for page menu view
     :param: options Dictionary holding any customization options user might want to set
     */
    public init(viewControllers: [UIViewController], frame: CGRect, options: [String: AnyObject]?) {
        super.init(nibName: nil, bundle: nil)
        
        controllerArray = viewControllers
        
        self.view.frame = frame
    }
    
    public convenience init(viewControllers: [UIViewController], frame: CGRect, pageMenuOptions: [CAPSPageMenuOption]?) {
        self.init(viewControllers: viewControllers, frame: frame, option: nil)
        
        if let options = pageMenuOptions {
            for option in options {
                switch (option) {
                case let .SelectionIndicatorHeight(value):
                    selectionIndicatorHeight = value
                case let .MenuItemSeparatorWidth(value):
                    menuItemSeparatorWidth = value
                case let .ScrollMenuBackgroundColor(value):
                    scrollMenuBackgroundColor = value
                case let .ViewBackgroundColor(value):
                    viewBackgroundColor = value
                case let .BottomMenuHairlineColor(value):
                    bottomMenuHairlineColor = value
                case let .SelectionIndicatorColor(value):
                    selectionIndicatorColor = value
                case let .MenuItemSeparatorColor(value):
                    menuItemSeparatorColor = value
                case let .MenuMargin(value):
                    menuMargin = value
                case let .MenuItemMargin(value):
                    menuItemMargin = value
                case let .MenuHeight(value):
                    menuHeight = value
                case let .SelectedMenuItemLabelColor(value):
                    selectedMenuItemLabelColor = value
                case let .UnselectedMenuItemLabelColor(value):
                    unselectedMenuItemLabelColor = value
                case let .UseMenuLikeSegmentedControl(value):
                    useMenuLikeSegmentedControl = value
                case let .MenuItemSeparatorRoundEdges(value):
                    menuItemSeparatorRoundEdges = value
                case let .MenuItemFont(value):
                    menuItemFont = value
                case let .MenuItemSeparatorPercentageHeight(value):
                    menuItemSeparatorPercentageHeight = value
                case let .MenuItemWidth(value):
                    menuItemWidth = value
                case let .EnableHorizontalBounce(value):
                    enableHorizontalBounce = value
                case let .AddBottomMenuHairline(value):
                    addBottomMenuHairline = value
                case let .MenuItemWidthBasedOnTitleTextWidth(value):
                    menuItemWidthBasedOnTitleTextWidth = value
                case let .TitleTextSizeBasedOnMenuItemWidth(value):
                    titleTextSizeBasedOnMenuItemWidth = value
                case let .ScrollAnimationDurationOnMenuItemTap(value):
                    scrollAnimationDurationOnMenuItemTap = value
                case let .CenterMenuItems(value):
                    centerMenuItems = value
                case let .HideTopMenuBar(value):
                    hideTopMenuBar = value
                }
            }
            
            if hideTopMenuBar {
                addBottomMenuHairline = false
                menuHeight = 0.0
            }
        }
        
        setUpUserInterface()
        
        if menuScrollView.subviews.count == 0 {
            configureUserInterface()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Container View Controller
    //public override func shouldAutomaticallyForwardAppearanceMethods() -> Bool {
     //   return true
    //}
    
    //public override func shouldAutomaticallyForwardRotationMethods() -> Bool {
    //    return true
    //}
    
    // MARK: - UI Setup
    func setUpUserInterface() {
        let viewsDictionary = ["menuScrollView":menuScrollView, "controllerScrollView":controllerScrollView]
        
        // Set up controller scroll view
        controllerScrollView.isPagingEnabled = true
        controllerScrollView.translatesAutoresizingMaskIntoConstraints = false
        controllerScrollView.alwaysBounceHorizontal = enableHorizontalBounce
        controllerScrollView.bounces = enableHorizontalBounce
        
        controllerScrollView.frame = CGRect(x: 0.0, y: menuHeight, width: self.view.frame.width, height: self.view.frame.height)
            
        self.view.addSubview(controllerScrollView)
        
        let controllerScrollView_constraint_H:Array = NSLayoutConstraint.constraints(withVisualFormat: "H:|[controllerScrollView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        let controllerScrollView_constraint_V:Array = NSLayoutConstraint.constraints(withVisualFormat: "V:|[controllerScrollView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        
        self.view.addConstraints(controllerScrollView_constraint_H)
        self.view.addConstraints(controllerScrollView_constraint_V)
        
        // Set up menu scroll view
        menuScrollView.translatesAutoresizingMaskIntoConstraints = false
        
        menuScrollView.frame = CGRect(x: 0.0, y: 0.0, width: self.view.frame.width, height: menuHeight)
        
        self.view.addSubview(menuScrollView)
        
        let menuScrollView_constraint_H:Array = NSLayoutConstraint.constraints(withVisualFormat: "H:|[menuScrollView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        let menuScrollView_constraint_V:Array = NSLayoutConstraint.constraints(withVisualFormat: "V:[menuScrollView(\(menuHeight))]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        
        self.view.addConstraints(menuScrollView_constraint_H)
        self.view.addConstraints(menuScrollView_constraint_V)
        
        // Add hairline to menu scroll view
        if addBottomMenuHairline {
            let menuBottomHairline : UIView = UIView()
            
            menuBottomHairline.translatesAutoresizingMaskIntoConstraints = false
            
            self.view.addSubview(menuBottomHairline)
            
            let menuBottomHairline_constraint_H:Array = NSLayoutConstraint.constraints(withVisualFormat: "H:|[menuBottomHairline]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["menuBottomHairline":menuBottomHairline])
            let menuBottomHairline_constraint_V:Array = NSLayoutConstraint.constraints(withVisualFormat: "V:|-\(menuHeight)-[menuBottomHairline(0.5)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["menuBottomHairline":menuBottomHairline])
            
            self.view.addConstraints(menuBottomHairline_constraint_H)
            self.view.addConstraints(menuBottomHairline_constraint_V)
            
            menuBottomHairline.backgroundColor = bottomMenuHairlineColor
        }
        
        // Disable scroll bars
        menuScrollView.showsHorizontalScrollIndicator = false
        menuScrollView.showsVerticalScrollIndicator = false
        controllerScrollView.showsHorizontalScrollIndicator = false
        controllerScrollView.showsVerticalScrollIndicator = false
        
        // Set background color behind scroll views and for menu scroll view
        self.view.backgroundColor = viewBackgroundColor
        menuScrollView.backgroundColor = scrollMenuBackgroundColor
    }
    
    func configureUserInterface() {
        // Add tap gesture recognizer to controller scroll view to recognize menu item selection
        let menuItemTapGestureRecognizer = UITapGestureRecognizer(target: self, action: Selector("handleMenuItemTap:"))
        menuItemTapGestureRecognizer.numberOfTapsRequired = 1
        menuItemTapGestureRecognizer.numberOfTouchesRequired = 1
        menuItemTapGestureRecognizer.delegate = self
        menuScrollView.addGestureRecognizer(menuItemTapGestureRecognizer)
        
        // Set delegate for controller scroll view
        controllerScrollView.delegate = self
        
        // When the user taps the status bar, the scroll view beneath the touch which is closest to the status bar will be scrolled to top,
        // but only if its `scrollsToTop` property is YES, its delegate does not return NO from `shouldScrollViewScrollToTop`, and it is not already at the top.
        // If more than one scroll view is found, none will be scrolled.
        // Disable scrollsToTop for menu and controller scroll views so that iOS finds scroll views within our pages on status bar tap gesture.
        menuScrollView.scrollsToTop = false;
        controllerScrollView.scrollsToTop = false;
        
        // Configure menu scroll view
        if useMenuLikeSegmentedControl {
            menuScrollView.isScrollEnabled = false
            menuScrollView.contentSize = CGSize(width: self.view.frame.width, height: menuHeight)
            menuMargin = 0.0
        } else {
            menuScrollView.contentSize = CGSize(width: (menuItemWidth + menuMargin) * CGFloat(controllerArray.count) + menuMargin, height: menuHeight)
        }
        
        // Configure controller scroll view content size
        controllerScrollView.contentSize = CGSize(width: self.view.frame.width * CGFloat(controllerArray.count), height: 0.0)//CGSizeMake(self.view.frame.width * CGFloat(controllerArray.count), 0.0)
        
        var index : CGFloat = 0.0
        
        for controller in controllerArray {
            if index == 0.0 {
                // Add first two controllers to scrollview and as child view controller
                addPageAtIndex(0)
            }
            
            // Set up menu item for menu scroll view
            var menuItemFrame : CGRect = CGRect()
            
            if useMenuLikeSegmentedControl {
                //**************************拡張*************************************
                if menuItemMargin > 0 {
                    let marginSum = menuItemMargin * CGFloat(controllerArray.count + 1)
                    let menuItemWidth = (self.view.frame.width - marginSum) / CGFloat(controllerArray.count)
                    menuItemFrame = CGRect(x: CGFloat(menuItemMargin * (index + 1)) + menuItemWidth * CGFloat(index), y: 0.0, width: CGFloat(self.view.frame.width) / CGFloat(controllerArray.count), height: menuHeight)
                } else {
                    menuItemFrame = CGRect(x: self.view.frame.width / CGFloat(controllerArray.count) * CGFloat(index), y: 0.0, width: CGFloat(self.view.frame.width) / CGFloat(controllerArray.count), height: menuHeight)
                }
                //**************************拡張ここまで*************************************
            } else if menuItemWidthBasedOnTitleTextWidth {
                let controllerTitle : String? = controller.title
                
                let titleText : String = controllerTitle != nil ? controllerTitle! : "Menu \(Int(index) + 1)"
                
                let itemWidthRect : CGRect = (titleText as NSString).boundingRect(with: CGSize(width: 1000, height: 1000), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName: menuItemFont], context: nil)
                
                menuItemWidth = itemWidthRect.width
                
                menuItemFrame = CGRect(x: totalMenuItemWidthIfDifferentWidths + menuMargin + menuMargin * index, y: 0.0, width: menuItemWidth, height: menuHeight)
                
                totalMenuItemWidthIfDifferentWidths += itemWidthRect.width
                menuItemWidths.append(itemWidthRect.width)
            } else {
                if centerMenuItems && index == 0.0  {
                    startingMenuMargin = ((self.view.frame.width - ((CGFloat(controllerArray.count) * menuItemWidth) + (CGFloat(controllerArray.count - 1) * menuMargin))) / 2.0) -  menuMargin
                    
                    if startingMenuMargin < 0.0 {
                        startingMenuMargin = 0.0
                    }
                    
                    menuItemFrame = CGRect(x: startingMenuMargin + menuMargin, y: 0.0, width: menuItemWidth, height: menuHeight)
                } else {
                    menuItemFrame = CGRect(x: menuItemWidth * index + menuMargin * (index + 1) + startingMenuMargin, y: 0.0, width: menuItemWidth, height: menuHeight)
                }
            }
            
            let menuItemView : MenuItemView = MenuItemView(frame: menuItemFrame) // Initialize menu item view with the calculated frame
            if useMenuLikeSegmentedControl {
                //**************************拡張*************************************
                if menuItemMargin > 0 {
                    let marginSum = menuItemMargin * CGFloat(controllerArray.count + 1)
                    let menuItemWidth = (self.view.frame.width - marginSum) / CGFloat(controllerArray.count)
                    menuItemView.setUpMenuItemView(menuItemWidth: menuItemWidth,
                                                   menuScrollViewHeight: menuHeight,
                                                   indicatorHeight: selectionIndicatorHeight,
                                                   separatorPercentageHeight: menuItemSeparatorPercentageHeight,
                                                   separatorWidth: menuItemSeparatorWidth,
                                                   separatorRoundEdges: menuItemSeparatorRoundEdges,
                                                   menuItemSeparatorColor: menuItemSeparatorColor)
                } else {
                    // Set up separator view and item title label
                    menuItemView.setUpMenuItemView(menuItemWidth: CGFloat(self.view.frame.width) / CGFloat(controllerArray.count),
                                                   menuScrollViewHeight: menuHeight,
                                                   indicatorHeight: selectionIndicatorHeight,
                                                   separatorPercentageHeight: menuItemSeparatorPercentageHeight,
                                                   separatorWidth: menuItemSeparatorWidth,
                                                   separatorRoundEdges: menuItemSeparatorRoundEdges,
                                                   menuItemSeparatorColor: menuItemSeparatorColor)
                }
                //**************************拡張ここまで*************************************
            } else {
                menuItemView.setUpMenuItemView(menuItemWidth: menuItemWidth,
                                               menuScrollViewHeight: menuHeight,
                                               indicatorHeight: selectionIndicatorHeight,
                                               separatorPercentageHeight: menuItemSeparatorPercentageHeight,
                                               separatorWidth: menuItemSeparatorWidth,
                                               separatorRoundEdges: menuItemSeparatorRoundEdges,
                                               menuItemSeparatorColor: menuItemSeparatorColor)
            }
            
            // Configure menu item label font if font is set by user
            menuItemView.titleLabel!.font = menuItemFont
            
            menuItemView.titleLabel!.textAlignment = NSTextAlignment.center
            menuItemView.titleLabel!.textColor = unselectedMenuItemLabelColor
            
            //**************************拡張*************************************
            menuItemView.titleLabel!.adjustsFontSizeToFitWidth = titleTextSizeBasedOnMenuItemWidth
            //**************************拡張ここまで*************************************
            
            // Set title depending on if controller has a title set
            if controller.title != nil {
                menuItemView.titleLabel!.text = controller.title!
            } else {
                menuItemView.titleLabel!.text = "Menu \(Int(index) + 1)"
            }
            
            // Add separator between menu items when using as segmented control
            if useMenuLikeSegmentedControl {
                if Int(index) < controllerArray.count - 1 {
                    menuItemView.menuItemSeparator!.isHidden = false
                }
            }
            
            // Add menu item view to menu scroll view
            menuScrollView.addSubview(menuItemView)
            menuItems.append(menuItemView)
            
            index += 1
        }
        
        // Set new content size for menu scroll view if needed
        if menuItemWidthBasedOnTitleTextWidth {
            menuScrollView.contentSize = CGSize(width: totalMenuItemWidthIfDifferentWidths + menuMargin + CGFloat(controllerArray.count) * menuMargin, height: menuHeight)
        }
        
        // Set selected color for title label of selected menu item
        // Select the first item by default
        if menuItems.count > 0 {
            if menuItems[currentPageIndex].titleLabel != nil {
                menuItems[currentPageIndex].titleLabel!.textColor = selectedMenuItemLabelColor
            }
        }
        
        // Configure selection indicator view
        var selectionIndicatorFrame : CGRect = CGRect()
        
        if useMenuLikeSegmentedControl {
            selectionIndicatorFrame = CGRect(x: 0.0, y: menuHeight - selectionIndicatorHeight, width: self.view.frame.width / CGFloat(controllerArray.count), height: selectionIndicatorHeight)
        } else if menuItemWidthBasedOnTitleTextWidth {
            selectionIndicatorFrame = CGRect(x: menuMargin, y: menuHeight - selectionIndicatorHeight, width: menuItemWidths[0], height: selectionIndicatorHeight)
        } else {
            if centerMenuItems  {
                selectionIndicatorFrame = CGRect(x: startingMenuMargin + menuMargin, y: menuHeight - selectionIndicatorHeight, width: menuItemWidth, height: selectionIndicatorHeight)
            } else {
                selectionIndicatorFrame = CGRect(x: menuMargin, y: menuHeight - selectionIndicatorHeight, width: menuItemWidth, height: selectionIndicatorHeight)
            }
        }
        
        selectionIndicatorView = UIView(frame: selectionIndicatorFrame)
        selectionIndicatorView.backgroundColor = selectionIndicatorColor
        menuScrollView.addSubview(selectionIndicatorView)
        
        if menuItemWidthBasedOnTitleTextWidth && centerMenuItems {
            self.configureMenuItemWidthBasedOnTitleTextWidthAndCenterMenuItems()
            let leadingAndTrailingMargin = self.getMarginForMenuItemWidthBasedOnTitleTextWidthAndCenterMenuItems()
            selectionIndicatorView.frame = CGRect(x: leadingAndTrailingMargin, y: menuHeight - selectionIndicatorHeight, width: menuItemWidths[0], height: selectionIndicatorHeight)
        }
    }
    
    // Adjusts the menu item frames to size item width based on title text width and center all menu items in the center
    // if the menuItems all fit in the width of the view. Otherwise, it will adjust the frames so that the menu items
    // appear as if only menuItemWidthBasedOnTitleTextWidth is true.
    private func configureMenuItemWidthBasedOnTitleTextWidthAndCenterMenuItems() {
        // only center items if the combined width is less than the width of the entire view's bounds
        if menuScrollView.contentSize.width < self.view.bounds.width {
            // compute the margin required to center the menu items
            let leadingAndTrailingMargin = self.getMarginForMenuItemWidthBasedOnTitleTextWidthAndCenterMenuItems()
            
            // adjust the margin of each menu item to make them centered
            for (index, menuItem) in menuItems.enumerated() {
                let controllerTitle = controllerArray[index].title!
                
                let itemWidthRect = controllerTitle.boundingRect(with: CGSizeMake(1000, 1000), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName:menuItemFont], context: nil)
                
                menuItemWidth = itemWidthRect.width
                
                var margin: CGFloat
                if index == 0 {
                    // the first menu item should use the calculated margin
                    margin = leadingAndTrailingMargin
                } else {
                    // the other menu items should use the menuMargin
                    let previousMenuItem = menuItems[index-1]
                    let previousX = CGRectGetMaxX(previousMenuItem.frame)
                    margin = previousX + menuMargin
                }
                
                menuItem.frame = CGRectMake(margin, 0.0, menuItemWidth, menuHeight)
            }
        } else {
            // the menuScrollView.contentSize.width exceeds the view's width, so layout the menu items normally (menuItemWidthBasedOnTitleTextWidth)
            for (index, menuItem) in menuItems.enumerate() {
                var menuItemX: CGFloat
                if index == 0 {
                    menuItemX = menuMargin
                } else {
                    menuItemX = CGRectGetMaxX(menuItems[index-1].frame) + menuMargin
                }
                
                menuItem.frame = CGRectMake(menuItemX, 0.0, CGRectGetWidth(menuItem.bounds), CGRectGetHeight(menuItem.bounds))
            }
        }
    }
    
    // Returns the size of the left and right margins that are neccessary to layout the menuItems in the center.
    private func getMarginForMenuItemWidthBasedOnTitleTextWidthAndCenterMenuItems() -> CGFloat {
        let menuItemsTotalWidth = menuScrollView.contentSize.width - menuMargin * 2
        let leadingAndTrailingMargin = (CGRectGetWidth(self.view.bounds) - menuItemsTotalWidth) / 2
        
        return leadingAndTrailingMargin
    }
    

}
