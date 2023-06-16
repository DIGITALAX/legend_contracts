import { run } from "hardhat";
// import { ethers } from "@nomiclabs/hardhat-etherscan";

const LENS_HUB_PROXY_MATIC: string =
  "0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d";
const LENS_HUB_PROXY_MUMBAI: string =
  "0x60Ae865ee4C725cd04353b5AAb364553f56ceF82";
const KEEPER_REGISTRY_MUMBAI: `0x${string}` =
  "0xe16df59b887e3caa439e0b29b42ba2e7976fd8b2";
const KEEPER_REGISTRY_MATIC: `0x${string}` =
  "0x02777053d6764996e594c3E88AF1D58D5363a2e6";
const MUMBAI_LINK_TOKEN: `0x${string}` =
  "0x326c977e6efc84e512bb9c30f76e30c160ed06fb";
const MATIC_LINK_TOKEN: `0x${string}` =
  "0xb0897686c545045aFc77CF20eC7A532E3120E0F1";

const main = async () => {
  try {
    // const GlobalAccessControl = await ethers.getContractFactory(
    //   "GlobalLegendAccessControl"
    // );
    // const LegendNFT = await ethers.getContractFactory("LegendNFT");
    // const LegendPayment = await ethers.getContractFactory("LegendPayment");
    // const LegendFactory = await ethers.getContractFactory("LegendFactory");
    // const LegendMarketplace = await ethers.getContractFactory("LegendMarket");
    // const LegendFulfillment = await ethers.getContractFactory(
    //   "LegendFulfillment"
    // );
    // const LegendCollection = await ethers.getContractFactory(
    //   "LegendCollection"
    // );
    // const LegendDrop = await ethers.getContractFactory("LegendDrop");
    // const LegendEscrow = await ethers.getContractFactory("LegendEscrow");

    const UpkeepIDConsumerExample = await ethers.getContractFactory(
      "UpkeepIDConsumer"
    );

    // deploy
    const upkeepIDConsumerExample = await UpkeepIDConsumerExample.deploy(
      MATIC_LINK_TOKEN,
      "0x57A4a13b35d25EE78e084168aBaC5ad360252467",
      KEEPER_REGISTRY_MATIC
    );
    // const accessControl = await GlobalAccessControl.deploy(
    //   "GlobalLegendAccessControl",
    //   "GLAC"
    // );
    // const legendFactory = await LegendFactory.deploy(
    //   "LegendFactory",
    //   "LFAC",
    //   "0xBB5FaA448C3bc59497cDebc33e62a3eE8A90be8C"
    // );
    // const legendPayment = await LegendPayment.deploy(accessControl.address);
    // const legendNFT = await LegendNFT.deploy(accessControl.address);
    // const legendCollection = await LegendCollection.deploy(
    //   "0x115655bDd3CCf1979205A14796CD88DCBD362D7a",
    //   "0xBB5FaA448C3bc59497cDebc33e62a3eE8A90be8C",
    //   "0xb619Ac757cE3230FB996DA5899dD692B6299DFFc",
    //   "0x0BD3C2a88A729c5f02276b7987A5922A12f465eB",
    //   "LECO",
    //   "LegendCollection"
    // );
    // const legendFulfillment = await LegendFulfillment.deploy(
    //   "0xBB5FaA448C3bc59497cDebc33e62a3eE8A90be8C",
    //   "0x115655bDd3CCf1979205A14796CD88DCBD362D7a",
    //   legendCollection.address,
    //   "LEFUL",
    //   "LegendFulfillment"
    // );
    // const legendMarketplace = await LegendMarketplace.deploy(
    //   legendCollection.address,
    //   "0xBB5FaA448C3bc59497cDebc33e62a3eE8A90be8C",
    //   legendFulfillment.address,
    //   "0x115655bDd3CCf1979205A14796CD88DCBD362D7a",
    //   "LEMA",
    //   "LegendMarketplace"
    // );
    // const legendDrop = await LegendDrop.deploy(
    //   "0xA3C2F7ba49513Ae46d44D074679f52cAEF7E721B",
    //   "0xBB5FaA448C3bc59497cDebc33e62a3eE8A90be8C",
    //   "LEDR",
    //   "LegendDrop"
    // );
    // const legendEscrow = await LegendEscrow.deploy(
    //   "0xA3C2F7ba49513Ae46d44D074679f52cAEF7E721B",
    //   "0xd68E8FD1dffC8F09b27b2973d06027D9E96e9d20",
    //   "0xBB5FaA448C3bc59497cDebc33e62a3eE8A90be8C",
    //   "0x115655bDd3CCf1979205A14796CD88DCBD362D7a",
    //   "LEES",
    //   "LegendEscrow"
    // );

    // await legendFactory.setLensHubProxy(LENS_HUB_PROXY_MUMBAI);
    // await accessControl.addAdmin(legendCollection.address);
    // await legendNFT.setLegendCollection(legendCollection.address);
    // await legendNFT.setLegendEscrow(legendEscrow.address);
    // await legendCollection.setLegendDrop(legendDrop.address);
    // await legendCollection.setLegendFulfillment(legendFulfillment.address);
    // await legendCollection.setLegendEscrow(legendEscrow.address);
    // await legendMarketplace.setLegendEscrow(legendEscrow.address);
    // legendPayment.setVerifiedPaymentTokens([
    //   "0x6199A505ec1707695Ce49b59A07A147f2d50f22D",
    //   "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619",
    //   "0xc2132D05D31c914a87C6611C10748AEb04B58e8F",
    //   "0x6968105460f67c3BF751bE7C15f92F5286Fd0CE5",
    // ]);
    // legendFulfillment.createFulfiller(
    //   20,
    //   "0xfa3fea500eeDAa120f7EeC2E4309Fe094F854E61"
    // );
    // accessControl.addAdmin("0x0BD3C2a88A729c5f02276b7987A5922A12f465eB");

    const WAIT_BLOCK_CONFIRMATIONS = 20;

    // wait confirmations
    // await upkeepIDConsumerExample.deployTransaction.wait(
    //   WAIT_BLOCK_CONFIRMATIONS
    // );
    // await accessControl.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    // await legendFactory.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    // await legendPayment.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    // await legendNFT.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    // await legendCollection.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    // await legendFulfillment.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    // await legendMarketplace.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    // await legendDrop.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    // await legendEscrow.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);

    // console.log(
    //   `Upkeep Register deployed at\n${upkeepIDConsumerExample.address}`
    // );
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
    //   address: "0xBB5FaA448C3bc59497cDebc33e62a3eE8A90be8C",
    //   constructorArguments: ["GlobalLegendAccessControl", "GLAC"],
    // });
    // await run(`verify:verify`, {
    //   address: "0x3723387De6d07A7da332f0FeD7a4d0e11845d2c3",
    //   constructorArguments: [
    //     "LegendFactory",
    //     "LFAC",
    //     "0xBB5FaA448C3bc59497cDebc33e62a3eE8A90be8C",
    //   ],
    // });
    // await run(`verify:verify`, {
    //   address: "0x86252789Adf119290Bb20DC0047d5cd4FdD6E213",
    //   constructorArguments: ["0xBB5FaA448C3bc59497cDebc33e62a3eE8A90be8C"],
    // });
    // await run(`verify:verify`, {
    //   address: "0x115655bDd3CCf1979205A14796CD88DCBD362D7a",
    //   constructorArguments: ["0xBB5FaA448C3bc59497cDebc33e62a3eE8A90be8C"],
    // });
    // await run(`verify:verify`, {
    //   address: "0xA3C2F7ba49513Ae46d44D074679f52cAEF7E721B",
    //   constructorArguments: [
    //   "0x115655bDd3CCf1979205A14796CD88DCBD362D7a",
    //   "0xBB5FaA448C3bc59497cDebc33e62a3eE8A90be8C",
    //   "0xb619Ac757cE3230FB996DA5899dD692B6299DFFc",
    //   "0x0BD3C2a88A729c5f02276b7987A5922A12f465eB",
    //   "LECO",
    //   "LegendCollection"
    //   ],
    // });
    // await run(`verify:verify`, {
    //   address: "0x88fa5a97345ba5e827Cf32F437f46449C5D68754",
    //   constructorArguments: [
    //    "0xBB5FaA448C3bc59497cDebc33e62a3eE8A90be8C",
    //   "0x115655bDd3CCf1979205A14796CD88DCBD362D7a",
    //   "0xA3C2F7ba49513Ae46d44D074679f52cAEF7E721B",
    //   "LEFUL",
    //   "LegendFulfillment"
    //   ],
    // });
    // await run(`verify:verify`, {
    //   address: "0xd68E8FD1dffC8F09b27b2973d06027D9E96e9d20",
    //   constructorArguments: [
    //   "0xA3C2F7ba49513Ae46d44D074679f52cAEF7E721B",
    //   "0xBB5FaA448C3bc59497cDebc33e62a3eE8A90be8C",
    //   "0x88fa5a97345ba5e827Cf32F437f46449C5D68754",
    //   "0x115655bDd3CCf1979205A14796CD88DCBD362D7a",
    //   "LEMA",
    //   "LegendMarketplace"
    //   ],
    // });
    // await run(`verify:verify`, {
    //   address: "0x8FD5F1a77967e881868C8b81e779Fd8C29aEEB8e",
    //   constructorArguments: [
    //   "0xA3C2F7ba49513Ae46d44D074679f52cAEF7E721B",
    //   "0xd68E8FD1dffC8F09b27b2973d06027D9E96e9d20",
    //   "0xBB5FaA448C3bc59497cDebc33e62a3eE8A90be8C",
    //   "0x115655bDd3CCf1979205A14796CD88DCBD362D7a",
    //   "LEES",
    //   "LegendEscrow"
    //   ],
    // });
    // await run(`verify:verify`, {
    //   address: "0xb01F35968e7D204521adB7dDd81e9F69bC99fDF4",
    //   constructorArguments: [
    //   "0xA3C2F7ba49513Ae46d44D074679f52cAEF7E721B",
    //   "0xBB5FaA448C3bc59497cDebc33e62a3eE8A90be8C",
    //   "LEDR",
    //   "LegendDrop"
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
