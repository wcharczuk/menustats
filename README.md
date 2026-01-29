# MenuStats

A lightweight macOS menu bar application for monitoring system statistics including CPU, memory, network, and disk usage.

## Features

- **Real-time monitoring** of CPU, memory, network, and disk metrics
- **Multiple display modes** per metric: text or graph
- **Configurable thresholds** with warning and critical levels
- **Dynamic indicator** that highlights metrics approaching or exceeding thresholds
- **Outlier detection** based on historical activity patterns
- **Minimal footprint** - runs entirely in the menu bar

## Requirements

- macOS 14.0 or later
- Xcode 15+ (for building)

## Building

```bash
./build.sh
```

This creates an app bundle at `.build/release/MenuStats.app`.

## Installation

After building:

```bash
./install.sh
```

This installs the app to `/Applications/MenuStats.app` and launches it.

## Usage

MenuStats displays system metrics in the menu bar. Each enabled metric appears as a separate item showing either text values or a mini graph.

Click any metric to see detailed information and access preferences.

### Menu Bar Items

- **NET** - Network upload/download rates
- **MEM** - Memory usage percentage
- **CPU** - CPU usage percentage
- **DSK** - Disk usage percentage

### Preferences

Access preferences by clicking any menu bar item and selecting "Preferences...".

#### General
- Update interval (1-10 seconds)
- Launch at login

#### Metrics
- Enable/disable individual metrics
- Choose display mode (text or graph) for each

#### Dynamic
- Enable/disable the dynamic indicator
- Configure outlier detection sensitivity
- Set minimum history samples for outlier detection

#### Thresholds
- Set warning and critical thresholds for each metric
- Visual dual-thumb slider with colored ranges

## License

MIT
