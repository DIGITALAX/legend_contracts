// test/LegendDynamicNFT.spec.ts

import { ethers } from "hardhat";
import { Contract, Signer, constants } from "ethers";
import { solidity } from "ethereum-waffle";
import chai from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

chai.use(solidity);
const { expect } = chai;

describe("LegendKeeper", function () {
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
      deployerAddressValue: deployer.address,
      URIArrayValue: URIArray,
      grantNameValue: grantName,
      editionAmountValue: editionAmount,
    };

    const tx = await legendFactory.createContracts(pubId, profileId, myStruct);
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
      expect(await legendKeeper.getDeployerAddress()).to.equal(
        deployer.address
      );
    });

    it("should set the correct edition amount", async () => {
      expect(await legendKeeper.getEditionAmount()).to.equal(editionAmount);
    });

    it("should set the dynamic NFT address", async () => {
      expect(await legendKeeper.getDynamicNFTAddress()).to.equal(
        legendDynamicNFT.address
      );
    });

    it("should set the access control address", async () => {
      expect(await legendKeeper.getAccessControlAddress()).to.equal(
        legendAccessControl.address
      );
    });

    it("should set the correct profileId", async () => {
      expect(await legendKeeper.getProfileId()).to.equal(profileId);
    });

    it("should set the correct pubId", async () => {
      expect(await legendKeeper.getPostId()).to.equal(pubId);
    });
  });
});

// test live the update metadata & collector mint & collector address
