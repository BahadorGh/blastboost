const hre = require("hardhat");
const path = require("path");
const fs = require("fs");
const waitForTargetBlock = require("./utils");

async function main() {
  const confirmationsNnumber = 5;
  const Contract = await hre.ethers.deployContract("CampaignManager");

  await Contract.waitForDeployment();

  console.log(
    `CampaignManager contract deployed to ${Contract.target} on ${hre.network.name}`
  );

  const gasLot = await hre.ethers.deployContract("GasLot", [Contract.target]);
  await gasLot.waitForDeployment();

  console.log(
    `GasLot contract deployed to ${gasLot.target} on ${hre.network.name}`
  );

  // saveFrontendFiles(Contract);
  saveFrontendFiles(Contract, gasLot);
  await waitForTargetBlock(confirmationsNnumber);
  await verifyContract(Contract);
  await verifyGasLotContract(gasLot, Contract.target);
}

function saveFrontendFiles(myContract, myContract2) {
  // const fs = require("fs");
  const contractsDir = path.join(
    __dirname,
    "..",
    "..",
    "/client",
    "src",
    "abis"
  );

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  fs.writeFileSync(
    path.join(contractsDir, "contract-address.json"),
    JSON.stringify({ ["contractAddress"]: myContract.target }, undefined, 2)
  );
  fs.writeFileSync(
    path.join(contractsDir, "contract-address.json"),
    JSON.stringify(
      { ["gasLotcontractAddress"]: myContract2.target },
      undefined,
      2
    )
  );

  const ContractArtifact = artifacts.readArtifactSync("CampaignManager");
  const GasLotContractArtifact = artifacts.readArtifactSync("GasLot");

  fs.writeFileSync(
    path.join(contractsDir, "contractAbi.json"),
    JSON.stringify(ContractArtifact, null, 2)
  );
  fs.writeFileSync(
    path.join(contractsDir, "contractAbiGasLot.json"),
    JSON.stringify(GasLotContractArtifact, null, 2)
  );
}

async function verifyContract(contract) {
  console.log(`Verifying contract on Blastscan...`);
  try {
    await hre.run("verify:verify", {
      address: contract.target,
      // constructorArguments: [taxVal],
    });
    console.log("Contract Verified Successfully");
  } catch (err) {
    console.log(err);
  }
}
async function verifyGasLotContract(contract, governer) {
  console.log(`Verifying contract on Blastscan...`);
  try {
    await hre.run("verify:verify", {
      address: contract.target,
      constructorArguments: [governer],
    });
    console.log("Contract Verified Successfully");
  } catch (err) {
    console.log(err);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
