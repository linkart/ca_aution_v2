const { ethers, upgrades, network } = require("hardhat");

// const hre =  require("hardhat");

const { writeAddr } = require('./artifact_log.js');

async function main() {
  console.log(network.name)

  const Box = await ethers.getContractFactory("Box");
  const box = await upgrades.deployProxy(Box, [43]);
  await box.deployed();

  console.log("Box deployed to:", box.address);
  
  await writeAddr(box.address, "Box", network.name)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
