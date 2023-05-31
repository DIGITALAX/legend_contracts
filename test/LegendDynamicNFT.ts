// test/LegendDynamicNFT.spec.ts

import { ethers } from "hardhat";
import { Contract, Signer, constants } from "ethers";
import { solidity } from "ethereum-waffle";
import chai from "chai";

chai.use(solidity);
const { expect } = chai;

describe("LegendDynamicNFT", function () {
  let legendAccessControl: any,
    legendDynamicNFT: any,
    legendKeeper: any,
    legendEscrow: any,
    legendCollection: any,
    legendNFT: any,
    legendMarketplace: any,
    legendDrop: any,
    legendPayment: any,
    deployer: any,
    writer: any,
    admin: any;

  const URIArray = [
    "http://example.com/metadata/1",
    "http://example.com/metadata/2",
    "http://example.com/metadata/1",
    "http://example.com/metadata/2",
    "http://example.com/metadata/1",
    "http://example.com/metadata/2",
    "http://example.com/metadata/1",
    "http://example.com/metadata/2",
    "http://example.com/metadata/1",
    "http://example.com/metadata/2",
    "http://example.com/metadata/1",
    "http://example.com/metadata/2",
  ];
  const grantName = "TestGrant";
  const editionAmount = 100;
  const pubId = 8199;

  beforeEach(async () => {
    [admin, deployer, writer] = await ethers.getSigners();

    const LegendAccessControl = await ethers.getContractFactory(
      "LegendAccessControl"
    );
    const LegendDynamicNFT = await ethers.getContractFactory(
      "LegendDynamicNFT"
    );
    const LegendKeeper = await ethers.getContractFactory("LegendKeeper");

    legendAccessControl = await LegendAccessControl.deploy();

    legendDynamicNFT = await LegendDynamicNFT.deploy(
      legendAccessControl.address, // _legendAccessControlAddress
      "", // _lensHubProxyAddress
      "", // _legendFactoryAddress
      deployer.address, // _deployerAddressValue
      URIArray,
      grantName,
      editionAmount
    );

    legendKeeper = await LegendKeeper.deploy(
      editionAmount,
      pubId,
      "",
      legendDynamicNFT.address,
      legendAccessControl.address,
      "LegendKeeper",
      "LKEEP"
    );

    legendDynamicNFT.setLegendKeeperContract(legendKeeper.address);
  });

  describe("deployment", async () => {
    it("should set the right deployer", async () => {
      expect(await legendDynamicNFT.getDeployerAddress()).to.equal(
        deployer.address
      );
    });

    it("should set the correct base URI", async () => {
      expect(await legendDynamicNFT.tokenURI(0)).to.equal(URIArray[0]);
    });

    it("should set the correct grant name", async () => {
      expect(await legendDynamicNFT.getGrantName()).to.equal(grantName);
    });

    it("should set the correct edition amount", async () => {
      expect(await legendDynamicNFT.getEditionAmount()).to.equal(editionAmount);
    });

    it("should set the correct max supply", async () => {
      expect(await legendDynamicNFT.getMaxSupply()).to.equal(editionAmount);
    });

    it("should set the current counter to 0", async () => {
      expect(await legendDynamicNFT.getCurrentCounter()).to.equal(0);
    });
  });

  describe("setLegendKeeperContract", async () => {
    it("should not allow non-admin to set keeper contract", async () => {
      await expect(
        legendDynamicNFT
          .connect(writer)
          .setLegendKeeperContract(legendKeeper.address)
      ).to.be.revertedWith(
        "LegendAccessControl: Only admin can perform this action"
      );
    });

    it("should not allow admin to set keeper contract", async () => {
      expect(await legendDynamicNFT.getLegendKeeper()).to.equal(
        legendKeeper.address
      );

      const LegendKeeper = await ethers.getContractFactory("LegendKeeper");

      const newLegendKeeper = await LegendKeeper.deploy(
        editionAmount,
        pubId,
        "",
        legendDynamicNFT.address,
        legendAccessControl.address,
        "LegendKeeper",
        "LKEEP"
      );
      await legendDynamicNFT
        .connect(admin)
        .setLegendKeeperContract(newLegendKeeper.address);

      expect(await legendDynamicNFT.getLegendKeeper()).to.equal(
        newLegendKeeper.address
      );
    });
  });
});

// test live the update metadata & collector mint & collector address
