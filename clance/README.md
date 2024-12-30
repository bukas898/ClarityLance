# ClarityLance

ClarityLance is a decentralized freelancing platform built on the Stacks blockchain using Clarity smart contracts. It enables secure and transparent job posting, bidding, and completion processes for freelancers and clients.

## Features

- Post jobs with detailed specifications
- Submit and manage bids
- Automatic bid validation and job state management
- Secure payment handling
- Transparent job lifecycle

## Smart Contract Overview

The ClarityLance smart contract is written in Clarity and provides the following main functionalities:

1. Job posting and management
2. Bid submission and withdrawal
3. Job finalization and payment
4. Read-only functions for retrieving job details and status

## Getting Started

To use ClarityLance, you'll need to interact with the Stacks blockchain. Make sure you have:

1. A Stacks wallet (e.g., Hiro Wallet)
2. STX tokens for transaction fees
3. Familiarity with Clarity and Stacks blockchain concepts

## Usage

The contract can be deployed to the Stacks blockchain using the Clarinet development environment or through other Stacks deployment methods.

## Functions

### Public Functions

1. `post-job`: Create a new job listing
2. `submit-bid`: Submit a bid for a job
3. `finalize-job`: Complete a job and transfer payment
4. `publish-job`: Change a job's status from draft to open
5. `withdraw-bid`: Withdraw a previously submitted bid

### Read-Only Functions

1. `get-job-details`: Retrieve detailed information about a job
2. `get-job-status`: Get the current status of a job

## Constants and Data Structures

### Job States

- DRAFT (0)
- OPEN (1)
- COMPLETED (2)
- CANCELED (3)

### Maps

- `jobs`: Stores job details
- `bids`: Tracks bids for each job
- `bid-returns`: Manages bid refunds

## Error Handling

The contract includes various error constants to handle different scenarios:

- ERR-NO-ACCESS (403): Unauthorized access
- ERR-JOB-NOT-FOUND (404): Job not found
- ERR-JOB-CLOSED (405): Job is no longer open
- ERR-BID-TOO-LOW (406): Bid amount is too low
- ERR-JOB-IN-PROGRESS (407): Job is still in progress
- ERR-PAYMENT-ISSUE (408): Payment transfer failed
- ERR-BAD-PARAMS (409): Invalid parameters provided

## Security Considerations

- The contract includes checks to ensure only authorized users can perform certain actions
- Bid amounts are validated to prevent underbidding
- Job durations are limited to prevent excessively long or short job postings
