//
//  DirectoryViewerViewController.swift
//  LimaChallenge
//
//  Created by Paul Ulric on 26/07/2016.
//  Copyright © 2016 Paul Ulric. All rights reserved.
//

import UIKit
import CoreData
import RxSwift
import LGPlusButtonsView


class DirectoryViewerViewController: UITableViewController, ErrorDisplayer, PortraitViewController {
    
    // MARK: - Properties
    var viewModel: DirectoryViewerViewModel!
    
    // Controller handling the search bar
    private let searchController = UISearchController(searchResultsController: nil)
    // "Plus" button to upload media
    private var addButton: LGPlusButtonsView!
    // Placeholder view for the empty state (when the table has no data)
    private var emptyView: UIView!
    // Modal displayed during a file upload
    private var loadingAlert: UIAlertController?
    
    // RxSwift dispose bag
    private var disposeBag = DisposeBag()

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = viewModel.title
        addButton = createAddButton()
        setupSearchBar()
        setupBackgroundEmptyView()
        setupRefreshControl()
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "FileItemCell")
        
        // Reload the table every time the viewModel has fetched content
        viewModel.contentFetched.asObservable().subscribeNext { [unowned self] (Int) in
            self.reloadTable()
        }.addDisposableTo(disposeBag)
        
        loadDirectoryContent()
    }
    
    deinit {
        // When the searchController hasn't been presented (no search has been performed),
        // a warning is shown upon deallocation.
        // To shut it up, we need to remove the searchController's view.
        searchController.view.removeFromSuperview()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.navigationController?.view.addSubview(addButton)
        addButton.observedScrollView = tableView
        addButton.showAnimated(false, completionHandler: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        addButton.removeFromSuperview()
    }
    
    
    // MARK: - UI Setup
    // The table view search bar allowing to search inside a directory
    private func setupSearchBar() {
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.searchBarStyle = UISearchBarStyle.Minimal
        
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        tableView.sectionIndexBackgroundColor = UIColor.clearColor()
        
        // Fix for an iOS bug: a searchBar won't appear properly if the navigation bar isn't translucent
        extendedLayoutIncludesOpaqueBars = true
    }
    
    // An empty state view for directories with no data
    private func setupBackgroundEmptyView() {
        emptyView = createEmptyView()
        tableView.backgroundView = emptyView
        emptyView.widthAnchor.constraintEqualToAnchor(tableView.widthAnchor).active = true
        emptyView.topAnchor.constraintEqualToAnchor(tableView.topAnchor, constant: 60.0).active = true
        emptyView.hidden = true
    }
    
    // The pull to refresh component
    private func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl?.tintColor = Colors.purple
        refreshControl?.addTarget(self, action: #selector(loadDirectoryContent), forControlEvents: .ValueChanged)
    }
    
    //MARK: - Loading Callbacks & Helpers
    func loadDirectoryContent() {
        viewModel.loadContent { (error: NSError?) in
            self.refreshControl?.endRefreshing()
            
            guard error == nil else {
                self.displayError(error!)
                return
            }
            
            // Add a very small delay so the viewModel can reload it's fetchedResultsController
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
                self.didUpdateTableContent()
            }
        }
    }
    
    private func didUpdateTableContent() {
        self.emptyView.hidden = self.viewModel.numberOfSections() > 0
        self.searchController.searchBar.hidden = !self.emptyView.hidden
        self.tableView.separatorStyle = self.emptyView.hidden ? .SingleLine : .None
    }
    
    // Reload the table when content has changed and tell the refresh control to hide
    func reloadTable() {
        tableView.reloadData()
    }
    
}


