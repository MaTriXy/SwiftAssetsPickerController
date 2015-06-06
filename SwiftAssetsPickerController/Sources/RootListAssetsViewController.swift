//
//  RootListAssetsViewController.swift
//  SwiftAssetsPickerController
//
//  Created by Maxim Bilan on 6/5/15.
//  Copyright (c) 2015 Maxim Bilan. All rights reserved.
//

import UIKit
import Photos

enum AlbumType: Int {
	case AllPhotos
	case Favorites
	case Panoramas
	case Videos
	case TimeLapse
	case RecentlyDeleted
	case UserAlbum
	
	static let titles = ["All Photos", "Favorites", "Panoramas", "Videos", "Time Lapse", "Recently Deleted", "User Album"]
}

struct RootListItem {
	var title: String!
	var albumType: AlbumType
	var image: UIImage!
}

class RootListAssetsViewController: UITableViewController, PHPhotoLibraryChangeObserver {
	
	private var items: Array<RootListItem>!
	private var activityIndicator: UIActivityIndicatorView!
	private let reuseIdentifier = "RootListAssetsCell"
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Navigation bar
		navigationItem.title = "Photos"
		navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: "cancelAction")
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: "doneAction")
		navigationItem.rightBarButtonItem?.enabled = false
		
		// Activity indicator
		activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
		activityIndicator.hidesWhenStopped = true
		activityIndicator.center = self.view.center
		self.view.addSubview(activityIndicator)
		
		// Data
		items = Array()
		
		// Notifications
		PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(true)
		
		loadData()
	}
	
	deinit {
		PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// MARK: ---
	
	func loadData() {
		tableView.userInteractionEnabled = false
		activityIndicator.startAnimating()
		
		let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
		dispatch_async(dispatch_get_global_queue(priority, 0)) {
		
			self.items.removeAll(keepCapacity: false)
			
			let allPhotosItem = RootListItem(title: AlbumType.titles[AlbumType.AllPhotos.rawValue], albumType: AlbumType.AllPhotos, image: self.lastImageFromCollection(nil))
			self.items.append(allPhotosItem)
			
			let smartAlbums = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.SmartAlbum, subtype: PHAssetCollectionSubtype.AlbumRegular, options: nil)
			for var i: Int = 0; i < smartAlbums.count; ++i {
				if let smartAlbum = smartAlbums[i] as? PHAssetCollection {
					var item: RootListItem? = nil
					
					switch smartAlbum.assetCollectionSubtype {
					case .SmartAlbumFavorites:
						item = RootListItem(title: AlbumType.titles[AlbumType.Favorites.rawValue], albumType: AlbumType.Favorites, image: self.lastImageFromCollection(smartAlbum))
						break
					case .SmartAlbumPanoramas:
						item = RootListItem(title: AlbumType.titles[AlbumType.Panoramas.rawValue], albumType: AlbumType.Panoramas, image: self.lastImageFromCollection(smartAlbum))
						break
					default:
						break
					}
					
					if item != nil {
						self.items.append(item!)
					}
				}
			}
			
			
			
			let topLevelUserCollections = PHCollectionList.fetchTopLevelUserCollectionsWithOptions(nil)
			for var i: Int = 0; i < topLevelUserCollections.count; ++i {
				if let userCollection = topLevelUserCollections[i] as? PHAssetCollection {
					let item = RootListItem(title: userCollection.localizedTitle, albumType: AlbumType.UserAlbum, image: self.lastImageFromCollection(userCollection))
					self.items.append(item)
				}
			}
			
			
			dispatch_async(dispatch_get_main_queue()) {
				self.tableView.reloadData()
				self.activityIndicator.stopAnimating()
				self.tableView.userInteractionEnabled = true
			}
		}
	}
	
	// MARK: UITableViewDataSource
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return items.count
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: reuseIdentifier)
		
		cell.textLabel?.text = items[indexPath.row].title
		cell.imageView?.image = items[indexPath.row].image
		//cell.textLabel?.text = "Row #\(indexPath.row)"
		//cell.detailTextLabel?.text = "Subtitle #\(indexPath.row)"
		return cell
	}
	
	// MARK: UITableViewDelegate
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
		let assetsGrid = AssetsGridViewController(collectionViewLayout: UICollectionViewLayout())
		navigationController?.pushViewController(assetsGrid, animated: true)
	}
	
	// MARK: Navigation bar actions
	
	func cancelAction() {
		dismissViewControllerAnimated(true, completion: nil)
	}
	
	func doneAction() {
		
	}
	
	// MARK: PHPhotoLibraryChangeObserver
	
	func photoLibraryDidChange(changeInstance: PHChange!) {
		
	}
	
	// MARK: Other
	
	func lastImageFromCollection(collection: PHAssetCollection?) -> UIImage? {
		
		var returnImage: UIImage? = nil
		
		let fetchOptions = PHFetchOptions()
		fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
		
		let fetchResult = (collection == nil) ? PHAsset.fetchAssetsWithMediaType(.Image, options: fetchOptions) : PHAsset.fetchAssetsInAssetCollection(collection, options: fetchOptions)
		if let lastAsset:PHAsset = fetchResult.lastObject as? PHAsset {
			
			let imageRequestOptions = PHImageRequestOptions()
			imageRequestOptions.synchronous = true
			
			let manager = PHImageManager.defaultManager()
			manager.requestImageDataForAsset(lastAsset,
				options: imageRequestOptions,
				resultHandler: { (data, uti, orientation, dict ) -> Void in
					if data != nil {
						if let image = UIImage(data: data) {
							returnImage = image
						}
					}
			})
		}
		
		return returnImage
	}
	
}