# analyze_ios_linkmap plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-analyze_ios_linkmap)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-analyze_ios_linkmap`, add it to your project by running:

```bash
fastlane add_plugin analyze_ios_linkmap
```

## About analyze_ios_linkmap

**Note to author:** Add a more detailed description about this plugin here. If your plugin contains multiple actions, make sure to mention them here.

## Example

Check out the [example `Fastfile`](fastlane/Fastfile) to see how to use this plugin. Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.

### Eg1: 默认解析一个 linkmap.txt

```ruby
path = '/Users/xiongzenghui/Desktop/Demo-LinkMap-normal-arm64.txt'
Fastlane::Actions::AnalyzeIosLinkmapAction.run( file_path: path )
pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_HASH]
pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_JSON]
```

### Eg2: 显示所有的 object file

```ruby
path = '/Users/xiongzenghui/Desktop/Demo-LinkMap-normal-arm64.txt'
Fastlane::Actions::AnalyzeIosLinkmapAction.run(
  file_path: path,
  all_objects: true
)
pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_HASH]
pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_JSON]
```

### Eg3: 显示所有的 symbol

```ruby
path = '/Users/xiongzenghui/Desktop/Demo-LinkMap-normal-arm64.txt'
Fastlane::Actions::AnalyzeIosLinkmapAction.run(
  file_path: path,
  all_objects: true,
  all_symbols: true
)
pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_HASH]
pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_JSON]
```

### Eg4: 根据 podspec name 进行合并

```ruby
path = '/Users/xiongzenghui/Desktop/Demo-LinkMap-normal-arm64.txt'
Fastlane::Actions::AnalyzeIosLinkmapAction.run(
  file_path: path,
  all_objects: false,
  all_symbols: false,
  merge_by_pod: true
)
pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_HASH]
pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_JSON]
pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_MERGE_HASH]
pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_PARSED_MERGE_JSON]
```

### Eg5: 搜索一个 symbol 所属的 library

```ruby
path = '/Users/xiongzenghui/Desktop/Demo-LinkMap-normal-arm64.txt'
Fastlane::Actions::AnalyzeIosLinkmapAction.run(
  file_path: path,
  search_symbol: 'TDATEvo'
)
pp Fastlane::Actions.lane_context[Fastlane::Actions::ShatedValues::ANALYZE_IOS_LINKMAP_SEARCH_SYMBOL]
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