// MARK: - TableView Source & Delegate
extension DirectoryViewerViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.titleForSection(section)
    }
    
    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return viewModel.sectionForSectionIndexTitle(title, atIndex: index)
    }
    
    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        return viewModel.sectionTitles()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItemsInSection(section)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FileItemCell", forIndexPath: indexPath)
        
        let type = viewModel.fileItemTypeAtIndexPath(indexPath)
        cell.imageView?.image = iconForType(type)
        cell.textLabel?.text = viewModel.titleAtIndexPath(indexPath)
        cell.accessoryType = (type == .directory) ? .DisclosureIndicator : .None
        let alpha: CGFloat = (type == .unset) ? 0.5 : 1.0
        cell.textLabel?.alpha = alpha
        cell.imageView?.alpha = alpha
        
        return cell
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // When a FileItem type hasn't been fetched yet, its cell shouldn't be clickable
        let type = viewModel.fileItemTypeAtIndexPath(indexPath)
        return (type != .unset)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let type = viewModel.fileItemTypeAtIndexPath(indexPath)
        switch type {
        case .directory:
            let directoryViewController = DirectoryViewerViewController()
            let directoryViewModel = viewModel.directoryViewerViewModelForIndexPath(indexPath)
            directoryViewController.viewModel = directoryViewModel
            navigationController?.pushViewController(directoryViewController, animated: true)
        case .unknown, .text, .staticImage, .animatedImage, .audio, .video:
            let mediaViewController = MediaPlayerViewController(nibName: nil, bundle: nil)
            let mediaViewModel = viewModel.mediaPlayerViewModelForIndexPath(indexPath)
            mediaViewController.viewModel = mediaViewModel
            mediaViewController.modalPresentationStyle = .OverFullScreen
            mediaViewController.modalTransitionStyle = .CrossDissolve
            presentViewController(mediaViewController, animated: true, completion: nil)
        default: break
        }
    }
    
    /* Helpers */
    private func iconForType(type: FileItemType) -> UIImage {
        switch type {
        case .unset:
            return UIImage(named: "unset")!
        case .unknown:
            return UIImage(named: "unknown")!
        case .directory:
            return UIImage(named: "directory")!
        case .text:
            return UIImage(named: "text")!
        case .staticImage, .animatedImage:
            return UIImage(named: "image")!
        case .audio:
            return UIImage(named: "audio")!
        case .video:
            return UIImage(named: "video")!
        }
    }
    
}


// MARK: - Search Handler
extension DirectoryViewerViewController: UISearchResultsUpdating {
    
    // Called when the content of the search bar changes
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        viewModel.performSearch(searchController.searchBar.text)
    }
    
}


// MARK: - FileItem Adder
extension DirectoryViewerViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    /* FileItem Creation abilities */
    private func askNewFolderName() {
        displayInputAlert("New folder", message: "Enter a name for the folder") { (name: String) in
            self.viewModel.createDirectory(name, completionHandler: { (error: NSError?) in
                guard error == nil else {
                    self.displayError(error!)
                    return
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.didUpdateTableContent()
                })
            })
        }
    }
    
    private func importImageFromLibrary(fromCamera: Bool) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = fromCamera ? .Camera : .PhotoLibrary
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage
        
        dismissViewControllerAnimated(true) {
            guard pickedImage != nil else { return }
            
            self.displayInputAlert("New image", message: "Enter a name for the image") { (name: String) in
                guard let imageData = UIImageJPEGRepresentation(pickedImage!, 1.0) else { return }
                
                self.startUploading()
                self.viewModel.createImage(name, data: imageData, completionHandler: { (error: NSError?) in
                    dispatch_async(dispatch_get_main_queue(), {
                        guard error == nil else {
                            // self.displayError(error!)
                            self.stopUploading(false)
                            return
                        }
                        
                        self.stopUploading(true)
                        self.didUpdateTableContent()
                    })
                })
            }
        }
    }
    
    /* Helpers */
    // Display a popup allowing user to enter a name
    private func displayInputAlert(title: String, message: String, submitAction: (String) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alert.addAction(cancelAction)
        let submitAction = UIAlertAction(title: "Submit", style: .Default) { (action: UIAlertAction) in
            let nameTextfield = alert.textFields![0] as UITextField
            submitAction(nameTextfield.text!)
        }
        submitAction.enabled = false
        alert.addAction(submitAction)
        alert.addTextFieldWithConfigurationHandler { (textfield: UITextField) in
            textfield.placeholder = "Name"
            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textfield, queue: NSOperationQueue.mainQueue(), usingBlock: { (notification: NSNotification) in
                submitAction.enabled = textfield.text != ""
            })
        }
        presentViewController(alert, animated: true, completion: nil)
    }
    
}


//MARK: - UI Components Creation
extension DirectoryViewerViewController {
    
    /* Components creation steps  (here because verbose) */
    private func createEmptyView() -> UIView {
        let emptyView = UIView()
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.heightAnchor.constraintEqualToConstant(280.0).active = true
        emptyView.backgroundColor = UIColor.clearColor()
        
        let emptyImage = UIImage(named: "empty")
        let emptyImageView = UIImageView(image: emptyImage)
        emptyView.addSubview(emptyImageView)
        emptyImageView.translatesAutoresizingMaskIntoConstraints = false
        emptyImageView.widthAnchor.constraintEqualToConstant(200.0).active = true
        emptyImageView.heightAnchor.constraintEqualToConstant(200.0).active = true
        emptyImageView.topAnchor.constraintEqualToAnchor(emptyView.topAnchor, constant: 10.0).active = true
        emptyImageView.centerXAnchor.constraintEqualToAnchor(emptyView.centerXAnchor).active = true
        
        let emptyLabel = UILabel(frame: emptyView.bounds)
        emptyLabel.textAlignment = .Center
        emptyLabel.text = "Nothing to see here.\nAdd content by tapping the '+' button."
        emptyLabel.numberOfLines = 0
        emptyLabel.lineBreakMode = .ByWordWrapping
        emptyView.addSubview(emptyLabel)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.topAnchor.constraintEqualToAnchor(emptyImageView.bottomAnchor).active = true
        emptyLabel.leadingAnchor.constraintEqualToAnchor(emptyView.leadingAnchor, constant: 20.0).active = true
        emptyLabel.trailingAnchor.constraintEqualToAnchor(emptyView.trailingAnchor, constant: -20.0).active = true
        emptyLabel.bottomAnchor.constraintEqualToAnchor(emptyView.bottomAnchor, constant: -10.0).active = true
        
        return emptyView
    }
    
