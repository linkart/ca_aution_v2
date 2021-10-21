const { ethers, network } = require("hardhat");

// const hre =  require("hardhat");

const { writeAddr } = require('./artifact_log.js');


const KnownOriginDigitalAssetV2_ABI = require("../abis/KnownOriginDigitalAssetV2.json")
const KnownOriginDigitalAssetV2_Addr = require(`../abis/KnownOriginDigitalAssetV2.${network.name}.json`)


const CANFTMarket_Addr = require(`../abis/CANFTMarket.${network.name}.json`)

const SelfServiceAccessControls_ABI = require("../abis/SelfServiceAccessControls.json")
const SelfServiceFrequencyControls_ABI = require("../abis/SelfServiceFrequencyControls.json")
const SelfServiceAccessControls_Addr = require(`../abis/SelfServiceAccessControls.${network.name}.json`)
const SelfServiceFrequencyControls_Addr = require(`../abis/SelfServiceFrequencyControls.${network.name}.json`)

console.log("KnownOriginDigitalAssetV2_Addr:" + KnownOriginDigitalAssetV2_Addr.address)
console.log("SelfServiceFrequencyControls_Addr:" + SelfServiceFrequencyControls_Addr.address)
console.log("SelfServiceAccessControls_Addr:" + SelfServiceAccessControls_Addr.address)

async function main() {

  let [owner]  = await ethers.getSigners();
  console.log("owner:" + owner.address)

  const EditionCurationMinter = await ethers.getContractFactory("EditionCurationMinter");
  const edition = await EditionCurationMinter.deploy(
    KnownOriginDigitalAssetV2_Addr.address,
    CANFTMarket_Addr.address,
    SelfServiceAccessControls_Addr.address,
    SelfServiceFrequencyControls_Addr.address
    );
  await edition.deployed();

  console.log("EditionCurationMinter deployed to:", edition.address);
  
  await writeAddr(edition.address, "EditionCurationMinter", network.name)


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
