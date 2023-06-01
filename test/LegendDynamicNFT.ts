// test/LegendDynamicNFT.spec.ts

import { ethers } from "hardhat";
import { Contract } from "ethers";
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
  const profileId = 81992;

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

    legendFactory = await LegendFactory.deploy(
      "LegendFactory",
      "LFAC",
      globalLegendAccessControl.address
    );

    globalLegendAccessControl.addAdmin(legendFactory.address);

    const myStruct = {
      lensHubProxyAddress: legendFactory.address,
      legendFactoryAddress: legendFactory.address,
      URIArrayValue: URIArray,
      grantNameValue: grantName,
      editionAmountValue: editionAmount,
    };

    const tx = await legendFactory.connect(deployer).createContracts(pubId, profileId, myStruct);
    const receipt = await tx.wait();

    const event = receipt.events.find(
      (event: any) => event.event === "FactoryDeployed"
    );

    const eventData = await event.args;

    legendDynamicNFT = LegendDynamicNFT.attach(eventData.dynamicNFTAddress);
    legendKeeper = LegendKeeper.attach(eventData.keeperAddress);
    legendAccessControl = LegendAccessControl.attach(
      eventData.accessControlAddress
    );
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

    it("should set the keeper address", async () => {
      expect(await legendDynamicNFT.getLegendKeeperAddress()).to.equal(
        legendKeeper.address
      );
    });

    it("should set the access control address", async () => {
      expect(await legendDynamicNFT.getLegendAccessControlAddress()).to.equal(
        legendAccessControl.address
      );
    });
  });
});

// test live the update metadata & collector mint & collector address
// updates the grant status