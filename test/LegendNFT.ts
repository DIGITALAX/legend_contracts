import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";

let 
legendEscrow: Contract,
legendCollection: Contract,
legendNFT: Contract,
legendMarketplace: Contract,
legendDrop: Contract,
legendPayment: Contract,
deployer: SignerWithAddress,
writer: SignerWithAddress,
admin: SignerWithAddress;