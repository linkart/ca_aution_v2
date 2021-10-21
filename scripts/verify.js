const hre =  require("hardhat");

const KnownOriginDigitalAssetV2_Addr = require(`../abis/KnownOriginDigitalAssetV2.${network.name}.json`)

const EditionCurationMinter_Addr = require(`../abis/EditionCurationMinter.${network.name}.json`)
const CANFTMarket_Addr = require(`../abis/CANFTMarket.${network.name}.json`)

const SelfServiceAccessControls_Addr = require(`../abis/SelfServiceAccessControls.${network.name}.json`)
const SelfServiceFrequencyControls_Addr = require(`../abis/SelfServiceFrequencyControls.${network.name}.json`)


async function main() {

  await hre.run("verify:verify", {
    address: EditionCurationMinter_Addr.address,
    constructorArguments: [
      KnownOriginDigitalAssetV2_Addr.address,
      CANFTMarket_Addr.address,
      SelfServiceAccessControls_Addr.address,
      SelfServiceFrequencyControls_Addr.address
    ],
  });

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
