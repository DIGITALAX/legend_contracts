import { ethers } from "hardhat";

const LENS_HUB_PROXY: string = "0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d";
const EDITION_AMOUNT: number = 1000;
const URI_VALUES: string[] = [""];

const main = async () => {
  try {
    const Factory = await ethers.getContractFactory("LegendFactory");

    const factory = await Factory.deploy(
      EDITION_AMOUNT,
      LENS_HUB_PROXY,
      "LegendKeeper",
      "LKEEP",
      URI_VALUES,
      "LegendAccessControl",
      "LAC"
    );

    const WAIT_BLOCK_CONFIRMATIONS = 20;

    factory.deployTransaction.wait(WAIT_BLOCK_CONFIRMATIONS);

    console.log(`Factory Contract deployed at\n${factory.address}`);

    // await run(`verify:verify`, {
    //   address: "",
    //   constructorArguments: [""],
    // });
  } catch (err: any) {
    console.error(err.message);
  }
};

main();
