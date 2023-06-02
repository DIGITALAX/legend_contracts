import { ethers, run } from "hardhat";

const LENS_HUB_PROXY: string = "0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d";

const main = async () => {
  try {
    const GlobalAccessControl = await ethers.getContractFactory(
      "GlobalLegendAccessControl"
    );
    const LegendEscrow = await ethers.getContractFactory("LegendEscrow");
    const LegendCollection = await ethers.getContractFactory(
      "LegendCollection"
    );
    const LegendNFT = await ethers.getContractFactory("LegendNFT");
    const LegendPayment = await ethers.getContractFactory("LegendPayment");
    const LegendMarketplace = await ethers.getContractFactory("LegendMarket");
    const LegendDrop = await ethers.getContractFactory("LegendDrop");
    const LegendFulfillment = await ethers.getContractFactory(
      "LegendFulfillment"
    );
    const LegendFactory = await ethers.getContractFactory("LegendFactory");

    // deploy
    const accessControl = await GlobalAccessControl.deploy(
      "GlobalLegendAccessControl",
      "GLAC"
    );
    const legendFactory = await LegendFactory.deploy(
      "LegendFactory",
      "LFAC",
      accessControl.address
    );
    const legendPayment = await LegendPayment.deploy(accessControl.address);
    const legendNFT = await LegendNFT.deploy(accessControl.address);
    const legendCollection = await LegendCollection.deploy(
      legendNFT.address,
      accessControl.address,
      legendPayment.address,
      legendFactory.address,
      "LECO",
      "LegendCollection"
    );
    const legendFulfillment = await LegendFulfillment.deploy(
      accessControl.address,
      legendNFT.address,
      legendCollection.address,
      "LEFUL",
      "LegendFulfillment"
    );
    const legendMarketplace = await LegendMarketplace.deploy(
      legendCollection.address,
      accessControl.address,
      legendFulfillment.address,
      legendNFT.address,
      "LEMA",
      "LegendMarketplace"
    );
    const legendDrop = await LegendDrop.deploy(
      legendCollection.address,
      accessControl.address,
      "LEDR",
      "LegendDrop"
    );
    const legendEscrow = await LegendEscrow.deploy(
      legendCollection.address,
      legendMarketplace.address,
      accessControl.address,
      legendNFT.address,
      "LEES",
      "LegendEscrow"
    );

    await legendFactory.setLensHubProxy(LENS_HUB_PROXY);
    await accessControl.addAdmin(legendCollection.address);
    await legendNFT.setLegendCollection(legendCollection.address);
    await legendNFT.setLegendEscrow(legendEscrow.address);
    await legendCollection.setLegendDrop(legendDrop.address);
    await legendCollection.setLegendFulfillment(legendFulfillment.address);
    await legendCollection.setLegendEscrow(legendEscrow.address);
    await legendMarketplace.setLegendEscrow(legendEscrow.address);
    legendPayment.setVerifiedPaymentTokens([]);
    legendFulfillment.createFulfiller(20, "");
    accessControl.addAdmin(legendFactory.address);

    const WAIT_BLOCK_CONFIRMATIONS = 20;

    // wait confirmations
    await accessControl.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    await legendFactory.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    await legendPayment.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    await legendNFT.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    await legendCollection.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    await legendFulfillment.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    await legendMarketplace.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    await legendDrop.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);
    await legendEscrow.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);

    console.log(
      `Global Access Control Contract deployed at\n${accessControl.address}`
    );
    console.log(`Factory Contract deployed at\n${legendFactory.address}`);
    console.log(`Payment Contract deployed at\n${legendPayment.address}`);
    console.log(`NFT Contract deployed at\n${legendNFT.address}`);
    console.log(`Collection Contract deployed at\n${legendCollection.address}`);
    console.log(
      `Fulfillment Contract deployed at\n${legendFulfillment.address}`
    );
    console.log(`Market Contract deployed at\n${legendMarketplace.address}`);
    console.log(`Drop Contract deployed at\n${legendDrop.address}`);
    console.log(`Escrow Contract deployed at\n${legendEscrow.address}`);

    await run(`verify:verify`, {
      address: accessControl.address,
      constructorArguments: ["GlobalLegendAccessControl", "GLAC"],
    });
    await run(`verify:verify`, {
      address: legendFactory.address,
      constructorArguments: ["LegendFactory", "LFAC", accessControl.address],
    });
    await run(`verify:verify`, {
      address: legendPayment.address,
      constructorArguments: [accessControl.address],
    });
    await run(`verify:verify`, {
      address: legendNFT.address,
      constructorArguments: [accessControl.address],
    });
    await run(`verify:verify`, {
      address: legendCollection.address,
      constructorArguments: [
        legendNFT.address,
        accessControl.address,
        legendPayment.address,
        legendFactory.address,
        "LECO",
        "LegendCollection",
      ],
    });
    await run(`verify:verify`, {
      address: legendFulfillment.address,
      constructorArguments: [
        accessControl.address,
        legendNFT.address,
        legendCollection.address,
        "LEFUL",
        "LegendFulfillment",
      ],
    });
    await run(`verify:verify`, {
      address: legendMarketplace.address,
      constructorArguments: [
        legendCollection.address,
        accessControl.address,
        legendFulfillment.address,
        legendNFT.address,
        "LEMA",
        "LegendMarketplace",
      ],
    });
    await run(`verify:verify`, {
      address: legendEscrow.address,
      constructorArguments: [
        legendCollection.address,
        legendMarketplace.address,
        accessControl.address,
        legendNFT.address,
        "LEES",
        "LegendEscrow",
      ],
    });
    await run(`verify:verify`, {
      address: legendDrop.address,
      constructorArguments: [
        legendCollection.address,
        accessControl.address,
        "LEDR",
        "LegendDrop",
      ],
    });
  } catch (err: any) {
    console.error(err.message);
  }
};

main();
