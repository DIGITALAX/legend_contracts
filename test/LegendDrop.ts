import { ethers } from "hardhat";
import { BigNumber, Contract } from "ethers";
import { solidity } from "ethereum-waffle";
import chai from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
chai.use(solidity);
const { expect } = chai;

xdescribe("LegendDrop", () => {
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

  let uri: string,
    collection_name: string,
    amount: number,
    acceptedTokens: string[],
    basePrices: string[];

  beforeEach("mint the collection", async () => {
    uri = "ipfs://newtoken";
    collection_name = "collection one";
    amount = 10;
    acceptedTokens = [
      token.address,
      "0x0000000000000000000000000000000000001010",
      "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619",
    ];
    basePrices = [
      "200000000000000000",
      "1200000000000000000",
      "200000000000000000",
    ];

    await legendFactory.createContracts(800, 900, {
      lensHubProxyAddress: legendFactory.address,
      legendFactoryAddress: legendFactory.address,
      URIArrayValue: URIArray,
      grantNameValue: "newgrant",
      editionAmountValue: editionAmount,
    });

    await legendCollection.mintCollection(
      amount,
      {
        acceptedTokens,
        basePrices,
        uri,
        printType: "shirt",
        fulfillerId: 1,
        discount: 10,
        grantCollectorsOnly: false,
      },
      "newgrant"
    );
  });

  describe("create drop", () => {
    beforeEach("create multiple collections", async () => {
      await accessControl.addWriter(writer.address);
      await legendFactory.createContracts(800, 900, {
        lensHubProxyAddress: legendFactory.address,
        legendFactoryAddress: legendFactory.address,
        URIArrayValue: URIArray,
        grantNameValue: "newgrant2",
        editionAmountValue: editionAmount,
      });
      await legendCollection.mintCollection(
        amount,
        {
          acceptedTokens,
          basePrices,
          uri,
          printType: "shirt",
          fulfillerId: 1,
          discount: 10,
          grantCollectorsOnly: false,
        },
        "newgrant2"
      );
      await legendCollection.mintCollection(
        amount,
        {
          acceptedTokens,
          basePrices,
          uri,
          printType: "shirt",
          fulfillerId: 1,
          discount: 10,
          grantCollectorsOnly: false,
        },
        "newgrant2"
      );
    });

    it("it creates a drop with multiple collections", async () => {
      expect(await legendDrop.createDrop([1, 2, 3], "drop_uri"))
        .to.emit(legendDrop, "DropCreated")
        .withArgs(
          1,
          [BigNumber.from("1"), BigNumber.from("2"), BigNumber.from("3")],
          admin.address
        );
      expect(await legendDrop.getCollectionIdToDrop(1)).to.equal(1);
      expect(await legendDrop.getCollectionIdToDrop(2)).to.equal(1);
      expect(await legendDrop.getCollectionIdToDrop(3)).to.equal(1);

      expect(await legendDrop.getDropSupply()).to.equal(1);
    });

    it("it fails to create a drop if not writer + owner of collections", async () => {
      // no writer
      await expect(
        legendDrop.connect(nonAdmin).createDrop([1, 2, 3], "drop_uri")
      ).to.be.revertedWith(
        "LegendDrop: Only the owner of a collection can add it to a drop"
      );

      // no owner of collection
      await expect(
        legendDrop.connect(writer).createDrop([1, 2, 3], "drop_uri")
      ).to.be.revertedWith(
        "LegendDrop: Only the owner of a collection can add it to a drop"
      );
    });

    it("fails to create a drop if collection does not exist", async () => {
      await expect(legendDrop.createDrop([0, 6], "drop")).to.be.reverted;
    });
  });

  describe("add collection to existing drop", () => {
    beforeEach("create drop", async () => {
      await legendFactory.createContracts(800, 900, {
        lensHubProxyAddress: legendFactory.address,
        legendFactoryAddress: legendFactory.address,
        URIArrayValue: URIArray,
        grantNameValue: "newgrant3",
        editionAmountValue: editionAmount,
      });
      await legendCollection.mintCollection(
        amount,
        {
          acceptedTokens,
          basePrices,
          uri,
          printType: "shirt",
          fulfillerId: 1,
          discount: 10,
          grantCollectorsOnly: false,
        },
        "newgrant3"
      );
      await legendCollection.mintCollection(
        amount,
        {
          acceptedTokens,
          basePrices,
          uri,
          printType: "shirt",
          fulfillerId: 1,
          discount: 10,
          grantCollectorsOnly: false,
        },
        "newgrant3"
      );
      await legendDrop.createDrop([1, 2, 3], "drop_uri");
    });

    it("drop supply is updated", async () => {
      expect(await legendDrop.getDropSupply()).to.equal(1);
    });

    it("it adds collections", async () => {
      await legendFactory.createContracts(800, 900, {
        lensHubProxyAddress: legendFactory.address,
        legendFactoryAddress: legendFactory.address,
        URIArrayValue: URIArray,
        grantNameValue: "newgrantagain",
        editionAmountValue: editionAmount,
      });
      await legendCollection.mintCollection(
        amount,
        {
          acceptedTokens,
          basePrices,
          uri,
          printType: "shirt",
          fulfillerId: 1,
          discount: 10,
          grantCollectorsOnly: false,
        },
        "newgrantagain"
      );
      await legendCollection.mintCollection(
        amount,
        {
          acceptedTokens,
          basePrices,
          uri,
          printType: "shirt",
          fulfillerId: 1,
          discount: 10,
          grantCollectorsOnly: false,
        },
        "newgrantagain"
      );

      expect(await legendDrop.getCollectionIdToDrop(4)).to.equal(0);
      expect(await legendDrop.getCollectionIdToDrop(5)).to.equal(0);

      expect(await legendDrop.addCollectionToDrop(1, [4, 5]))
        .to.emit(legendDrop, "CollectionAddedToDrop")
        .withArgs(1, [BigNumber.from("4"), BigNumber.from("5")]);

      expect(await legendDrop.getCollectionsInDrop(1)).to.deep.equal([
        BigNumber.from("1"),
        BigNumber.from("2"),
        BigNumber.from("3"),
        BigNumber.from("4"),
        BigNumber.from("5"),
      ]);
      expect(await legendDrop.getCollectionIdToDrop(1)).to.equal(1);
      expect(await legendDrop.getCollectionIdToDrop(2)).to.equal(1);
      expect(await legendDrop.getCollectionIdToDrop(3)).to.equal(1);
      expect(await legendDrop.getCollectionIdToDrop(4)).to.equal(1);
      expect(await legendDrop.getCollectionIdToDrop(5)).to.equal(1);
    });

    it("fails to add a collection if it is already part of another drop", async () => {
      await expect(legendDrop.createDrop([1], "drop_uri")).to.be.revertedWith(
        "LegendDrop: Collection is already part of another existing drop"
      );
      await legendCollection.mintCollection(
        amount,
        {
          acceptedTokens,
          basePrices,
          uri,
          printType: "shirt",
          fulfillerId: 1,
          discount: 10,
          grantCollectorsOnly: false,
        },
        "newgrant3"
      );
      legendDrop.createDrop([4], "drop_uri");
      await expect(legendDrop.addCollectionToDrop(2, [4])).to.be.revertedWith(
        "LegendDrop: Collection is already part of another existing drop"
      );
    });

    it("it fails to add a drop if not writer + owner of collections", async () => {
      await legendCollection.mintCollection(
        amount,
        {
          acceptedTokens,
          basePrices,
          uri,
          printType: "shirt",
          fulfillerId: 1,
          discount: 10,
          grantCollectorsOnly: false,
        },
        "newgrant3"
      );
      legendDrop.createDrop([4], "drop_uri");
      await expect(
        legendDrop.connect(nonAdmin).addCollectionToDrop(2, [4])
      ).to.be.revertedWith(
        "LegendDrop: Only the owner of a collection can add it to a drop"
      );
    });

    describe("delete drop / collection ", () => {
      it("removes a collection from a drop", async () => {
        expect(await legendDrop.removeCollectionFromDrop(1))
          .to.emit(legendDrop, "CollectionRemovedFromDrop")
          .withArgs(1, 1);
        expect(await legendDrop.getCollectionsInDrop(1)).to.deep.equal([
          BigNumber.from("3"),
          BigNumber.from("2"),
        ]);
      });

      it("it fails to remove a collection if not writer + owner of collections", async () => {
        await expect(
          legendDrop.connect(nonAdmin).removeCollectionFromDrop(1)
        ).to.be.revertedWith(
          "LegendDrop: Only creator or collection contract can remove collection"
        );
      });

      it("it fails to remove a collection if the collection is not in the drop", async () => {
        await expect(legendDrop.removeCollectionFromDrop(5)).to.be.reverted;
      });

      it("deletes a drop and removes all collections", async () => {
        expect(await legendDrop.deleteDrop(1))
          .to.emit(legendDrop, "DropDeleted")
          .withArgs(1, admin.address);

        expect(await legendDrop.getCollectionIdToDrop(1)).to.equal(0);
        expect(await legendDrop.getCollectionIdToDrop(2)).to.equal(0);
        expect(await legendDrop.getCollectionIdToDrop(3)).to.equal(0);
      });

      it("fails to delete drop if not drop owner/creator", async () => {
        await expect(
          legendDrop.connect(nonAdmin).deleteDrop(1)
        ).to.be.revertedWith(
          "LegendDrop: Only the owner of a collection can add it to a drop"
        );
      });
    });
  });

  describe("contract updates", () => {
    beforeEach("deploy new contracts", async () => {
      const AccessControl = await ethers.getContractFactory(
        "GlobalLegendAccessControl"
      );
      const LegendNFT = await ethers.getContractFactory("LegendNFT");
      accessControl = await AccessControl.deploy("LegendAccessControl", "LEAC");
      legendNFT = await LegendNFT.deploy(accessControl.address);
    });

    it("updates access", async () => {
      const old = await legendDrop.getAccessControlContract();
      expect(await legendDrop.updateAccessControl(accessControl.address))
        .to.emit(legendDrop, "AccessControlUpdated")
        .withArgs(old, accessControl.address, admin.address);
      expect(await legendDrop.getAccessControlContract()).to.equal(
        accessControl.address
      );
    });

    it("updates collection", async () => {
      const old = await legendDrop.getLegendCollectionContract();
      expect(await legendDrop.updateLegendCollection(legendCollection.address))
        .to.emit(legendDrop, "LegendCollectionUpdated")
        .withArgs(old, legendCollection.address, admin.address);
      expect(await legendDrop.getLegendCollectionContract()).to.equal(
        legendCollection.address
      );
    });

    it("fails to update if not admin", async () => {
      await expect(
        legendDrop
          .connect(nonAdmin)
          .updateLegendCollection(legendCollection.address)
      ).to.be.revertedWith(
        "GlobalLegendAccessControl: Only admin can perform this action"
      );

      await expect(
        legendDrop.connect(nonAdmin).updateAccessControl(accessControl.address)
      ).to.be.revertedWith(
        "GlobalLegendAccessControl: Only admin can perform this action"
      );
    });
  });

  describe("drop getters and setters", async () => {
    let blockNumber: any;
    beforeEach("create drop", async () => {
      await legendFactory.createContracts(800, 900, {
        lensHubProxyAddress: legendFactory.address,
        legendFactoryAddress: legendFactory.address,
        URIArrayValue: URIArray,
        grantNameValue: "newgrant4",
        editionAmountValue: editionAmount,
      });
      await legendCollection.mintCollection(
        amount,
        {
          acceptedTokens,
          basePrices,
          uri,
          printType: "shirt",
          fulfillerId: 1,
          discount: 10,
          grantCollectorsOnly: false,
        },
        "newgrant4"
      );
      await legendCollection.mintCollection(
        amount,
        {
          acceptedTokens,
          basePrices,
          uri,
          printType: "shirt",
          fulfillerId: 1,
          discount: 10,
          grantCollectorsOnly: false,
        },
        "newgrant4"
      );
      await legendDrop.createDrop([1, 2, 3], "drop_uri");
      blockNumber = await ethers.provider.getBlockNumber();
    });

    it("returns the collections", async () => {
      expect(await legendDrop.getCollectionsInDrop(1)).to.deep.equal([
        BigNumber.from("1"),
        BigNumber.from("2"),
        BigNumber.from("3"),
      ]);
    });

    it("returns the uri", async () => {
      expect(await legendDrop.getDropURI(1)).to.equal("drop_uri");
    });

    it("returns the creator", async () => {
      expect(await legendDrop.getDropCreator(1)).to.equal(admin.address);
    });

    it("returns the timestamp", async () => {
      const block = await ethers.provider.getBlock(blockNumber);
      expect(await legendDrop.getDropTimestamp(1)).to.equal(block.timestamp);
    });

    it("updates the uri", async () => {
      expect(await legendDrop.setDropURI(1, "new_uri"))
        .to.emit(legendDrop, "DropURIUpdated")
        .withArgs(1, "new_uri");
      expect(await legendDrop.getDropURI(1)).to.equal("new_uri");
    });

    it("fails to update the uri if not creator", async () => {
      await expect(
        legendDrop.connect(nonAdmin).setDropURI(1, "new_uri")
      ).to.be.revertedWith(
        "LegendDrop: Only the owner of a drop can edit a drop"
      );
    });

    it("collection removed from drop when burned", async () => {
      await legendCollection.burnCollection(1);
      expect(await legendDrop.getCollectionsInDrop(1)).to.deep.equal([
        BigNumber.from("3"),
        BigNumber.from("2"),
      ]);
    });
  });
});
