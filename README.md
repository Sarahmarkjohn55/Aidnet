# Aidnet - Community First Aid DAO

A decentralized autonomous organization (DAO) that funds and organizes volunteer EMTs for community emergency response. Built on Stacks blockchain using Clarity smart contracts.

## Overview

Aidnet creates a decentralized network of certified EMTs and first responders who can quickly respond to medical emergencies in their communities. The system incentivizes rapid response through token rewards and maintains quality through reputation scoring and stake-based participation.

## Features

### 🚑 Emergency Management
- Report emergencies with location and severity levels
- Volunteer EMTs can respond to nearby emergencies
- Emergency reporters can accept specific responders
- Track emergency resolution status

### 👨‍⚕️ Volunteer System
- Register as certified EMT with stake requirement
- Earn reputation through successful responses
- Receive AID tokens for emergency responses
- Training session participation tracking

### 🎓 Training & Education
- Create and manage training sessions
- Reward participants with AID tokens
- Track training completion for certification maintenance

### 🗳️ DAO Governance
- Create proposals for system improvements
- Token-weighted voting system
- Community-driven decision making

### 💰 Funding & Rewards
- Community funding through STX contributions
- Automatic reward distribution for responses
- Training incentives and reputation building

## Quick Start

### Prerequisites
- [Clarinet](https://docs.hiro.so/stacks/clarinet) installed
- Node.js and npm for testing

### Installation
```bash
git clone <repository-url>
cd Aidnet
clarinet check
npm install
npm test
```

## Contract Functions

### Core Functions

#### `register-volunteer`
Register as an EMT volunteer (requires STX stake)
```clarity
(register-volunteer certification-level)
```

#### `report-emergency`
Report a medical emergency
```clarity
(report-emergency location severity)
```

#### `respond-to-emergency`
Respond to an emergency as a volunteer EMT
```clarity
(respond-to-emergency emergency-id)
```

#### `accept-responder`
Accept a specific responder for your emergency
```clarity
(accept-responder emergency-id responder-principal)
```

#### `contribute-to-fund`
Contribute STX to the emergency fund
```clarity
(contribute-to-fund amount)
```

### Training Functions

#### `create-training-session`
Create a new training session
```clarity
(create-training-session title date max-participants reward-per-participant)
```

#### `join-training-session`
Join a training session as a volunteer
```clarity
(join-training-session session-id)
```

### Governance Functions

#### `create-proposal`
Create a governance proposal
```clarity
(create-proposal title description voting-duration)
```

#### `vote-on-proposal`
Vote on a governance proposal
```clarity
(vote-on-proposal proposal-id vote-boolean)
```

## Token Economics

- **AID Token**: Fungible token earned through participation
- **Emergency Response**: 500 AID tokens per accepted response
- **Training Completion**: Variable rewards based on session
- **Emergency Reporting**: 50 AID tokens per valid report
- **Community Contribution**: 1 AID per 10 STX contributed

## Staking & Requirements

- **Volunteer Registration**: 1000 µSTX minimum stake
- **Proposal Creation**: 100 AID tokens required
- **Active Status**: Maintained through regular training participation

## Read-Only Functions

- `get-volunteer`: View volunteer profile
- `get-emergency`: View emergency details
- `get-proposal`: View proposal information
- `get-training-session`: View training session details
- `get-total-fund`: View total community fund
- `get-contract-balance`: View contract STX balance

## Data Structures

### Volunteer Profile
```clarity
{
  certification-level: uint,
  total-responses: uint,
  reputation-score: uint,
  staked-amount: uint,
  active: bool,
  last-training: uint
}
```

### Emergency Record
```clarity
{
  reporter: principal,
  location: string-ascii,
  severity: uint,
  status: uint,
  created-at: uint,
  responder: optional principal,
  resolved-at: optional uint
}
```

## Development

### Testing
```bash
npm test
```

### Deployment
```bash
clarinet integrate
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## License

Open source - see LICENSE file for details.

## Support

For questions or support, please create an issue in the repository.
