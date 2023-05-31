// test/LegendDynamicNFT.spec.ts

import { ethers } from "hardhat";
import { Contract, Signer, constants } from "ethers";
import { solidity } from "ethereum-waffle";
import chai from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

chai.use(solidity);
const { expect } = chai;

describe("LegendDynamicNFT", function () {
  let legendAccessControl: Contract,
    legendDynamicNFT: Contract,
    legendKeeper: Contract,
    legendFactory: Contract,
    globalLegendAccessControl: Contract,
    deployer: SignerWithAddress,
    writer: SignerWithAddress,
    admin: SignerWithAddress;

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

    const LegendGlobalAccess = await ethers.getContractFactory(
      "GlobalLegendAccessControl"
    );
    const LegendFactory = await ethers.getContractFactory("LegendFactory");
    const LegendAccessControl = await ethers.getContractFactory(
      "LegendAccessControl"
    );
    const LegendDynamicNFT = await ethers.getContractFactory(
      "LegendDynamicNFT"
    );
    const LegendKeeper = await ethers.getContractFactory("LegendKeeper");

    globalLegendAccessControl = await LegendGlobalAccess.deploy(
      "GlobalLegendAccessControl",
      "GLAC"
    );

    legendAccessControl = await LegendAccessControl.deploy(
      "LegendAccessControl",
      "LAC",
      deployer.address
    );

    legendFactory = await LegendFactory.deploy(
      "LegendFactory",
      "LFAC",
      globalLegendAccessControl.address
    );

    globalLegendAccessControl.addAdmin(legendFactory.address);

    const myStruct = {
      legendAccessControlAddress: legendAccessControl.address,
      lensHubProxyAddress: legendAccessControl.address,
      legendFactoryAddress: legendFactory.address,
      deployerAddressValue: deployer.address,
      URIArrayValue: URIArray,
      grantNameValue: grantName,
      editionAmountValue: editionAmount,
    };

    const tx = await legendFactory.createContracts(pubId, myStruct);
    const receipt = await tx.wait();

    const event = receipt.events.find(
      (event: any) => event.event === "FactoryDeployed"
    );

    const eventData = await event.args;

    legendDynamicNFT = LegendDynamicNFT.attach(
      eventData.dynamicNFTAddress
    );
    legendKeeper = LegendKeeper.attach(eventData.keeperAddress);

    legendDynamicNFT
      .connect(deployer)
      .setLegendKeeperContract(legendKeeper.address);
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
          .connect(admin)
          .setLegendKeeperContract(legendKeeper.address)
      ).to.be.revertedWith(
        "LegendAccessControl: Only admin can perform this action"
      );
    });

    it("should only allow admin to set keeper contract", async () => {
      expect(await legendDynamicNFT.getLegendKeeperAddress()).to.equal(
        legendKeeper.address
      );

      const LegendKeeper = await ethers.getContractFactory("LegendKeeper");

      const newLegendKeeper = await LegendKeeper.deploy(
        editionAmount,
        pubId,
        legendDynamicNFT.address,
        legendDynamicNFT.address,
        legendAccessControl.address,
        "LegendKeeper",
        "LKEEP"
      );
      await legendDynamicNFT
        .connect(deployer)
        .setLegendKeeperContract(newLegendKeeper.address);

      expect(await legendDynamicNFT.getLegendKeeperAddress()).to.equal(
        newLegendKeeper.address
      );
    });
  });
});

// test live the update metadata & collector mint & collector address