    private func createAddButton() -> LGPlusButtonsView {
        let button = LGPlusButtonsView(numberOfButtons: 4, firstButtonIsPlusButton: true, showAfterInit: true) { [unowned self] (plusButtonsView: LGPlusButtonsView!, title: String!, description: String!, index: UInt) in
            switch index {
            case 1:
                self.askNewFolderName()
            case 2:
                self.importImageFromLibrary(false)
            case 3:
                self.importImageFromLibrary(true)
            default: break
            }
            if index != 0 {
                plusButtonsView.hideButtonsAnimated(true, completionHandler: nil)
            }
        }
        
        button.coverColor = UIColor(white: 0.0, alpha: 0.5)
        button.position = LGPlusButtonsViewPosition.BottomRight
        button.plusButtonAnimationType = LGPlusButtonAnimationType.Rotate
        button.setButtonsTitles(["+", "", "", ""], forState: UIControlState.Normal)
        button.setDescriptionsTexts(["", "Folder", "Image", "Photo"])
        button.setButtonsImages([NSNull(), UIImage(named: "folder")!, UIImage(named: "picture")!, UIImage(named: "camera")!], forState: .Normal, forOrientation: LGPlusButtonsViewOrientation.All)
        button.setButtonsAdjustsImageWhenHighlighted(false)
        button.setButtonsBackgroundColor(Colors.purple, forState: .Normal)
        button.setButtonsBackgroundColor(Colors.purpleLight, forState: .Highlighted)
        button.setButtonsBackgroundColor(Colors.purpleLight, forState: [.Highlighted, .Selected])
        button.setButtonsSize(CGSize(width: 36.0, height: 36.0), forOrientation: LGPlusButtonsViewOrientation.All)
        button.setButtonsLayerCornerRadius(36.0/2.0, forOrientation: LGPlusButtonsViewOrientation.All)
        button.setButtonsTitleFont(UIFont.boldSystemFontOfSize(18.0), forOrientation: LGPlusButtonsViewOrientation.All)
        button.setButtonsLayerShadowColor(UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0))
        button.setButtonsLayerShadowOpacity(0.5)
        button.setButtonsLayerShadowRadius(3.0)
        button.setButtonsLayerShadowOffset(CGSize(width: 0.0, height: 2.0))
        button.setDescriptionsTextColor(UIColor.whiteColor())
        button.setButtonAtIndex(0, size:CGSize(width: 48.0, height: 48.0), forOrientation: LGPlusButtonsViewOrientation.Portrait)
        button.setButtonAtIndex(0, layerCornerRadius: 48.0/2.0, forOrientation: LGPlusButtonsViewOrientation.Portrait)
        button.setButtonAtIndex(0, titleFont:(UIFont.systemFontOfSize(36.0)), forOrientation: LGPlusButtonsViewOrientation.Portrait)
        button.setButtonAtIndex(0, titleOffset: CGPoint(x: 0.0, y: -3.0), forOrientation: LGPlusButtonsViewOrientation.All)
        button.setButtonAtIndex(0, offset: CGPoint(x: -5, y: -5), forOrientation: LGPlusButtonsViewOrientation.All)
        for i: UInt in 1...3 {
            button.setButtonAtIndex(i, offset:CGPoint(x: -11.0, y: 0.0), forOrientation: LGPlusButtonsViewOrientation.All)
        }
        
        return button
    }
    
    private func createLoadingAlert() -> UIAlertController {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
        return alert
    }
    
    func startUploading() {
        if loadingAlert == nil {
            loadingAlert = createLoadingAlert()
        }
        loadingAlert!.title = "Uploading..."
        presentViewController(loadingAlert!, animated: true, completion: nil)
    }
    
    func stopUploading(success: Bool) {
        guard loadingAlert != nil else { return }
        loadingAlert?.title = success ? "Success" : "Failed"
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
            self.loadingAlert!.dismissViewControllerAnimated(true, completion: nil)
        }
    }

}
