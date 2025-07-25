# Collaborative Story Universe

A decentralized platform for collaborative storytelling where creators earn from their contributions built on the Stacks blockchain.

## Overview

The Collaborative Story Universe is a smart contract that enables:
- Creation of shared fictional worlds
- Collaborative story contributions
- Revenue sharing among creators and contributors
- Community voting on contributions
- Creator reputation system

## Features

- **Story Creation**: Users can create new story universes with custom genres and contributor limits
- **Contributions**: Community members can contribute chapters, characters, plots, and settings
- **Voting System**: Community voting on contributions to maintain quality
- **Earnings Distribution**: Automatic revenue sharing (60% creator, 35% contributors, 5% platform)
- **User Profiles**: Reputation tracking and contributor statistics

## Smart Contract Functions

### Public Functions
- `create-story`: Create a new story universe
- `contribute-to-story`: Add contributions to existing stories
- `vote-contribution`: Vote on story contributions
- `approve-contribution`: Approve contributions (creator only)
- `distribute-earnings`: Distribute earnings to contributors
- `create-user-profile`: Create/update user profile

### Read-Only Functions
- `get-story`: Retrieve story information
- `get-contribution`: Get contribution details
- `get-user-profile`: View user profile
- `get-story-contributor`: Get contributor statistics

## Getting Started

### Prerequisites
- Clarinet CLI
- Stacks Wallet
- Node.js (for testing)

### Installation
1. Clone this repository
2. Run `clarinet console` to interact with the contract
3. Deploy to testnet for testing

## Contract Architecture

The contract uses several data maps to store:
- Story metadata and settings
- User contributions and content
- Voting records and reputation
- Revenue sharing configurations

## Revenue Model

- **Creator**: 60% of story earnings
- **Contributors**: 35% shared among contributors
- **Platform**: 5% for maintenance and development

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - see LICENSE file for details



## Development Status
✅ Smart contract implementation complete
✅ Core functionality tested
🔄 Ready for community feedback
