# BlastBoost Project

The BlastBoost Decentralized crowdfunding platfrom is mainly for people to raise donations for their projects or even humanity use cases.

# Main functionalities of the project till the day

- Creating fundraising campaigns
- Updating fundraising campaigns
- Donating to campaigns
- Deleting campaigns
- Withdrawing funds
- Refunding funds(in case of emergency and campaign deleting)
- Generating blast yields for donators of each campaign
- Holding a Lottery from the total gas spent from donators of the projects(divided to 3 different shares)

##

Back-end parts (`solidity`) are located in `web3` folder.
Front-end parts are located in `client` folder.

![Donation(crowdfunding or fundraising dapp)](Image/donation-dapp.png?raw=true)

# Starting the frontend:

Take steps as below:

- 0. deploy core smart contracts ( `CampaignManager.sol` & `GasLot.sol`) from `web3` folder on your desire network(default is BlastSepolia). Explanation is located at `web3` folder.
- 1. `cd client`
- 2. `npm install`
- 3. to start the frontend: `yarn dev`
- 4. easily work with the platform

* Note: In case facing error of **_to high nonce_** (on `localhost` network), first reset your `Metamask` as stated below, and then try again:

- Open **Metamask** > **Settings** > **Advanced** > **Clear activity and nonce data** > click on **`Clear activity tab data`** button

# Video links

### Video of project description:

1. To watch project's description video, click here > [Watch project's description](https://mega.nz/file/utRknRDL#fd8FQJiRPkONAE2yk5bU7HSaRUTPk7Tv-VAv4ZzOCQQ)

2. To watch project's interaction video, click here > [Watch live project interaction](https://mega.nz/file/ToBwGZRJ#yk1_bEXX_gU7HaTZU9UeSKKEflhEpqPGfmMHKrFRs90)
