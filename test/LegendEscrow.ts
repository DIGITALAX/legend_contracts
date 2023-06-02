import { ethers } from "hardhat";
import { BigNumber, Contract } from "ethers";
import { solidity } from "ethereum-waffle";
import chai from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
chai.use(solidity);
const { expect } = chai;

describe("LegendEscrow", function () {
  let accessControl: Contract,
    legendEscrow: Contract,
    legendCollection: Contract,
    legendNFT: Contract,
    legendMarketplace: Contract,
    legendFactory: Contract,
    legendFulfillment: Contract,
    legendDrop: Contract,
    legendPayment: Contract,
    admin: SignerWithAddress,
    nonAdmin: SignerWithAddress,
    writer: SignerWithAddress,
    secondWriter: SignerWithAddress,
    fulfiller: SignerWithAddress,
    token: Contract,
    legendDynamicNFT: Contract;

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
    [admin, nonAdmin, writer, secondWriter, fulfiller] =
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
      "LegendCollection",
      "LECOL"
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
      "LegendMarketplace",
      "CHROM"
    );
    legendDrop = await LegendDrop.deploy(
      legendCollection.address,
      accessControl.address,
      "LegendDrop",
      "LEDR"
    );
    legendEscrow = await LegendEscrow.deploy(
      legendCollection.address,
      legendMarketplace.address,
      accessControl.address,
      legendNFT.address,
      "LegendEscrow",
      "LEES"
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

  describe("update contracts", () => {
    beforeEach("redeploy contracts", async () => {
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
        "LegendCollection",
        "LECOL"
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
        "LegendMarketplace",
        "CHROM"
      );
      legendDrop = await LegendDrop.deploy(
        legendCollection.address,
        accessControl.address,
        "LegendDrop",
        "LEDR"
      );
      legendEscrow = await LegendEscrow.deploy(
        legendCollection.address,
        legendMarketplace.address,
        accessControl.address,
        legendNFT.address,
        "LegendEscrow",
        "LEES"
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
      await legendCollection
        .connect(admin)
        .setLegendEscrow(legendEscrow.address);
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
    it("updates access", async () => {
      const old = await legendEscrow.getAccessControlContract();
      expect(await legendEscrow.updateAccessControl(accessControl.address))
        .to.emit(legendEscrow, "AccessControlUpdated")
        .withArgs(old, accessControl.address, admin.address);
      expect(await legendEscrow.getAccessControlContract()).to.equal(
        accessControl.address
      );
    });
    it("updates collection", async () => {
      const old = await legendEscrow.getLegendCollectionContract();
      expect(
        await legendEscrow.updateLegendCollection(legendCollection.address)
      )
        .to.emit(legendEscrow, "LegendCollectionUpdated")
        .withArgs(old, legendCollection.address, admin.address);
      expect(await legendEscrow.getLegendCollectionContract()).to.equal(
        legendCollection.address
      );
    });
    it("updates marketplace", async () => {
      const old = await legendEscrow.getLegendMarketContract();
      expect(
        await legendEscrow.updateLegendMarketplace(legendMarketplace.address)
      )
        .to.emit(legendEscrow, "LegendMarketplaceUpdated")
        .withArgs(old, legendMarketplace.address, admin.address);
      expect(await legendEscrow.getLegendMarketContract()).to.equal(
        legendMarketplace.address
      );
    });
    it("updates nft", async () => {
      const old = await legendEscrow.getLegendNFTContract();
      expect(await legendEscrow.updateLegendNFT(legendNFT.address))
        .to.emit(legendEscrow, "LegendNFTUpdated")
        .withArgs(old, legendNFT.address, admin.address);
      expect(await legendEscrow.getLegendNFTContract()).to.equal(
        legendNFT.address
      );
    });
    it("updates fail for all without admin", async () => {
      await expect(
        legendEscrow
          .connect(nonAdmin)
          .updateAccessControl(accessControl.address)
      ).to.be.revertedWith(
        "GlobalLegendAccessControl: Only admin can perform this action"
      );
      await expect(
        legendEscrow
          .connect(nonAdmin)
          .updateLegendCollection(legendCollection.address)
      ).to.be.revertedWith(
        "GlobalLegendAccessControl: Only admin can perform this action"
      );
      await expect(
        legendEscrow
          .connect(nonAdmin)
          .updateLegendMarketplace(legendMarketplace.address)
      ).to.be.revertedWith(
        "GlobalLegendAccessControl: Only admin can perform this action"
      );
      await expect(
        legendEscrow.connect(nonAdmin).updateLegendNFT(legendNFT.address)
      ).to.be.revertedWith(
        "GlobalLegendAccessControl: Only admin can perform this action"
      );
    });
  });

  describe("deposit and release", () => {
    beforeEach("mint collection and add to drop", async () => {
      await legendFactory.createContracts(800, 900, {
        lensHubProxyAddress: legendFactory.address,
        legendFactoryAddress: legendFactory.address,
        URIArrayValue: URIArray,
        grantNameValue: "newgrant",
        editionAmountValue: editionAmount,
      });

      await legendCollection.mintCollection(
        3,
        {
          acceptedTokens: [token.address],
          basePrices: ["20000"],
          uri: "uri",
          printType: "shirt",
          fulfillerId: 1,
          discount: 10,
          grantCollectorsOnly: false,
        },
        "newgrant"
      );
      await legendDrop.createDrop([1], "drop_uri");
    });

    describe("deposit", () => {
      it("calls deposit on mint to escrow", async () => {
        expect(await legendNFT.ownerOf(1)).to.equal(legendEscrow.address);
        expect(await legendNFT.ownerOf(2)).to.equal(legendEscrow.address);
        expect(await legendNFT.ownerOf(3)).to.equal(legendEscrow.address);
      });
      it("fails deposit if not depositer role", async () => {
        await expect(legendEscrow.deposit(2, false)).to.be.revertedWith(
          "LegendEscrow: Only the Legend Collection or NFT contract can call this function"
        );
      });
    });

    describe("release", () => {
      it("calls release on buy", async () => {
        // approve buyer
        token
          .connect(nonAdmin)
          .approve(
            legendMarketplace.address,
            BigNumber.from("50000000000000000000")
          );
        await legendMarketplace
          .connect(nonAdmin)
          .buyTokens([1, 3], token.address, "fulfillmentdetails");
        expect(await legendNFT.ownerOf(1)).to.equal(nonAdmin.address);
        expect(await legendNFT.ownerOf(3)).to.equal(nonAdmin.address);
      });

      it("calls release on burn", async () => {
        await legendCollection.burnCollection(1);
        await expect(legendNFT.ownerOf(1)).to.be.reverted;
      });
      it("fails release if not creator", async () => {
        await expect(
          legendCollection.connect(nonAdmin).burnCollection(1)
        ).to.be.revertedWith(
          "LegendCollection: Only the creator can edit this collection"
        );
        expect(await legendNFT.ownerOf(1)).to.equal(legendEscrow.address);
        expect(await legendNFT.ownerOf(2)).to.equal(legendEscrow.address);
        expect(await legendNFT.ownerOf(3)).to.equal(legendEscrow.address);
      });
      it("fails release if not buyer for burn", async () => {
        await expect(legendNFT.connect(nonAdmin).burn(1)).to.be.revertedWith(
          "ERC721Metadata: Only token owner can burn token"
        );
      });
      it("fails release if not buyer for burn batch", async () => {
        await expect(
          legendNFT.connect(nonAdmin).burnBatch([1, 3])
        ).to.be.revertedWith(
          "ERC721Metadata: Only token owner can burn tokens"
        );
      });

      it("fails to release if not release role", async () => {
        await expect(
          legendEscrow.release(1, false, nonAdmin.address)
        ).to.be.revertedWith(
          "LegendEscrow: Only the Legend Marketplace contract can call this function"
        );
      });
    });
  });
});
