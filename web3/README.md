# BlastBoost Project

The BlastBoost Decentralized crowdfunding platfrom is mainly for people to raise donations for their projects or even humanity use cases.
It comes with a contract, and a script that deploys and verifies that contracts. (note: tests for the contracts will be added at a later time)

# Deploy the core contract on `Blast Sepolia` network:

Take steps as below:

```shell
npm install
npx hardhat run scripts/deploy.js --network blast_boost
```

Thats' it!

As you run `deploy.js`, below things happen:

- Contract will be deployed
- `Contract address`es and `ABI`s will go to the `client/src/abi` folder
- We will wait for `5` block confirmation from sepolia chain to request verifying the contract(with the help of `utils.js` in script folder)
- Contract verification will be successfully done if everything goes fine.

# Deploy on localhsot:

Terminal #1:

```shell
npx hardhat node
```

Terminal #2:

```shell
npx hardhat run scripts/deploy.js --network localhost
```

- Note1: Make sure commenting the below lines of code in `deploy.js` when deploying on `localhost`:

```JavaScript
const waitForTargetBlock = require('./utils')  --> line 4
await waitForTargetBlock(confirmationsNnumber); --> line 18
```

- Note2: Make sure to set correct configurations in your `hardhat.config.js`

- Note3: When changing the network from `Blast Sepolia` to `localhost`, you have to make some little changes in frontend part ( `client/src/main.jsx` folder):

```Javascript
  <ThirdwebProvider
    desiredChainId={ChainId.Localhost}
    activeChain={ChainId.Localhost}
  >
```
