const { ethers, upgrades, network } = require("hardhat");

// const hre =  require("hardhat");

const { writeAddr } = require('./artifact_log.js');

const AccessControl_Addr = require(`../abis/AccessControl.${network.name}.json`)
const KnownOriginDigitalAssetV2_Addr = require(`../abis/KnownOriginDigitalAssetV2.${network.name}.json`)

console.log("KnownOriginDigitalAssetV2_Addr:" + KnownOriginDigitalAssetV2_Addr.address)
console.log("AccessControl_Addr:" + AccessControl_Addr.address)

async function main() {
  let [owner]  = await ethers.getSigners();

  const CANFTMarket = await ethers.getContractFactory("CANFTMarket");
  const market = await CANFTMarket.deploy(AccessControl_Addr.address, 
    KnownOriginDigitalAssetV2_Addr.address,
    owner.address);
  await market.deployed();

  console.log("CANFTMarket deployed to:", market.address);
  
  await writeAddr(market.address, "CANFTMarket", network.name)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
