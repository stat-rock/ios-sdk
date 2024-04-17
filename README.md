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

        player = StatRockView()
        player.frame = CGRect(x: 16, y: 50, width: 200, height: 100)
        
        or use NSLayoutConstraint
        
        player.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            player!.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            player!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            player!.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            player!.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        view.addSubview(player)
        player.load(placement: <your placement>, delegate: self)

## License

StatRockSdk is available under the Apache License. See the LICENSE file for more info.
