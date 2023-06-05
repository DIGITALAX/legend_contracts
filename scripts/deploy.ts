import { run, ethers } from "hardhat";
// import { ethers } from "@nomiclabs/hardhat-etherscan";

const LENS_HUB_PROXY_MATIC: string =
  "0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d";
const LENS_HUB_PROXY_MUMBAI: string =
  "0x60Ae865ee4C725cd04353b5AAb364553f56ceF82";
const KEEPER_REGISTRY_MUMBAI: `0x${string}` =
  "0xE16Df59B887e3Caa439E0b29B42bA2e7976FD8b2";
const KEEPER_REGISTRY_MATIC: `0x${string}` =
  "0x02777053d6764996e594c3E88AF1D58D5363a2e6";
const MUMBAI_LINK_TOKEN: `0x${string}` =
  "0x326C977E6efc84E512bB9C30f76E30c160eD06FB";
const MATIC_LINK_TOKEN: `0x${string}` =
  "0xb0897686c545045aFc77CF20eC7A532E3120E0F1";

const main = async () => {
  try {
    // const GlobalAccessControl = await ethers.getContractFactory(
    //   "GlobalLegendAccessControl"
    // );
    // const LegendEscrow = await ethers.getContractFactory("LegendEscrow");
    // const LegendCollection = await ethers.getContractFactory(
    //   "LegendCollection"
    // );
    // const LegendNFT = await ethers.getContractFactory("LegendNFT");
    // const LegendPayment = await ethers.getContractFactory("LegendPayment");
    // const LegendMarketplace = await ethers.getContractFactory("LegendMarket");
    // const LegendDrop = await ethers.getContractFactory("LegendDrop");
    // const LegendFulfillment = await ethers.getContractFactory(
    //   "LegendFulfillment"
    // );
    // const LegendFactory = await ethers.getContractFactory("LegendFactory");
    const UpkeepIDConsumerExample = await ethers.getContractFactory(
      "UpkeepIDConsumer"
    );

    // deploy
    const upkeepIDConsumerExample = await UpkeepIDConsumerExample.deploy(
      MUMBAI_LINK_TOKEN,
      "0x57A4a13b35d25EE78e084168aBaC5ad360252467",
      KEEPER_REGISTRY_MUMBAI
    );
    // const accessControl = await GlobalAccessControl.deploy(
    //   "GlobalLegendAccessControl",
    //   "GLAC"
    // );
    // const legendFactory = await LegendFactory.deploy(
    //   "LegendFactory",
    //   "LFAC",
    //   accessControl.address
    // );
    // const legendPayment = await LegendPayment.deploy(
    //   "0xC40a180aBa7eE7E49FcfE24d4D654B31cF5400be"
    // );
    // const legendNFT = await LegendNFT.deploy(
    //   "0xC40a180aBa7eE7E49FcfE24d4D654B31cF5400be"
    // );
    // const legendCollection = await LegendCollection.deploy(
    //   "0xb16c46011A2Ff2fE742c34E299099AFaC4b77fa3",
    //   "0xC40a180aBa7eE7E49FcfE24d4D654B31cF5400be",
    //   "0x7DFB2D3ccEb99de8606B275fdABf8b5228CAdEAb",
    //   "0xD026B4E1F9d6dD682faA2a7Fdc6BEcE3D1A557F6",
    //   "LECO",
    //   "LegendCollection"
    // );
    // const legendFulfillment = await LegendFulfillment.deploy(
    //   "0xC40a180aBa7eE7E49FcfE24d4D654B31cF5400be",
    //   "0xb16c46011A2Ff2fE742c34E299099AFaC4b77fa3",
    //   legendCollection.address,
    //   "LEFUL",
    //   "LegendFulfillment"
    // );
    // const legendMarketplace = await LegendMarketplace.deploy(
    //   "0xE11feaB8ddfDCd7C5a1e2Fa68E88cbdA403e4B7F",
    //   "0xC40a180aBa7eE7E49FcfE24d4D654B31cF5400be",
    //   "0xc09F0Ca5EadB895B96F44D575B36Fd62c58768c8",
    //   "0xb16c46011A2Ff2fE742c34E299099AFaC4b77fa3",
    //   "LEMA",
    //   "LegendMarketplace"
    // );
    // const legendDrop = await LegendDrop.deploy(
    //   "0xE11feaB8ddfDCd7C5a1e2Fa68E88cbdA403e4B7F",
    //    "0xC40a180aBa7eE7E49FcfE24d4D654B31cF5400be",
    //   "LEDR",
    //   "LegendDrop"
    // );
    // const legendEscrow = await LegendEscrow.deploy(
    //   "0xE11feaB8ddfDCd7C5a1e2Fa68E88cbdA403e4B7F",
    //   legendMarketplace.address,
    //   "0xC40a180aBa7eE7E49FcfE24d4D654B31cF5400be",
    //   "0xb16c46011A2Ff2fE742c34E299099AFaC4b77fa3",
    //   "LEES",
    //   "LegendEscrow"
    // );

    // await legendFactory.setLensHubProxy(LENS_HUB_PROXY_MUMBAI);
    // await accessControl.addAdmin("0xE11feaB8ddfDCd7C5a1e2Fa68E88cbdA403e4B7F");
    // await legendNFT.setLegendCollection("0xE11feaB8ddfDCd7C5a1e2Fa68E88cbdA403e4B7F");
    // await legendNFT.setLegendEscrow(legendEscrow.address);
    // await legendCollection.setLegendDrop(legendDrop.address);
    // await legendCollection.setLegendFulfillment(legendFulfillment.address);
    // await legendCollection.setLegendEscrow(legendEscrow.address);
    // await legendMarketplace.setLegendEscrow(legendEscrow.address);
    // legendPayment.setVerifiedPaymentTokens([]);
    // legendFulfillment.createFulfiller(20, "0xfa3fea500eeDAa120f7EeC2E4309Fe094F854E61");
    // accessControl.addAdmin(legendFactory.address);

    const WAIT_BLOCK_CONFIRMATIONS = 20;

    // wait confirmations
    await upkeepIDConsumerExample.deployTransaction.wait(
      WAIT_BLOCK_CONFIRMATIONS
    );
    // await accessControl.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    // await legendFactory.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    // await legendPayment.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    // await legendNFT.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    // await legendCollection.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    // await legendFulfillment.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    // await legendMarketplace.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    // await legendDrop.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    // await legendEscrow.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);

    console.log(
      `Upkeep Register deployed at\n${upkeepIDConsumerExample.address}`
    );
    // console.log(
    //   `Global Access Control Contract deployed at\n${accessControl.address}`
    // );
    // console.log(`Factory Contract deployed at\n${legendFactory.address}`);
    // console.log(`Payment Contract deployed at\n${legendPayment.address}`);
    // console.log(`NFT Contract deployed at\n${legendNFT.address}`);
    // console.log(`Collection Contract deployed at\n${legendCollection.address}`);
    // console.log(
    //   `Fulfillment Contract deployed at\n${legendFulfillment.address}`
    // );
    // console.log(`Market Contract deployed at\n${legendMarketplace.address}`);
    // console.log(`Drop Contract deployed at\n${legendDrop.address}`);
    // console.log(`Escrow Contract deployed at\n${legendEscrow.address}`);

    // await run(`verify:verify`, {
    //   address: "0xC40a180aBa7eE7E49FcfE24d4D654B31cF5400be",
    //   constructorArguments: ["GlobalLegendAccessControl", "GLAC"],
    // });
    // await run(`verify:verify`, {
    //   address: "0xD026B4E1F9d6dD682faA2a7Fdc6BEcE3D1A557F6",
    //   constructorArguments: [
    //     "LegendFactory",
    //     "LFAC",
    //     "0xC40a180aBa7eE7E49FcfE24d4D654B31cF5400be",
    //   ],
    // });
    // await run(`verify:verify`, {
    //   address: "0x7DFB2D3ccEb99de8606B275fdABf8b5228CAdEAb",
    //   constructorArguments: ["0xC40a180aBa7eE7E49FcfE24d4D654B31cF5400be"],
    // });
    // await run(`verify:verify`, {
    //   address: "0xb16c46011A2Ff2fE742c34E299099AFaC4b77fa3",
    //   constructorArguments: ["0xC40a180aBa7eE7E49FcfE24d4D654B31cF5400be"],
    // });
    // await run(`verify:verify`, {
    //   address: "0xE11feaB8ddfDCd7C5a1e2Fa68E88cbdA403e4B7F",
    //   constructorArguments: [
    //     "0xb16c46011A2Ff2fE742c34E299099AFaC4b77fa3",
    //     "0xC40a180aBa7eE7E49FcfE24d4D654B31cF5400be",
    //     "0x7DFB2D3ccEb99de8606B275fdABf8b5228CAdEAb",
    //     "0xD026B4E1F9d6dD682faA2a7Fdc6BEcE3D1A557F6",
    //     "LECO",
    //     "LegendCollection",
    //   ],
    // });
    // await run(`verify:verify`, {
    //   address: "0xc09F0Ca5EadB895B96F44D575B36Fd62c58768c8",
    //   constructorArguments: [
    //     "0xC40a180aBa7eE7E49FcfE24d4D654B31cF5400be",
    //     "0xb16c46011A2Ff2fE742c34E299099AFaC4b77fa3",
    //     "0xE11feaB8ddfDCd7C5a1e2Fa68E88cbdA403e4B7F",
    //     "LEFUL",
    //     "LegendFulfillment",
    //   ],
    // });
    // await run(`verify:verify`, {
    //   address: "0x12df1E0166c4abb8aB8df6392eCE253c47E0caa1",
    //   constructorArguments: [
    //     "0xE11feaB8ddfDCd7C5a1e2Fa68E88cbdA403e4B7F",
    //     "0xC40a180aBa7eE7E49FcfE24d4D654B31cF5400be",
    //     "0xc09F0Ca5EadB895B96F44D575B36Fd62c58768c8",
    //     "0xb16c46011A2Ff2fE742c34E299099AFaC4b77fa3",
    //     "LEMA",
    //     "LegendMarketplace",
    //   ],
    // });
    // await run(`verify:verify`, {
    //   address: "0xD9b92636af9028520cb9fC5fC60CecE4F9b754B2",
    //   constructorArguments: [
    //     "0xE11feaB8ddfDCd7C5a1e2Fa68E88cbdA403e4B7F",
    //     "0x12df1E0166c4abb8aB8df6392eCE253c47E0caa1",
    //     "0xC40a180aBa7eE7E49FcfE24d4D654B31cF5400be",
    //     "0xb16c46011A2Ff2fE742c34E299099AFaC4b77fa3",
    //     "LEES",
    //     "LegendEscrow",
    //   ],
    // });
    // await run(`verify:verify`, {
    //   address: "0xCd9aeE9D390609B6F6b569D7C4AD9D4405410770",
    //   constructorArguments: [
    //     "0xE11feaB8ddfDCd7C5a1e2Fa68E88cbdA403e4B7F",
    //     "0xC40a180aBa7eE7E49FcfE24d4D654B31cF5400be",
    //     "LEDR",
    //     "LegendDrop",
    //   ],
    // });
    // await run(`verify:verify`, {
    //   address: "0xC4037066dE8598a58A6543eacc89ce5c05357cC8",
    //   constructorArguments: [MUMBAI_LINK_TOKEN, KEEPER_REGISTRY_MUMBAI],
    // });
  } catch (err: any) {
    console.error(err.message);
  }
};

main();
