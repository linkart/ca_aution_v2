const { ethers, network } = require("hardhat");

// const hre =  require("hardhat");

const { writeAddr } = require('./artifact_log.js');

async function main() {
  console.log(network.name)

  let [owner]  = await ethers.getSigners();
  console.log("owner:" + owner.address)

  const AccessControl = await ethers.getContractFactory("AccessControl");
  const access = await AccessControl.deploy();
  await access.deployed();

  console.log("AccessControl deployed to:", access.address);
  
  await writeAddr(access.address, "AccessControl", network.name)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
