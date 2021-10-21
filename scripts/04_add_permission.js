const { ethers, network } = require("hardhat");

const KnownOriginDigitalAssetV2_ABI = require("../abis/KnownOriginDigitalAssetV2.json")
const KnownOriginDigitalAssetV2_Addr = require(`../abis/KnownOriginDigitalAssetV2.${network.name}.json`)

const EditionCurationMinter_Addr = require(`../abis/EditionCurationMinter.${network.name}.json`)
const CANFTMarket_Addr = require(`../abis/CANFTMarket.${network.name}.json`)

const SelfServiceAccessControls_ABI = require("../abis/SelfServiceAccessControls.json")
const SelfServiceFrequencyControls_ABI = require("../abis/SelfServiceFrequencyControls.json")
const SelfServiceAccessControls_Addr = require(`../abis/SelfServiceAccessControls.${network.name}.json`)
const SelfServiceFrequencyControls_Addr = require(`../abis/SelfServiceFrequencyControls.${network.name}.json`)


async function main() {

  console.log("EditionCurationMinter_Addr :" + EditionCurationMinter_Addr.address)

  let [signer] = await ethers.getSigners();

  if (network.name == "kovan_fork") {
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: ["0xdB6E076eA582fbE875f6998B610422b9b162a42a"],
    });
    signer = await ethers.getSigner("0xdB6E076eA582fbE875f6998B610422b9b162a42a")

  }

    let koda = new ethers.Contract(KnownOriginDigitalAssetV2_Addr.address, KnownOriginDigitalAssetV2_ABI.abi , signer)
    const owner = await koda.owner();
    console.log("owner:" + owner);
    console.log("siger:" + koda.signer.address);

    let frequencyControls = new ethers.Contract(SelfServiceFrequencyControls_Addr.address, SelfServiceFrequencyControls_ABI.abi , signer)

    console.log("addAddressToWhitelist")
    // // whitelist self service address so it can call frequency controls
    await frequencyControls.addAddressToWhitelist(EditionCurationMinter_Addr.address);

    console.log("addAddressToAccessControl")
    //   // whitelist self service so it can mint new editions
    const ROLE_KNOWN_ORIGIN = 1;
    await koda.addAddressToAccessControl(EditionCurationMinter_Addr.address, ROLE_KNOWN_ORIGIN);
  
    // console.log("setAllowedArtist")
    // console.log("SelfServiceAccessControls_Addr:" + SelfServiceAccessControls_Addr.address)
    // let accessControls = new ethers.Contract(SelfServiceAccessControls_Addr.address, SelfServiceAccessControls_ABI.abi , signer) 
    // await accessControls.setAllowedArtist(signer.address, true);
    // let isAritst = await accessControls.isEnabledForAccount(signer.address);
    // console.log("isAritst:" + isAritst);
}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
