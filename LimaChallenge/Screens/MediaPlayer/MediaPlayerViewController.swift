//
//  MediaPlayerViewController.swift
//  LimaChallenge
//
//  Created by Paul Ulric on 27/07/2016.
//  Copyright © 2016 Paul Ulric. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import FLAnimatedImage
import RxSwift
import RxCocoa


class MediaPlayerViewController: UIViewController, ErrorDisplayer {
    
    // MARK: - Properties
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var activityLoader: UIActivityIndicatorView!
    
    @IBOutlet weak var placeholderView: UIView!
    @IBOutlet weak var placeholderImage: UIImageView!
    @IBOutlet weak var placeholderLabel: UILabel!
    
    var viewModel: MediaPlayerViewModel!
    
    // RxSwift dispose bag
    private var disposeBag = DisposeBag()
    

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        loadMedia()
        
        viewModel.isFavorite.asObservable()
            .map { $0! }
            .bindTo(favoriteButton.rx_selected)
            .addDisposableTo(disposeBag)
    }
    
    
    // MARK: - UI Setup
    private func setupUI() {
        titleLabel.text = viewModel.title
        detailLabel.text = viewModel.readableSize
        
        favoriteButton.enabled = false
        favoriteButton.hidden = !viewModel.dataIsCacheable
    }
    
    
    // MARK: - UI Interactions
    @IBAction func closeButtonTapped(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func favoriteButtonTapped(sender: AnyObject) {
        if !viewModel.toggleFavoriteItem() {
            let action = viewModel.isFavorite.value! ? "unmark" : "mark"
            self.displayError("Unable to \(action) item as favorite")
        }
    }
    
    @IBAction func shareButtonTapped(sender: AnyObject) {
        var items = [viewModel.title]
        if let url = viewModel.mediaURL {
            items.append(url.absoluteString)
        }
        let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        presentViewController(activityController, animated: true, completion: nil)
    }
    
}


// MARK: - Data Loading
extension MediaPlayerViewController {
    
    // For the "usually light" items (text, images), we load all the data first,
    // and then display the file.
    // For the heavier files (audio, video), we stream them directly in a player.
    private func loadMedia() {
        let type = viewModel.modelType
        switch type {
        case .text, .staticImage, .animatedImage:
            activityLoader.startAnimating()
            viewModel.loadContent({ (data: NSData?, error: NSError?) in
                dispatch_async(dispatch_get_main_queue(), {
                    guard error == nil else {
                        self.displayPlaceholder("error", text: "Oops! An error while loading the media.")
                        return
                    }
                    
                    self.favoriteButton.enabled = true
                    self.activityLoader.stopAnimating()
                    self.displayLoadedData(type, data: data!)
                })
            })
        case .audio, .video:
            if let mediaURL = viewModel.mediaURL {
                displayMediaPlayer(mediaURL, isAudio: type == .audio)
            } else {
                displayPlaceholder("error", text: "Oops! An error while loading the media.")
            }
        default:
            displayPlaceholder("unknown_w", text: "Unable to read the file format.")
        }
    }
    
    func displayLoadedData(type: FileItemType, data: NSData) {
        switch type {
        case .text:
            self.displayTextFromData(data)
        case .staticImage:
            self.displayStaticImageViewFromData(data)
        case .animatedImage:
            self.displayAnimatedImageViewFromData(data)
        default: break
        }
    }
    
}


// MARK: - Media Display
extension MediaPlayerViewController {
    
    // Display a text file
    private func displayTextFromData(textData: NSData) {
        guard let text = NSString(data: textData, encoding: NSUTF8StringEncoding) as? String ?? NSString(data: textData, encoding: NSUnicodeStringEncoding) as? String else {
            displayPlaceholder("unknown_w", text: "File content is empty.")
            return
        }
        
        let textView = UITextView()
        textView.backgroundColor = UIColor.clearColor()
        textView.textColor = UIColor.whiteColor()
        textView.text = text
        contentView.addSubview(textView)
        addConstraintsToFillSuperview(textView)
    }
    
    // Display a static image
    private func displayStaticImageViewFromData(imageData: NSData) {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFit
        let image = UIImage(data: imageData)
        imageView.image = image
        contentView.addSubview(imageView)
        addConstraintsToFillSuperview(imageView)
    }
    
    // Display an animated image
    private func displayAnimatedImageViewFromData(imageData: NSData) {
        let image = FLAnimatedImage(animatedGIFData: imageData)
        let imageView = FLAnimatedImageView()
        imageView.contentMode = .ScaleAspectFit
        imageView.animatedImage = image
        contentView.addSubview(imageView)
        addConstraintsToFillSuperview(imageView)
    }
    
    // Display a media player (audio / video)
    private func displayMediaPlayer(url: NSURL, isAudio: Bool) {
        let player = AVPlayer(URL: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        self.addChildViewController(playerViewController)
        contentView.addSubview(playerViewController.view)
        if isAudio {
            playerViewController.view.frame = CGRectZero
            playerViewController.view.leadingAnchor.constraintEqualToAnchor(contentView.leadingAnchor).active = true
            playerViewController.view.trailingAnchor.constraintEqualToAnchor(contentView.trailingAnchor).active = true
            playerViewController.view.heightAnchor.constraintEqualToConstant(44.0).active = true
            playerViewController.view.centerYAnchor.constraintEqualToAnchor(contentView.centerYAnchor).active = true
            playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        } else {
            playerViewController.view.frame = CGRectZero
            addConstraintsToFillSuperview(playerViewController.view)
        }
        
        playerViewController.player!.play()
    }
    
    /* Helpers */
    // Add auto-layout contraints to a view so it fills its superview
    private func addConstraintsToFillSuperview(view: UIView) {
        view.leadingAnchor.constraintEqualToAnchor(view.superview!.leadingAnchor).active = true
        view.trailingAnchor.constraintEqualToAnchor(view.superview!.trailingAnchor).active = true
        view.topAnchor.constraintEqualToAnchor(view.superview!.topAnchor).active = true
        view.bottomAnchor.constraintEqualToAnchor(view.superview!.bottomAnchor).active = true
        view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    // Display a specific image and a text (e.g. when the file isn't supported or an error occured)
    private func displayPlaceholder(imageName: String, text: String) {
        placeholderView.hidden = false
        placeholderImage.image = UIImage(named: imageName)
        placeholderLabel.text = text
    }
    
}
