# StatRockSdk

[![Version](https://img.shields.io/cocoapods/v/StatRockSdk.svg?style=flat)](https://cocoapods.org/pods/StatRockSdk)
[![License](https://img.shields.io/cocoapods/l/StatRockSdk.svg?style=flat)](https://cocoapods.org/pods/StatRockSdk)
[![Platform](https://img.shields.io/cocoapods/p/StatRockSdk.svg?style=flat)](https://cocoapods.org/pods/StatRockSdk)

## Installation

StatRockSdk is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'StatRockSdk'
```

## Example

```swift
player = StatRockView()
player.frame = CGRect(x: 16, y: 50, width: 200, height: 100)

// or use NSLayoutConstraint
player.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    player!.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
    player!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
    player!.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
    player.heightAnchor.constraint(equalToConstant: 200)
])

view.addSubview(player)
player.load(placement: "your_placement_id", type: .inPage, delegate: self)
```

## StatRockDelegate

Implement the `StatRockDelegate` protocol to receive ad callbacks:

```swift
extension YourViewController: StatRockDelegate {

    func onAdLoaded() {
        // Ad has been loaded
    }
    
    func onAdStarted() {
        // Ad playback has started
    }
    
    func onAdStopped() {
        // Ad playback has stopped
    }
    
    func onAdError(errorType: AdErrorType, errorMessage: String?) {
        switch errorType {
        case .noInternet:
            // Handle no internet connection
        case .timeout:
            // Handle timeout (ad load timeout or request timeout)
        case .networkError:
            // Handle other network errors
        case .noAd:
            // No ad available
        case .unknown:
            // Unknown error
        }
    }
}
```

## Features

- **Network Error Handling**: Automatic detection of network connectivity issues
- **Timeout Handling**: 
  - HTTP request timeout (10 seconds)
  - Ad load timeout (15 seconds) - fires if no response from ad network
- **Type-Safe Error Handling**: Use `AdErrorType` enum for error classification
- **In-Page Ad Support**: Support for in-page ad placement with visibility tracking

## Error Types

The SDK provides the following error types via `AdErrorType` enum:

- `noInternet` - No internet connection available
- `timeout` - Request or ad load timeout
- `networkError` - Other network-related errors
- `noAd` - No ad inventory available
- `unknown` - Unknown error type

## License

StatRockSdk is available under the Apache License. See the LICENSE file for more info.
