const { ethers, network } = require("hardhat");

const EditionCurationMinter_Addr = require(`../abis/EditionCurationMinter.${network.name}.json`)
const CANFTMarket_Addr = require(`../abis/CANFTMarket.${network.name}.json`)


async function main() {

  console.log("EditionCurationMinter_Addr :" + EditionCurationMinter_Addr.address)

  let [signer] = await ethers.getSigners();

  let editionCuration =  await ethers.getContractAt("EditionCurationMinter",
    EditionCurationMinter_Addr.address,
    signer);


  let tx = await editionCuration.setAuction(CANFTMarket_Addr.address);
  console.log("CANFTMarket_Addr.address:" + CANFTMarket_Addr.address);
  console.log(" tx.hash" +  tx.hash)
}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });