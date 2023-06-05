import { ethers } from "hardhat";
import { BigNumber, Contract } from "ethers";
import { solidity } from "ethereum-waffle";
import chai from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
chai.use(solidity);
const { expect } = chai;

describe("LegendNFT + LegendCollection", function () {
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

  let tx: any,
    uri: string,
    amount: number,
    acceptedTokens: string[],
    blockNumber: number,
    basePrices: string[],
    printType: string,
    myStruct: any;
  beforeEach("mint the collection as verified deployer", async () => {
    uri = "ipfs://newtoken";
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
    printType = "shirt";

    myStruct = {
      acceptedTokens,
      basePrices,
      uri,
      printType,
      fulfillerId: 1,
      discount: 10,
      grantCollectorsOnly: false,
    };

    tx = await legendCollection
      .connect(writer)
      .mintCollection(amount, myStruct, grantName);

    blockNumber = await ethers.provider.getBlockNumber();
  });

  describe("should mint a new collection + batch of tokens", () => {
    it("emits collection minted", async () => {
      const collId = await legendCollection.getCollectionSupply();
      expect(tx)
        .to.emit(legendCollection, "CollectionMinted")
        .withArgs(collId, uri, amount, writer.address);
    });

    it("has a correct nft total supply", async () => {
      expect(await legendNFT.getTotalSupplyCount()).to.equal(amount);
    });

    it("has a correct collection id", async () => {
      expect(await legendCollection.getCollectionSupply()).to.equal(1);
    });

    it("has correct uri for all minted tokens", async () => {
      for (let i = 1; i < amount; i++) {
        expect(await legendNFT.tokenURI(i)).to.equal(uri);
      }
      expect(await legendCollection.getCollectionURI(1)).to.equal(uri);
    });

    it("has correct id for all minted tokens and collection", async () => {
      for (let i = 1; i < amount; i++) {
        expect(await legendNFT.getTokenId(i)).to.equal(i);
      }
    });

    it("creator to be minter of collection", async () => {
      expect(await legendCollection.getCollectionCreator(1)).to.equal(
        writer.address
      );
      for (let i = 1; i < amount; i++) {
        expect(await legendNFT.getTokenCreator(i)).to.equal(writer.address);
      }
    });

    it("collection includes correct token ids", async () => {
      expect(await legendCollection.getCollectionTokenIds(1)).to.eql([
        BigNumber.from("1"),
        BigNumber.from("2"),
        BigNumber.from("3"),
        BigNumber.from("4"),
        BigNumber.from("5"),
        BigNumber.from("6"),
        BigNumber.from("7"),
        BigNumber.from("8"),
        BigNumber.from("9"),
        BigNumber.from("10"),
      ]);
    });

    it("all tokens are owned by escrow", async () => {
      for (let i = 1; i < amount; i++) {
        expect(await legendNFT.ownerOf(i)).to.equal(legendEscrow.address);
      }
    });

    it("collection amount is correct", async () => {
      expect(await legendCollection.getCollectionAmount(1)).to.equal(amount);
    });

    it("accepted tokens for all", async () => {
      const expectedTokens = [
        token.address,
        "0x0000000000000000000000000000000000001010",
        "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619",
      ].map((address) => address.toLowerCase());
      const actualTokens = (
        await legendCollection.getCollectionAcceptedTokens(1)
      ).map((address: string) => address.toLowerCase());

      expect(actualTokens).to.deep.equal(expectedTokens);

      for (let i = 1; i < amount; i++) {
        const actualTokens = (await legendNFT.getTokenAcceptedTokens(i)).map(
          (address: string) => address.toLowerCase()
        );
        expect(actualTokens).to.deep.equal(expectedTokens);
      }
    });

    it("accepted prices for all", async () => {
      expect(await legendCollection.getCollectionBasePrices(1)).to.eql([
        BigNumber.from("200000000000000000"),
        BigNumber.from("1200000000000000000"),
        BigNumber.from("200000000000000000"),
      ]);

      for (let i = 1; i < amount; i++) {
        expect(await legendNFT.getTokenBasePrices(i)).to.eql([
          BigNumber.from("200000000000000000"),
          BigNumber.from("1200000000000000000"),
          BigNumber.from("200000000000000000"),
        ]);
      }
    });

    it("is burn is false for all", async () => {
      expect(await legendCollection.getCollectionIsBurned(1)).to.equal(false);
      for (let i = 1; i < amount; i++) {
        expect(await legendNFT.getTokenIsBurned(i)).to.equal(false);
      }
    });

    it("correct timestamp for all", async () => {
      const block = await ethers.provider.getBlock(blockNumber);
      expect(await legendCollection.getCollectionTimestamp(1)).to.equal(
        block.timestamp
      );

      for (let i = 1; i < amount; i++) {
        expect(await legendNFT.getTokenTimestamp(i)).to.equal(block.timestamp);
      }
    });

    it("correct discount for all", async () => {
      expect(await legendCollection.getCollectionDiscount(1)).to.equal(10);
      for (let i = 1; i < amount; i++) {
        expect(await legendNFT.getTokenDiscount(i)).to.equal(10);
      }
    });

    it("correct collectors only for all", async () => {
      expect(
        await legendCollection.getCollectionGrantCollectorsOnly(1)
      ).to.equal(false);
      for (let i = 1; i < amount; i++) {
        expect(await legendNFT.getTokenGrantCollectorsOnly(i)).to.equal(false);
      }
    });

    it("correct pubId for all", async () => {
      expect(await legendCollection.getCollectionPubId(1)).to.equal(pubId);
      for (let i = 1; i < amount; i++) {
        expect(await legendNFT.getTokenPubId(i)).to.equal(pubId);
      }
    });

    it("correct dynamicNFTAddress for all", async () => {
      expect(await legendCollection.getCollectionDynamicNFTAddress(1)).to.equal(
        legendDynamicNFT.address
      );
      for (let i = 1; i < amount; i++) {
        expect(await legendNFT.getTokenDynamicNFTAddress(i)).to.equal(
          legendDynamicNFT.address
        );
      }
    });

    it("correct print type for all", async () => {
      expect(await legendCollection.getCollectionPrintType(1)).to.equal(
        printType
      );
      for (let i = 1; i < amount; i++) {
        expect(await legendNFT.getTokenPrintType(i)).to.equal(printType);
      }
    });

    it("correct fulfiller id for all", async () => {
      expect(await legendCollection.getCollectionFulfillerId(1)).to.equal(1);
      for (let i = 1; i < amount; i++) {
        expect(await legendNFT.getTokenFulfillerId(i)).to.equal(1);
      }
    });

    it("correct drop id for all", async () => {
      expect(await legendCollection.getCollectionDropId(1)).to.equal(0);
    });
  });

  describe("it should reject for all requires", () => {
    it("rejects on non grant writer", async () => {
      await expect(
        legendCollection
          .connect(nonAdmin)
          .mintCollection(amount, myStruct, grantName)
      ).to.be.revertedWith(
        "LegendCollection: Only grant publishers can make collections for their grants."
      );
    });

    it("rejects on invalid price / token length", async () => {
      await expect(
        legendCollection.connect(writer).mintCollection(
          amount,
          {
            acceptedTokens,
            basePrices: ["100"],
            uri,
            printType,
            fulfillerId: 1,
            discount: 10,
            grantCollectorsOnly: false,
          },
          grantName
        )
      ).to.be.revertedWith("LegendCollection: Invalid input");
    });

    it("rejects if another grant deployer tries to make a collection for a grant that isn't theirs", async () => {
      await legendFactory.connect(nonAdmin).createContracts(800, 900, {
        lensHubProxyAddress: legendFactory.address,
        legendFactoryAddress: legendFactory.address,
        URIArrayValue: URIArray,
        grantNameValue: "new grant other",
        editionAmountValue: editionAmount,
      });

      await expect(
        legendCollection.connect(nonAdmin).mintCollection(
          amount,
          {
            acceptedTokens,
            basePrices: ["100"],
            uri,
            printType,
            fulfillerId: 1,
            discount: 10,
            grantCollectorsOnly: true,
          },
          grantName
        )
      ).to.be.revertedWith(
        "LegendCollection: Only grant publishers can make collections for their grants."
      );

      // try again with same different grant name
      await expect(
        legendCollection
          .connect(writer)
          .mintCollection(amount, myStruct, "another grant name")
      ).to.be.revertedWith(
        "LegendCollection: Only grant publishers can make collections for their grants."
      );
    });
  });

  describe("it should correctly track 2nd collection", async () => {
    beforeEach("mints second collection", async () => {
      await legendCollection.connect(writer).mintCollection(
        15,
        {
          acceptedTokens,
          basePrices,
          uri: "second_uri",
          printType,
          fulfillerId: 1,
          discount: 10,
          grantCollectorsOnly: false,
        },
        grantName
      );
      blockNumber = await ethers.provider.getBlockNumber();
    });

    it("new collection id", async () => {
      expect(await legendCollection.getCollectionSupply()).to.equal(2);
    });

    it("new token ids", async () => {
      expect(await legendCollection.getCollectionTokenIds(2)).to.eql([
        BigNumber.from("11"),
        BigNumber.from("12"),
        BigNumber.from("13"),
        BigNumber.from("14"),
        BigNumber.from("15"),
        BigNumber.from("16"),
        BigNumber.from("17"),
        BigNumber.from("18"),
        BigNumber.from("19"),
        BigNumber.from("20"),
        BigNumber.from("21"),
        BigNumber.from("22"),
        BigNumber.from("23"),
        BigNumber.from("24"),
        BigNumber.from("25"),
      ]);
    });

    it("new total supply", async () => {
      expect(await legendNFT.getTotalSupplyCount()).to.equal(25);
    });

    it("new uris", async () => {
      expect(await legendCollection.getCollectionURI(2)).to.equal("second_uri");
      for (let i = amount + 1; i < amount + 15; i++) {
        expect(await legendNFT.tokenURI(i + 1)).to.equal("second_uri");
      }
    });

    it("all tokens are owned by escrow", async () => {
      for (let i = amount + 1; i < amount + 15; i++) {
        expect(await legendNFT.ownerOf(i + 1)).to.equal(legendEscrow.address);
      }
    });
  });

  describe("it should fail to mint if not collection contract", () => {
    it("fail mint batch", async () => {
      await expect(
        legendNFT.mintBatch(
          {
            acceptedTokens,
            basePrices,
            uri: "second_uri",
            printType,
            fulfillerId: 1,
            discount: 10,
            grantCollectorsOnly: false,
          },
          amount,
          pubId,
          1,
          legendDynamicNFT.address,
          admin.address
        )
      ).to.be.revertedWith(
        "LegendNFT: Only collection contract can mint tokens"
      );
    });
  });

  describe("burn tokens", () => {
    beforeEach("buy from marketplace", async () => {
      await legendFactory
        .connect(secondWriter)
        .createContracts(pubId, profileId, {
          lensHubProxyAddress: legendFactory.address,
          legendFactoryAddress: legendFactory.address,
          URIArrayValue: URIArray,
          grantNameValue: grantName,
          editionAmountValue: editionAmount,
        });

      // mint another collection
      await legendCollection.connect(secondWriter).mintCollection(
        amount,
        {
          acceptedTokens,
          basePrices,
          uri: "burnurivalue",
          printType,
          fulfillerId: 1,
          discount: 20,
          grantCollectorsOnly: false,
        },
        grantName
      );

      // add collection to a drop
      await legendDrop.connect(secondWriter).createDrop([2], "drop_uri");

      // approve allowance
      await token
        .connect(nonAdmin)
        .approve(
          legendMarketplace.address,
          BigNumber.from("800000000000000000")
        );

      await legendMarketplace
        .connect(nonAdmin)
        .buyTokens([1, 2, 13], token.address, "fulfillmentdetails");
    });

    it("it should burn a token as buyer / owner and emit event", async () => {
      expect(await legendNFT.connect(nonAdmin).burn(1))
        .to.emit(legendNFT, "TokenBurned")
        .withArgs(1);
    });

    it("it should be set as burn from nft level and owner should be burn address", async () => {
      await legendNFT.connect(nonAdmin).burn(1);
      expect(await legendNFT.getTokenIsBurned(1)).to.equal(true);
      await expect(legendNFT.ownerOf(1)).to.be.reverted;
    });

    it("it should burn a batch of tokens", async () => {
      await legendNFT.connect(nonAdmin).burnBatch([1, 2, 13]);
      expect(await legendNFT.getTokenIsBurned(1)).to.equal(true);
      expect(await legendNFT.getTokenIsBurned(2)).to.equal(true);
      expect(await legendNFT.getTokenIsBurned(13)).to.equal(true);
    });

    describe("it should be set as burn from collection level", () => {
      beforeEach("burn collection", async () => {
        expect(await legendCollection.connect(secondWriter).burnCollection(2))
          .to.emit(legendCollection, "CollectionBurned")
          .withArgs(secondWriter.address, 2);
      });

      it("it should be set as burn from collection level", async () => {
        expect(await legendCollection.getCollectionIsBurned(2)).to.equal(true);
      });

      it("should be able to purchase and mint another collection after burning", async () => {
        const tx = await legendCollection.connect(writer).mintCollection(
          amount,
          {
            acceptedTokens,
            basePrices,
            uri: "burnurivalue",
            printType,
            fulfillerId: 1,
            discount: 20,
            grantCollectorsOnly: false,
          },
          grantName
        );
        const collId = await legendCollection.getCollectionSupply();
        expect(tx)
          .to.emit(legendCollection, "CollectionMinted")
          .withArgs(collId, "burnurivalue", amount, writer.address);
      });
    });

    it("it should fail to burn if not creator or contract", async () => {
      await expect(
        legendCollection.connect(nonAdmin).burnCollection(2)
      ).to.be.revertedWith(
        "LegendCollection: Only the creator can edit this collection"
      );
    });
  });

  describe("update contract dependencies", () => {
    beforeEach("redeploy new contracts", async () => {
      const AccessControl = await ethers.getContractFactory(
        "GlobalLegendAccessControl"
      );
      const LegendEscrow = await ethers.getContractFactory("LegendEscrow");
      const LegendCollection = await ethers.getContractFactory(
        "LegendCollection"
      );
      const LegendNFT = await ethers.getContractFactory("LegendNFT");
      const LegendPayment = await ethers.getContractFactory("LegendPayment");
      const LegendFulfillment = await ethers.getContractFactory(
        "LegendFulfillment"
      );
      const LegendMarketplace = await ethers.getContractFactory("LegendMarket");
      const LegendDrop = await ethers.getContractFactory("LegendDrop");
      accessControl = await AccessControl.deploy("LegendAccessControl", "LEAC");
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

      accessControl.connect(admin).addAdmin(legendFactory.address);
    });

    it("updates access controls", async () => {
      const old_access = await legendNFT.getAccessControlContract();
      expect(await legendNFT.updateAccessControl(accessControl.address))
        .to.emit(legendNFT, "AccessControlUpdated")
        .withArgs(old_access, accessControl.address, admin.address);
      expect(await legendNFT.getAccessControlContract()).to.equal(
        accessControl.address
      );

      expect(await legendCollection.updateAccessControl(accessControl.address))
        .to.emit(legendCollection, "AccessControlUpdated")
        .withArgs(old_access, accessControl.address, admin.address);
      expect(await legendCollection.getAccessControlContract()).to.equal(
        accessControl.address
      );
    });

    it("updates escrow", async () => {
      const oldAddress = await legendNFT.getLegendEscrowContract();
      expect(await legendNFT.setLegendEscrow(legendEscrow.address))
        .to.emit(legendNFT, "LegendEscrowUpdated")
        .withArgs(oldAddress, legendEscrow.address, admin.address);
      expect(await legendNFT.getLegendEscrowContract()).to.equal(
        legendEscrow.address
      );

      const oldAdressColl = await legendCollection.getLegendEscrowContract();

      expect(await legendCollection.setLegendEscrow(legendEscrow.address))
        .to.emit(legendCollection, "LegendEscrowUpdated")
        .withArgs(oldAdressColl, legendEscrow.address, admin.address);
      expect(await legendCollection.getLegendEscrowContract()).to.equal(
        legendEscrow.address
      );
    });

    it("updates collection", async () => {
      const oldAddress = await legendNFT.getLegendCollectionContract();
      expect(await legendNFT.setLegendCollection(legendCollection.address))
        .to.emit(legendNFT, "LegendCollectionUpdated")
        .withArgs(oldAddress, legendCollection.address, admin.address);
      expect(await legendNFT.getLegendCollectionContract()).to.equal(
        legendCollection.address
      );
    });

    it("updates drop", async () => {
      const oldAddress = await legendCollection.getLegendDropContract();
      expect(await legendCollection.setLegendDrop(legendDrop.address))
        .to.emit(legendCollection, "LegendDropUpdated")
        .withArgs(oldAddress, legendDrop.address, admin.address);
      expect(await legendCollection.getLegendDropContract()).to.equal(
        legendDrop.address
      );
    });

    it("updates payment", async () => {
      const oldAddress = await legendCollection.getLegendPaymentContract();
      expect(await legendCollection.updateLegendPayment(legendPayment.address))
        .to.emit(legendCollection, "LegendPaymentUpdated")
        .withArgs(oldAddress, legendPayment.address, admin.address);
      expect(await legendCollection.getLegendPaymentContract()).to.equal(
        legendPayment.address
      );
    });

    it("updates fulfillment", async () => {
      const oldAddress = await legendCollection.getLegendFulfillmentContract();
      expect(
        await legendCollection.setLegendFulfillment(legendFulfillment.address)
      )
        .to.emit(legendCollection, "LegendFulfillmentUpdated")
        .withArgs(oldAddress, legendFulfillment.address, admin.address);
      expect(await legendCollection.getLegendFulfillmentContract()).to.equal(
        legendFulfillment.address
      );
    });

    it("updates factory", async () => {
      const oldAddress = await legendCollection.getLegendFactoryContract();
      expect(await legendCollection.updateLegendFactory(legendFactory.address))
        .to.emit(legendCollection, "LegendFactoryUpdated")
        .withArgs(oldAddress, legendFactory.address, admin.address);
      expect(await legendCollection.getLegendFactoryContract()).to.equal(
        legendFactory.address
      );
    });

    it("updates NFT", async () => {
      const oldAddress = await legendCollection.getLegendNFTContract();
      expect(await legendCollection.updateLegendNFT(legendNFT.address))
        .to.emit(legendCollection, "LegendNFTUpdated")
        .withArgs(oldAddress, legendNFT.address, admin.address);
      expect(await legendCollection.getLegendNFTContract()).to.equal(
        legendNFT.address
      );
    });

    it("should fail all updates if not admin", async () => {
      await expect(
        legendNFT
          .connect(nonAdmin)
          .setLegendCollection(legendCollection.address)
      ).to.be.revertedWith(
        "GlobalLegendAccessControl: Only admin can perform this action"
      );
      await expect(
        legendNFT.connect(nonAdmin).setLegendEscrow(legendEscrow.address)
      ).to.be.revertedWith(
        "GlobalLegendAccessControl: Only admin can perform this action"
      );
      await expect(
        legendNFT.connect(nonAdmin).updateAccessControl(accessControl.address)
      ).to.be.revertedWith(
        "GlobalLegendAccessControl: Only admin can perform this action"
      );
      await expect(
        legendCollection
          .connect(nonAdmin)
          .updateAccessControl(accessControl.address)
      ).to.be.revertedWith(
        "GlobalLegendAccessControl: Only admin can perform this action"
      );
      await expect(
        legendCollection.connect(nonAdmin).updateLegendNFT(legendNFT.address)
      ).to.be.revertedWith(
        "GlobalLegendAccessControl: Only admin can perform this action"
      );
      await expect(
        legendCollection.connect(nonAdmin).setLegendEscrow(legendEscrow.address)
      ).to.be.revertedWith(
        "GlobalLegendAccessControl: Only admin can perform this action"
      );
      await expect(
        legendCollection.connect(nonAdmin).setLegendDrop(legendDrop.address)
      ).to.be.revertedWith(
        "GlobalLegendAccessControl: Only admin can perform this action"
      );
      await expect(
        legendCollection
          .connect(nonAdmin)
          .updateLegendPayment(legendPayment.address)
      ).to.be.revertedWith(
        "GlobalLegendAccessControl: Only admin can perform this action"
      );
      await expect(
        legendCollection
          .connect(nonAdmin)
          .setLegendFulfillment(legendFulfillment.address)
      ).to.be.revertedWith(
        "GlobalLegendAccessControl: Only admin can perform this action"
      );
      await expect(
        legendCollection
          .connect(nonAdmin)
          .updateLegendFactory(legendFactory.address)
      ).to.be.revertedWith(
        "GlobalLegendAccessControl: Only admin can perform this action"
      );
    });
  });

  describe("it should update setters and read getters", () => {
    beforeEach("create collection with write address", async () => {
      // give access control to writer
      await legendFactory
        .connect(secondWriter)
        .createContracts(pubId, profileId, {
          lensHubProxyAddress: legendFactory.address,
          legendFactoryAddress: legendFactory.address,
          URIArrayValue: URIArray,
          grantNameValue: grantName,
          editionAmountValue: editionAmount,
        });

      await legendCollection.connect(secondWriter).mintCollection(
        amount,
        {
          acceptedTokens,
          basePrices,
          uri: "newurivalue",
          printType,
          fulfillerId: 1,
          discount: 20,
          grantCollectorsOnly: false,
        },
        grantName
      );
    });

    it("set URI", async () => {
      const old = await legendCollection.getCollectionURI(2);
      expect(
        await legendCollection
          .connect(secondWriter)
          .setCollectionURI("newurivalue", 2)
      )
        .to.emit(legendCollection, "CollectionURIUpdated")
        .withArgs(2, old, "newurivalue", secondWriter.address);
      expect(await legendCollection.getCollectionURI(2)).to.equal(
        "newurivalue"
      );
      expect(await legendNFT.tokenURI(13)).to.equal("newurivalue");
    });

    it("set tokens accepted", async () => {
      const old = await legendCollection.getCollectionAcceptedTokens(2);
      expect(
        await legendCollection
          .connect(secondWriter)
          .setCollectionAcceptedTokens(2, [token.address])
      )
        .to.emit(legendCollection, "CollectionAcceptedTokensUpdated")
        .withArgs(2, old, [token.address], secondWriter.address);
      expect(
        await legendCollection.getCollectionAcceptedTokens(2)
      ).to.deep.equal([token.address]);
      expect(await legendNFT.getTokenAcceptedTokens(13)).to.deep.equal([
        token.address,
      ]);
    });

    it("set prices", async () => {
      const old = await legendCollection.getCollectionBasePrices(2);
      expect(
        await legendCollection
          .connect(secondWriter)
          .setCollectionBasePrices(2, ["2000000"])
      )
        .to.emit(legendCollection, "CollectionBasePricesUpdated")
        .withArgs(2, old, ["2000000"], secondWriter.address);
      expect(await legendCollection.getCollectionBasePrices(2)).to.deep.equal([
        BigNumber.from("2000000"),
      ]);
      expect(await legendNFT.getTokenBasePrices(13)).to.deep.equal([
        BigNumber.from("2000000"),
      ]);
    });

    it("should fail all setters if not creator / collection contract", async () => {
      await expect(
        legendCollection.setCollectionURI("new_token", 2)
      ).to.be.revertedWith(
        "LegendCollection: Only the creator can edit this collection"
      );
      await expect(
        legendCollection.setCollectionAcceptedTokens(2, [token.address])
      ).to.be.revertedWith(
        "LegendCollection: Only the creator can edit this collection"
      );
      await expect(
        legendCollection.setCollectionBasePrices(2, ["2000000"])
      ).to.be.revertedWith(
        "LegendCollection: Only the creator can edit this collection"
      );
      await expect(legendNFT.setTokenURI(13, "new_token")).to.be.revertedWith(
        "LegendNFT: Only collection contract can mint tokens"
      );
      await expect(
        legendNFT.setTokenAcceptedTokens(13, [token.address])
      ).to.be.revertedWith(
        "LegendNFT: Only collection contract can mint tokens"
      );
      await expect(legendNFT.setBasePrices(13, ["2000000"])).to.be.revertedWith(
        "LegendNFT: Only collection contract can mint tokens"
      );
    });

    it("should fail setters if collection not all in escrow", async () => {
      // buy from another collection
      await legendCollection.connect(writer).mintCollection(
        amount,
        {
          acceptedTokens,
          basePrices,
          uri: "newurivalue2",
          printType,
          fulfillerId: 1,
          discount: 20,
          grantCollectorsOnly: false,
        },
        grantName
      );

      // add collection to a drop
      await legendDrop.connect(writer).createDrop([3], "drop_uri");

      // approve allowance
      await token
        .connect(nonAdmin)
        .approve(
          legendMarketplace.address,
          BigNumber.from("300000000000000000")
        );

      await legendMarketplace
        .connect(nonAdmin)
        .buyTokens([22], token.address, "fulfillment details");

      await expect(
        legendCollection.connect(writer).setCollectionURI("new_token", 3)
      ).to.be.revertedWith(
        "LegendCollection: The entire collection must be owned by Escrow to update"
      );
    });

    describe("only updates the values in escrow", () => {
      beforeEach("mint and buy", async () => {
        await legendCollection.connect(writer).mintCollection(
          amount,
          {
            acceptedTokens,
            basePrices,
            uri: "newurivalue2",
            printType,
            fulfillerId: 1,
            discount: 20,
            grantCollectorsOnly: false,
          },
          grantName
        );

        // add collection to a drop
        await legendDrop.connect(writer).createDrop([3], "drop_uri");

        legendFulfillment.connect(admin).createFulfiller(10, fulfiller.address);

        await token
          .connect(nonAdmin)
          .approve(
            legendMarketplace.address,
            BigNumber.from("300000000000000000")
          );

        await legendMarketplace
          .connect(nonAdmin)
          .buyTokens([23], token.address, "fulfillment details");
      });

      it("updates accepted tokens", async () => {
        await legendCollection
          .connect(writer)
          .setCollectionAcceptedTokens(3, [token.address]);
        const actual = await legendNFT.getTokenAcceptedTokens(23);
        expect(
          actual.map((address: string) => address.toLowerCase())
        ).to.deep.equal(
          [
            token.address,
            "0x0000000000000000000000000000000000001010",
            "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619",
          ].map((address) => address.toLowerCase())
        );
        expect(await legendNFT.getTokenAcceptedTokens(21)).to.deep.equal([
          token.address,
        ]);
      });

      it("updates base prices", async () => {
        await legendCollection
          .connect(writer)
          .setCollectionBasePrices(3, ["2000000"]);
        expect(await legendNFT.getTokenBasePrices(23)).to.deep.equal([
          BigNumber.from("200000000000000000"),
          BigNumber.from("1200000000000000000"),
          BigNumber.from("200000000000000000"),
        ]);
        expect(await legendNFT.getTokenBasePrices(21)).to.deep.equal([
          BigNumber.from("2000000"),
        ]);
      });

      it("updates fulfiller id", async () => {
        await legendCollection.connect(writer).setCollectionFulfillerId(2, 3);
        expect(await legendNFT.getTokenFulfillerId(23)).to.equal(1);
        expect(await legendNFT.getTokenFulfillerId(21)).to.equal(2);
      });

      it("updates print type", async () => {
        await legendCollection
          .connect(writer)
          .setCollectionPrintType("skirt", 3);
        expect(await legendNFT.getTokenPrintType(23)).to.equal("shirt");
        expect(await legendNFT.getTokenPrintType(21)).to.equal("skirt");
      });

      it("updates discount", async () => {
        await legendCollection.connect(writer).setCollectionDiscount(30, 3);
        expect(await legendNFT.getTokenDiscount(23)).to.equal(20);
        expect(await legendNFT.getTokenDiscount(21)).to.equal(30);
      });

      it("updates collectors only", async () => {
        await legendCollection
          .connect(writer)
          .setCollectionGrantCollectorsOnly(true, 3);
        expect(await legendNFT.getTokenGrantCollectorsOnly(23)).to.equal(false);
        expect(await legendNFT.getTokenGrantCollectorsOnly(21)).to.equal(true);
      });
    });
  });

  describe("rejects wrong fulfiller", () => {
    it("rejects on update", async () => {
      await expect(
        legendCollection.connect(writer).setCollectionFulfillerId(4, 1)
      ).to.be.revertedWith("LegendFulfillment: FulfillerId does not exist.");
    });

    it("rejects on mint", async () => {
      await expect(
        legendCollection.connect(writer).mintCollection(
          amount,
          {
            acceptedTokens,
            basePrices,
            uri: "newurivalue2",
            printType,
            fulfillerId: 6,
            discount: 20,
            grantCollectorsOnly: false,
          },
          grantName
        )
      ).to.be.revertedWith("LegendFulfillment: FulfillerId does not exist.");
    });
  });

  describe("updates discount on purchase", () => {
    it("purchase at discounted price after update, but discount not applied because not collector", async () => {
      await legendCollection.connect(writer).mintCollection(
        amount,
        {
          acceptedTokens,
          basePrices,
          uri: "newurivalue5",
          printType,
          fulfillerId: 1,
          discount: 20,
          grantCollectorsOnly: false,
        },
        grantName
      );

      const prevBalance = await token.balanceOf(nonAdmin.address);

      await token
        .connect(nonAdmin)
        .approve(
          legendMarketplace.address,
          BigNumber.from("200000000000000000")
        );

      await legendMarketplace
        .connect(nonAdmin)
        .buyTokens([15], token.address, "fulfillment details");

      expect(await token.balanceOf(nonAdmin.address)).to.equal(
        prevBalance.sub(BigNumber.from("200000000000000000"))
      );

      const prevBalanceUpdate = await token.balanceOf(nonAdmin.address);

      await token
        .connect(nonAdmin)
        .approve(
          legendMarketplace.address,
          BigNumber.from("200000000000000000")
        );

      await legendMarketplace
        .connect(nonAdmin)
        .buyTokens([16], token.address, "fulfillment details");

      expect(await token.balanceOf(nonAdmin.address)).to.equal(
        prevBalanceUpdate.sub(BigNumber.from("200000000000000000"))
      );
    });
  });

  describe("updates on collectors only", () => {
    it("rejects buyer on collectors updated to true", async () => {
      await legendCollection.connect(writer).mintCollection(
        amount,
        {
          acceptedTokens,
          basePrices,
          uri: "newurivalue5",
          printType,
          fulfillerId: 1,
          discount: 20,
          grantCollectorsOnly: true,
        },
        grantName
      );
      await token
        .connect(nonAdmin)
        .approve(
          legendMarketplace.address,
          BigNumber.from("200000000000000000")
        );

      await expect(
        legendMarketplace
          .connect(nonAdmin)
          .buyTokens([16], token.address, "fulfillment details")
      ).to.be.revertedWith("LegendMarket: Must be authorized grant collector.");
    });
  });
});
