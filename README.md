![ImageUI](https://user-images.githubusercontent.com/9810726/81400704-08c6f080-912e-11ea-8833-114e0cc0c773.png)  

<img src="https://img.shields.io/cocoapods/v/ImageUI.svg?label=version"> [![Platform](https://img.shields.io/cocoapods/p/ImageUI.svg?style=flat)](https://developer.apple.com/iphone/index.action)   <img src="https://img.shields.io/badge/supports-Swift%20Package%20Manager%2C%20CocoaPods%2C%20Carthage-green.svg">

## Welcome to ImageUI!
**ImageUI** is an open source project for displaying images and videos (not yet implemented) in a similar way to Apple’s Photos app.
If you'd like to contribute to ImageUI see [**Contributing**](#contributing).
In this version there is the photo browser that allows to display thumbnail and full-size images.

- [Features](#features)
- [Requirements](#requirements)
- [Dependencies](#dependencies)
- [Installation](#installation)
- [Usage](#usage)
- [Customization](#customization)
- [Contributing](#contributing)

## Features
- [x] Loading remote, local and in-memory images
- [x] Support both portrait and landscape mode
- [x] Sharing, deleting (not yet implemented) and custom actions
- [x] Size class adaptive layout (iOS, iPadOS)
- [x] Dark mode
- [x] Multiple gestures (tap, double tap, pan, swipe, pinch)
- [x] LPLinkMetadata (iOS 13.0+)
- [x] SwiftUI compatible

## Requirements
- iOS 11.0+
- Xcode 11+
- Swift 5.1+

## Dependencies
- [Nuke](https://github.com/kean/Nuke)
> Powerful Image Loading System

## Installation

### CocoaPods
[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate ImageUI into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'ImageUI'
```

### Carthage
[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks. To integrate ImageUI into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "alberto093/ImageUI"
```

### Swift Package Manager
[Swift Package Manager](https://swift.org/package-manager/) is a dependency manager built into Xcode.

If you are using Xcode 11 or higher, go to **File / Swift Packages / Add Package Dependency...** and enter package repository URL **https://github.com/alberto093/ImageUI.git**, then follow the instructions.
Once you have your Swift package set up, adding ImageUI as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/alberto093/ImageUI.git")
]
```

## Usage

### Creating the data source
**IFImage** is the data structure that represents the image metadata.
You can instantiate an IFImage in a three different ways:
```swift
let urlImage = IFImage(url: imageURL) // network URL
let fileImage = IFImage(path: filePath) // file URL (path)
let memoryImage = IFImage(image: myUIImage) // in-memory image
```
To get the best performances you should provide both the thumbnail and full-size images especially if you are using network URLs.
Optionally you can provide a title that represents the navigation bar title (and the sharing metadata title available on iOS 13.0+) and a loading placeholder image.
```swift
let image = IFImage(
    title: "First image",
    original: .remote(url: imageURL),
    thumbnail: .remote(url: thumbnailURL),
    placeholder: loadingImage)
```
> Ideally the thumbnail images' sizes should be smaller than 300x300 (the maximum size on iPad)

### Displaying the browser
**IFBrowserViewController** represents the container of both thumbnails and full-size images.
It is possibile to use it directly in Storyboard or programmatically and It does not require a `UINavigationController` but It is strongly recommended.

```swift
let viewController = IFBrowserViewController(images: images, initialImageIndex: 0)
viewController.actions = [.share]

// Navigation controller
navigationController.pushViewController(viewController, animated: true)

// Modal presentation
let navigationController = UINavigationController(rootViewController: browserViewController)
navigationController.modalPresentationStyle = .fullScreen
present(navigationController, animated: true)
```

> Custom presentation controllers and custom animators `UIViewControllerInteractiveTransitioning`, `UIViewControllerAnimatedTransitioning` are work in progress.
## Customization

### Providing the initial index
It is possible to set the initial displaying image index.
```swift
// images: [IFImage]
let viewController = IFBrowserViewController(images: images, initialImageIndex: .random(in: images.indices))
```
>The `IFBrowserViewController` clamps the provided value to avoid unexpected crash.

###  Aspect fill images
The `IFBrowserViewController` allows you to decide whether the full-size image should be displayed using the aspect fill zoom if the aspect ratio is similar to its container view. 

<p align="center">
<img align="left" height="136" src="https://user-images.githubusercontent.com/9810726/81415560-e5f60580-9148-11ea-99db-b939e3a0e57c.png">

```swift
let viewController = IFBrowserViewController(
    images: images, 
    initialImageIndex: 0)

viewController.prefersAspectFillZoom = false // default
```
</p>

<p align="center">
<img align="left" height="136" src="https://user-images.githubusercontent.com/9810726/81415520-da0a4380-9148-11ea-9dab-c0c9aae1daea.png">

```swift
let viewController = IFBrowserViewController(
    images: images, 
    initialImageIndex: 0)

viewController.prefersAspectFillZoom = true
```
</p>

### Custom actions
It is possibile to create a custom action to allow user to interact with images.
```swift
browserViewController.actions = [.share, .custom(identifier: "cropAction", image: cropImage)]
```
>Sharing and deleting (not yet implemented) actions are already managed by the `IFBrowserViewController`.

Then you can interact with them by implementing `IFBrowserViewControllerDelegate`:
```swift
func browserViewController(_ browserViewController: IFBrowserViewController, didSelectActionWith identifier: String, forImageAt index: Int) {
    switch identifier {
    case  "cropAction":
        // User tap on crop action
    default:
        break
    }
}
```

### Dismiss button
The browser implements the default cancel bar button item when it is presented modally. You can provide your own bar button item by setting navigation item related-property:
```swift
browserViewController.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeButtonDidTap))
```
> It is recommended to subclass `IFBrowserViewController` instead of provide a button with an another target

### Navigation bar title
It is possible to provide a title or a title view to avoid automatic updates when a new image is about to be displayed.
```swift
browserViewController.navigationItem.titleView = CustomLabel(title: "ImageUI", subtitle: "My album")
```

### More customization
You can adopt `IFBrowserViewControllerDelegate` and implement the following method in order to update the UI by your rules.

```swift
func browserViewController(_ browserViewController: IFBrowserViewController, willDisplayImageAt index: Int) {
    // A new image is about to be displayed
}
```

## Contributing
[ImageUI's roadmap](https://trello.com/b/EyLeOgmV/imageui) is managed by Trello and is publicly available. If you'd like to contribute, please feel free to create a PR.

## License
ImageUI is released under the MIT license. See [LICENSE](https://github.com/alberto093/ImageUI/blob/master/LICENSE) for details.
