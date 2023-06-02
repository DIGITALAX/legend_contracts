import { ethers } from "hardhat";
import { BigNumber, Contract } from "ethers";
import { solidity } from "ethereum-waffle";
import chai from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
chai.use(solidity);
const { expect } = chai;

xdescribe("LegendFulfillment", () => {
  let accessControl: Contract,
    legendEscrow: Contract,
    legendCollection: Contract,
    legendFactory: Contract,
    legendFulfillment: Contract,
    legendNFT: Contract,
    legendMarketplace: Contract,
    legendDrop: Contract,
    legendDynamicNFT: Contract,
    legendPayment: Contract,
    admin: SignerWithAddress,
    writer: SignerWithAddress,
    nonAdmin: SignerWithAddress,
    fulfiller: SignerWithAddress,
    secondWriter: SignerWithAddress,
    token: Contract;

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
    [admin, writer, nonAdmin, fulfiller, secondWriter] =
      await ethers.getSigners();
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
    const LegendDynamicNFT = await ethers.getContractFactory(
      "LegendDynamicNFT"
    );

    accessControl = await GlobalAccessControl.deploy(
      "GlobalLegendAccessControl",
      "LAC"
    );

    // add the collection contract to admin
    legendFactory = await LegendFactory.deploy(
      "LegendFactory",
      "LFAC",
      accessControl.address
    );

    legendPayment = await LegendPayment.deploy(accessControl.address);
    legendNFT = await LegendNFT.deploy(accessControl.address);
    legendCollection = await LegendCollection.deploy(
      legendNFT.address,
      accessControl.address,
      legendPayment.address,
      legendFactory.address,
      "LECOL",
      "LegendCollection"
    );
    legendFulfillment = await LegendFulfillment.deploy(
      accessControl.address,
      legendNFT.address,
      legendCollection.address,
      "LEFUL",
      "LegendFulfillment"
    );
    legendMarketplace = await LegendMarketplace.deploy(
      legendCollection.address,
      accessControl.address,
      legendFulfillment.address,
      legendNFT.address,
      "LEMA",
      "LegendMarketplace"
    );
    legendDrop = await LegendDrop.deploy(
      legendCollection.address,
      accessControl.address,
      "LEDR",
      "LegendDrop"
    );
    legendEscrow = await LegendEscrow.deploy(
      legendCollection.address,
      legendMarketplace.address,
      accessControl.address,
      legendNFT.address,
      "LEES",
      "LegendEscrow"
    );

    await accessControl.connect(admin).addAdmin(legendCollection.address);

    await legendNFT
      .connect(admin)
      .setLegendCollection(legendCollection.address);
    await legendNFT.connect(admin).setLegendEscrow(legendEscrow.address);
    await legendCollection.connect(admin).setLegendDrop(legendDrop.address);
    await legendCollection
      .connect(admin)
      .setLegendFulfillment(legendFulfillment.address);
    await legendCollection.connect(admin).setLegendEscrow(legendEscrow.address);
    await legendMarketplace
      .connect(admin)
      .setLegendEscrow(legendEscrow.address);

    // deploy test erc20 and transfer to nonAdmin
    const ERC20 = await ethers.getContractFactory("TestToken");
    token = await ERC20.connect(admin).deploy();
    await token.deployed();
    await token
      .connect(admin)
      .transfer(nonAdmin.address, ethers.utils.parseEther("60"));

    // verify payment tokens
    legendPayment
      .connect(admin)
      .setVerifiedPaymentTokens([
        token.address,
        "0x0000000000000000000000000000000000001010",
        "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619",
      ]);

    // create fulfiller
    legendFulfillment.connect(admin).createFulfiller(20, fulfiller.address);

    // mint to the factory with the writer address
    accessControl.connect(admin).addAdmin(legendFactory.address);

    const thisStruct = {
      lensHubProxyAddress: legendFactory.address,
      legendFactoryAddress: legendFactory.address,
      URIArrayValue: URIArray,
      grantNameValue: grantName,
      editionAmountValue: editionAmount,
    };

    const tx = await legendFactory
      .connect(writer)
      .createContracts(pubId, profileId, thisStruct);
    const receipt = await tx.wait();

    const event = receipt.events.find(
      (event: any) => event.event === "FactoryDeployed"
    );

    const eventData = await event.args;

    legendDynamicNFT = LegendDynamicNFT.attach(eventData.dynamicNFTAddress);
  });

  describe("createFulfiller", () => {
    it("should create a new fulfiller", async () => {
      expect(await legendFulfillment.createFulfiller(10, fulfiller.address))
        .to.emit(legendFulfillment, "FulfillerCreated")
        .withArgs(2, BigNumber.from("10"), fulfiller.address);

    

      expect(await legendFulfillment.getFulfillerPercent(2)).to.equal(10);

      expect(await legendFulfillment.getFulfillerAddress(2)).to.equal(
        fulfiller.address
      );

      expect(await legendFulfillment.getFulfillerCount()).to.equal(2);
    });

    it("rejects if % is greater than 100", async () => {
      await expect(
        legendFulfillment.createFulfiller(101, fulfiller.address)
      ).to.be.revertedWith(
        "LegendFulfillment: Percent can not be greater than 100."
      );
    });

    it("rejects if non-admin creates fulfiller", async () => {
      await expect(
        legendFulfillment
          .connect(nonAdmin)
          .createFulfiller(10, fulfiller.address)
      ).to.be.revertedWith(
        "GlobalLegendAccessControl: Only admin can perform this action"
      );
    });

    it("updates fulfiller count", async () => {
      expect(await legendFulfillment.getFulfillerCount()).to.equal(1);
    });
  });

  describe("updateLegendNFT", () => {
    it("should update the LegendNFT contract address", async () => {
      const oldNFT = await legendFulfillment.getLegendNFTContract();
      const newLegendNFT = await ethers.getContractFactory("LegendNFT");
      const newLegendNFTInstance = await newLegendNFT.deploy(
        accessControl.address
      );

      expect(
        await legendFulfillment.updateLegendNFT(newLegendNFTInstance.address)
      )
        .to.emit(legendFulfillment, "LegendNFTUpdated")
        .withArgs(oldNFT, newLegendNFTInstance.address, admin.address);

      expect(await legendFulfillment.getLegendNFTContract()).to.equal(
        newLegendNFTInstance.address
      );
    });
  });

  describe("updateAccessControl", () => {
    it("should update the AccessControl contract address", async () => {
      const oldAccess = await legendFulfillment.getAccessControlContract();
      const newAccessControl = await ethers.getContractFactory(
        "GlobalLegendAccessControl"
      );
      const newAccessControlInstance = await newAccessControl.deploy(
        "GlobalLegendAccessControl",
        "LAC"
      );

      expect(
        await legendFulfillment.updateAccessControl(
          newAccessControlInstance.address
        )
      )
        .to.emit(legendFulfillment, "AccessControlUpdated")
        .withArgs(oldAccess, newAccessControlInstance.address, admin.address);

      expect(await legendFulfillment.getAccessControlContract()).to.equal(
        newAccessControlInstance.address
      );
    });
  });

  describe("updateLegendCollection", () => {
    it("should update the LegendCollection contract address", async () => {
      const oldCollection =
        await legendFulfillment.getLegendCollectionContract();
      const newLegendCollection = await ethers.getContractFactory(
        "LegendCollection"
      );
      const newLegendCollectionInstance = await newLegendCollection.deploy(
        legendNFT.address,
        accessControl.address,
        legendPayment.address,
        legendFactory.address,
        "LECOL",
        "LegendCollection"
      );

      expect(
        await legendFulfillment.updateLegendCollection(
          newLegendCollectionInstance.address
        )
      )
        .to.emit(legendFulfillment, "LegendCollectionUpdated")
        .withArgs(
          oldCollection,
          newLegendCollectionInstance.address,
          admin.address
        );

      expect(await legendFulfillment.getLegendCollectionContract()).to.equal(
        newLegendCollectionInstance.address
      );
    });
  });

  describe("updates count", () => {
    it("correctly updates count for multiple fulfillers", async () => {
      await legendFulfillment.createFulfiller(10, fulfiller.address);
      await legendFulfillment.createFulfiller(10, fulfiller.address);

      expect(await legendFulfillment.getFulfillerCount()).to.equal(3);
    });
  });

  describe("updateFulfillerPercent", () => {
    it("should update the fulfiller percent", async () => {
      await legendFulfillment.createFulfiller(10, fulfiller.address);

      expect(
        await legendFulfillment.connect(fulfiller).updateFulfillerPercent(1, 20)
      )
        .to.emit(legendFulfillment, "FulfillerPercentUpdated")
        .withArgs(1, 20);

      expect(await legendFulfillment.getFulfillerPercent(1)).to.equal(20);
    });

    it("rejects non fulfiller updating", async () => {
      await legendFulfillment.createFulfiller(10, fulfiller.address);

      await expect(
        legendFulfillment.updateFulfillerPercent(1, 20)
      ).to.be.revertedWith("LegendFulfillment: Only the fulfiller can update.");
    });
  });

  describe("updateFulfillerAddress", () => {
    it("should update the fulfiller percent", async () => {
      await legendFulfillment.createFulfiller(10, fulfiller.address);

      expect(
        await legendFulfillment
          .connect(fulfiller)
          .updateFulfillerAddress(1, nonAdmin.address)
      )
        .to.emit(legendFulfillment, "FulfillerAddressUpdated")
        .withArgs(1, nonAdmin.address);

      expect(await legendFulfillment.getFulfillerAddress(1)).to.equal(
        nonAdmin.address
      );
    });

    it("rejects non fulfiller updating", async () => {
      await legendFulfillment.createFulfiller(10, fulfiller.address);

      await expect(
        legendFulfillment.updateFulfillerAddress(1, nonAdmin.address)
      ).to.be.revertedWith("LegendFulfillment: Only the fulfiller can update.");
    });
  });

});
