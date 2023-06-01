import { ethers } from "hardhat";
import { Contract } from "ethers";
import { solidity } from "ethereum-waffle";
import chai from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
chai.use(solidity);
const { expect } = chai;

describe("LegendFactory", function () {
  let legendFactory: Contract,
    globalLegendAccessControl: Contract,
    deployer: SignerWithAddress,
    writer: SignerWithAddress,
    admin: SignerWithAddress,
    editionAmount: number,
    pubId: number,
    profileId: number,
    grantName: string,
    URIValues: string[],
    timestamp: number,
    legendAccessControl: Contract,
    legendDynamicNFT: Contract,
    legendKeeper: Contract;

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

    await globalLegendAccessControl.addAdmin(legendFactory.address);

    pubId = 8199;
    profileId = 81992;
    editionAmount = 100;
    grantName = "TestGrant";
    URIValues = [
      "text1",
      "text2",
      "text3",
      "text1",
      "text2",
      "text3",
      "text1",
      "text2",
      "text3",
      "text1",
      "text2",
      "text3",
    ];

    const myStruct = {
      lensHubProxyAddress: legendFactory.address,
      legendFactoryAddress: legendFactory.address,
      URIArrayValue: URIValues,
      grantNameValue: grantName,
      editionAmountValue: editionAmount,
    };

    const tx = await legendFactory
      .connect(writer)
      .createContracts(pubId, profileId, myStruct);
    const receipt = await tx.wait();

    const event = receipt.events.find(
      (event: any) => event.event === "FactoryDeployed"
    );
    timestamp = (await ethers.provider.getBlock(receipt.blockNumber)).timestamp;

    const eventData = await event.args;

    legendDynamicNFT = LegendDynamicNFT.attach(eventData.dynamicNFTAddress);
    legendKeeper = LegendKeeper.attach(eventData.keeperAddress);
    legendAccessControl = LegendAccessControl.attach(
      eventData.accessControlAddress
    );
  });

  describe("createContracts", async () => {
    it("verifies writer length", async () => {
      const deployedLegendKeepers =
        await legendFactory.getDeployedLegendKeepers(writer.address);
      const deployedLegendAccessControls =
        await legendFactory.getDeployedLegendAccessControls(writer.address);
      const deployedLegendDynamicNFTs =
        await legendFactory.getDeployedLegendDynamicNFTs(writer.address);

      expect(deployedLegendKeepers).to.have.lengthOf(1);
      expect(deployedLegendAccessControls).to.have.lengthOf(1);
      expect(deployedLegendDynamicNFTs).to.have.lengthOf(1);
    });

    beforeEach(
      "should create and deploy LegendKeeper, LegendAccessControl, and LegendDynamicNFT contracts",
      async () => {
        const pubId = 8199;
        const profileId = 81992;
        editionAmount = 100;
        const grantName = "TestGrant";
        const URIValues = [
          "text1",
          "text2",
          "text3",
          "text1",
          "text2",
          "text3",
          "text1",
          "text2",
          "text3",
          "text1",
          "text2",
          "text3",
        ];

        const myStruct = {
          lensHubProxyAddress: legendFactory.address,
          legendFactoryAddress: legendFactory.address,
          URIArrayValue: URIValues,
          grantNameValue: grantName,
          editionAmountValue: editionAmount,
        };
        const tx = await legendFactory
          .connect(deployer)
          .createContracts(pubId, profileId, myStruct);
        const receipt = await tx.wait();
        const actualTimestamp = (
          await ethers.provider.getBlock(receipt.blockNumber)
        ).timestamp;

        expect(tx)
          .to.emit(legendFactory, "FactoryDeployed")
          .withArgs(
            (
              await legendFactory.getDeployedLegendKeepers(deployer.address)
            ).slice(-1)[0],
            (
              await legendFactory.getDeployedLegendAccessControls(
                deployer.address
              )
            ).slice(-1)[0],
            (
              await legendFactory.getDeployedLegendDynamicNFTs(deployer.address)
            ).slice(-1)[0],
            grantName,
            deployer.address,
            actualTimestamp
          );
      }
    );

    it("verify mappings", async () => {
      const deployedLegendKeepers =
        await legendFactory.getDeployedLegendKeepers(deployer.address);
      const deployedLegendAccessControls =
        await legendFactory.getDeployedLegendAccessControls(deployer.address);
      const deployedLegendDynamicNFTs =
        await legendFactory.getDeployedLegendDynamicNFTs(deployer.address);

      expect(deployedLegendKeepers).to.have.lengthOf(1);
      expect(deployedLegendAccessControls).to.have.lengthOf(1);
      expect(deployedLegendDynamicNFTs).to.have.lengthOf(1);
    });

    it("verify mappings updated", async () => {
      const pubId = 8199;
      const profileId = 81992;
      const editionAmount = 100;
      const grantName = "HelloAgain";
      const URIValues = [
        "text1",
        "text2",
        "text3",
        "text1",
        "text2",
        "text3",
        "text1",
        "text2",
        "text3",
        "text1",
        "text2",
        "text3",
      ];

      const myStruct = {
        lensHubProxyAddress: legendFactory.address,
        legendFactoryAddress: legendFactory.address,
        URIArrayValue: URIValues,
        grantNameValue: grantName,
        editionAmountValue: editionAmount,
      };

      await legendFactory
        .connect(deployer)
        .createContracts(pubId, profileId, myStruct);

      const deployedLegendKeepers =
        await legendFactory.getDeployedLegendKeepers(deployer.address);
      const deployedLegendAccessControls =
        await legendFactory.getDeployedLegendAccessControls(deployer.address);
      const deployedLegendDynamicNFTs =
        await legendFactory.getDeployedLegendDynamicNFTs(deployer.address);

      expect(deployedLegendKeepers).to.have.lengthOf(2);
      expect(deployedLegendAccessControls).to.have.lengthOf(2);
      expect(deployedLegendDynamicNFTs).to.have.lengthOf(2);
    });

    it("cannot redeploy with the same grant name", async () => {
      const pubId = 8199;
      const profileId = 81992;
      const editionAmount = 100;
      const grantName = "TestGrant";
      const URIValues = [
        "text1",
        "text2",
        "text3",
        "text1",
        "text2",
        "text3",
        "text1",
        "text2",
        "text3",
        "text1",
        "text2",
        "text3",
      ];

      const myStruct = {
        lensHubProxyAddress: legendFactory.address,
        legendFactoryAddress: legendFactory.address,
        URIArrayValue: URIValues,
        grantNameValue: grantName,
        editionAmountValue: editionAmount,
      };
      await expect(
        legendFactory
          .connect(writer)
          .createContracts(pubId, profileId, myStruct)
      ).to.be.revertedWith("LegendFactory: Grant Name must be unique.");
    });

    it("can redeploy with the same grant name if different sender", async () => {
      const pubId = 8199;
      const profileId = 81992;
      const editionAmount = 100;
      const grantName = "HelloAgain";
      const URIValues = [
        "text1",
        "text2",
        "text3",
        "text1",
        "text2",
        "text3",
        "text1",
        "text2",
        "text3",
        "text1",
        "text2",
        "text3",
      ];

      const myStruct = {
        lensHubProxyAddress: legendFactory.address,
        legendFactoryAddress: legendFactory.address,
        URIArrayValue: URIValues,
        grantNameValue: grantName,
        editionAmountValue: editionAmount,
      };

      const tx = await legendFactory
        .connect(writer)
        .createContracts(pubId, profileId, myStruct);
      const receipt = await tx.wait();
      const actualTimestamp = (
        await ethers.provider.getBlock(receipt.blockNumber)
      ).timestamp;

      expect(tx)
        .to.emit(legendFactory, "FactoryDeployed")
        .withArgs(
          (await legendFactory.getDeployedLegendKeepers(writer.address)).slice(
            -1
          )[0],
          (
            await legendFactory.getDeployedLegendAccessControls(writer.address)
          ).slice(-1)[0],
          (
            await legendFactory.getDeployedLegendDynamicNFTs(writer.address)
          ).slice(-1)[0],
          grantName,
          writer.address,
          actualTimestamp
        );
    });
  });

  it("check values correctly associated in deployed contracts", async () => {
    expect(await legendKeeper.getDeployerAddress()).to.equal(writer.address);
    expect(await legendDynamicNFT.getDeployerAddress()).to.equal(
      writer.address
    );
    expect(await legendKeeper.getEditionAmount()).to.equal(editionAmount);
    expect(await legendDynamicNFT.getEditionAmount()).to.equal(editionAmount);

    expect(await legendKeeper.getDynamicNFTAddress()).to.equal(
      legendDynamicNFT.address
    );
    expect(await legendKeeper.getAccessControlAddress()).to.equal(
      legendAccessControl.address
    );
    expect(await legendDynamicNFT.getLegendKeeperAddress()).to.equal(
      legendKeeper.address
    );
    expect(await legendDynamicNFT.getLegendAccessControlAddress()).to.equal(
      legendAccessControl.address
    );
  });

  describe("check access controls", () => {
    it("verify access controls", async () => {
      expect(await legendFactory.getAccessControlContract()).to.equal(
        globalLegendAccessControl.address
      );
    });

    it("only admin can update access controls", async () => {
      await expect(
        legendFactory
          .connect(writer)
          .setAccessControl(globalLegendAccessControl.address)
      ).to.be.revertedWith(
        "GlobalLegendAccessControl: Only admin can perform this action"
      );
    });

    it("admin can update access controls", async () => {
      const LegendGlobalAccess = await ethers.getContractFactory(
        "GlobalLegendAccessControl"
      );

      const newGlobalLegendAccessControl = await LegendGlobalAccess.deploy(
        "GlobalLegendAccessControl",
        "GLAC"
      );

      expect(
        await legendFactory.setAccessControl(
          newGlobalLegendAccessControl.address
        )
      )
        .to.emit(legendFactory, "AccessControlSet")
        .withArgs(
          globalLegendAccessControl.address,
          newGlobalLegendAccessControl.address,
          admin.address
        );

      expect(await legendFactory.getAccessControlContract()).to.equal(
        newGlobalLegendAccessControl.address
      );
    });
  });

  describe("check grant variables", () => {
    it("returns the grant name", async () => {
      expect(
        await legendFactory.getGrantName(writer.address, grantName)
      ).to.equal(grantName);
    });

    it("returns the grant contracts", async () => {
      expect(
        await legendFactory.getGrantContracts(writer.address, grantName)
      ).to.deep.equal([
        legendKeeper.address,
        legendAccessControl.address,
        legendDynamicNFT.address,
      ]);
    });

    it("returns the grant timestamp", async () => {
      expect(
        await legendFactory.getGrantTimestamp(writer.address, grantName)
      ).to.equal(timestamp);
    });

    it("returns the grant status", async () => {
      expect(
        await legendFactory.getGrantStatus(writer.address, grantName)
      ).to.equal("live");
    });

    it("only deployer can update the grant status", async () => {
      await expect(
        legendFactory.setGrantStatus(writer.address, "finished", grantName)
      ).to.be.revertedWith(
        "LegendFactory: Only the Dynamic NFT Address can update the grant status"
      );
    });
  });
});
