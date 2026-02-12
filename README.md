# God's Eye Anti-Cheat

An advanced protection system against mod menu exploits in GTA RP servers, specifically designed for QBCore/Qbx Framework.

![God's Eye Banner](https://github.com/SL-oomiBoy/God-s-Eye-Anti-Cheat/blob/main/images/logo.png)

## Overview

God's Eye Anti-Cheat is a comprehensive security solution designed to protect your FiveM server from common cheating methods. This anti-cheat system monitors player activities in real-time to detect and prevent various exploits, providing server owners with powerful tools to maintain fair gameplay.

## Features

- **Blacklisted Weapons Detection**: Automatically detects and logs players using prohibited weapons
- **Blacklisted Vehicles Protection**: Prevents spawning of military and other restricted vehicles
- **Health & Armor Monitoring**: Detects players with abnormal health or armor values
- **Anti-Teleport System**: Identifies suspicious position changes to prevent teleport hacks
- **Suspicious Event Monitoring**: Tracks and blocks potentially harmful event triggers
- **Resource Protection**: Prevents unauthorized stopping or restarting of critical resources
- **Anti-Explosion Protection**: Controls explosion events to prevent mass destruction
- **Discord Integration**: Placeholder (ready for webhook implementation)
- **Comprehensive Logging**: Detailed logs of all detected violations
- **Configurable Punishment System**: Customizable responses including kicks and bans
- **Admin Exemption System**: Whitelist for staff members
- **Performance Optimized**: Designed for minimal server impact

## Configuration

God's Eye Anti-Cheat features extensive configuration options through the `config.lua` file:

- Customize detection thresholds
- Add or remove blacklisted items
- Set check intervals
- Configure punishment methods
- Adjust logging preferences
- Set up Discord webhook integration
- Performance optimization settings

## Installation

1. Download the latest release
2. Extract the folder to your server's resources directory
3. Add `ensure <folder_name>` to your server.cfg (use the actual resource folder name)
4. Configure the settings in `config.lua` to match your server's needs
5. Restart your server

## Requirements

- FiveM Server
- QBX/QBCore Framework

## Support

If you encounter any issues or have questions, please open an issue on this GitHub repository.

## License

[MIT License](LICENSE)

## Credits

Developed by Omiya
