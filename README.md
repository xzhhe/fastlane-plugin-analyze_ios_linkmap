# analyze_ios_linkmap plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-analyze_ios_linkmap)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-analyze_ios_linkmap`, add it to your project by running:

```bash
fastlane add_plugin analyze_ios_linkmap
```

## About analyze_ios_linkmap

xx

**Note to author:** Add a more detailed description about this plugin here. If your plugin contains multiple actions, make sure to mention them here.

## Example

Check out the [example `Fastfile`](fastlane/Fastfile) to see how to use this plugin. Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.

```ruby
lane :test do
  # eg1: 
  analyze_ios_linkmap(
    filepath: '/Users/xiongzenghui/collect_rubygems/fastlane-plugins/fastlane-plugin-analyze_ios_linkmap/spec/demo-LinkMap.txt'
  )
  pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_HASH]
  pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_JSON]

  # eg2: 
  analyze_ios_linkmap(
    filepath: '/Users/xiongzenghui/Desktop/osee2unifiedRelease-LinkMap-normal-arm64.txt',
    search_symbol: 'TDATEvo'
  )
  pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_SEARCH_SYMBOL]
end

```



## Run tests for this plugin

To run both the tests, and code style validation, run

```
rake
```

To automatically fix many of the styling issues, use
```
rubocop -a
```

## Issues and Feedback

For any other issues and feedback about this plugin, please submit it to this repository.

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
