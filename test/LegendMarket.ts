import { ethers } from "hardhat";
import { BigNumber, Contract } from "ethers";
import { solidity } from "ethereum-waffle";
import chai from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
chai.use(solidity);
const { expect } = chai;

describe("Legend Market", function () {
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
    token: Contract,
    token2: Contract;

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
    token2 = await ERC20.deploy();
    await token2.deployed();
    await token2.transfer(nonAdmin.address, ethers.utils.parseEther("60"));

    // verify payment tokens
    legendPayment
      .connect(admin)
      .setVerifiedPaymentTokens([
        token.address,
        token2.address,
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
    beforeEach("deploy new contracts", async () => {
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
    });
    it("updates access", async () => {
      const old = await legendMarketplace.getAccessControlContract();
      expect(await legendMarketplace.updateAccessControl(accessControl.address))
        .to.emit(legendMarketplace, "AccessControlUpdated")
        .withArgs(old, accessControl.address, admin.address);
      expect(await legendMarketplace.getAccessControlContract()).to.equal(
        accessControl.address
      );
    });
    it("updates fulfillment", async () => {
      const old = await legendMarketplace.getLegendFulfillmentContract();
      expect(
        await legendMarketplace.updateLegendFulfillment(
          legendFulfillment.address
        )
      )
        .to.emit(legendMarketplace, "LegendFulfillmentUpdated")
        .withArgs(old, legendFulfillment.address, admin.address);
      expect(await legendMarketplace.getLegendFulfillmentContract()).to.equal(
        legendFulfillment.address
      );
    });
    it("updates collection", async () => {
      const old = await legendMarketplace.getLegendCollectionContract();
      expect(
        await legendMarketplace.updateLegendCollection(legendCollection.address)
      )
        .to.emit(legendMarketplace, "LegendCollectionUpdated")
        .withArgs(old, legendCollection.address, admin.address);
      expect(await legendMarketplace.getLegendCollectionContract()).to.equal(
        legendCollection.address
      );
    });
    it("updates escrow", async () => {
      const old = await legendMarketplace.getLegendEscrowContract();
      expect(await legendMarketplace.setLegendEscrow(legendEscrow.address))
        .to.emit(legendMarketplace, "LegendEscrowUpdated")
        .withArgs(old, legendEscrow.address, admin.address);
      expect(await legendMarketplace.getLegendEscrowContract()).to.equal(
        legendEscrow.address
      );
    });
    it("updates nft", async () => {
      const old = await legendMarketplace.getLegendNFTContract();
      expect(await legendMarketplace.updateLegendNFT(legendNFT.address))
        .to.emit(legendMarketplace, "LegendNFTUpdated")
        .withArgs(old, legendNFT.address, admin.address);
      expect(await legendMarketplace.getLegendNFTContract()).to.equal(
        legendNFT.address
      );
    });
    it("updates fail for all without admin", async () => {
      await expect(
        legendMarketplace.connect(nonAdmin).updateLegendNFT(legendNFT.address)
      ).to.be.revertedWith(
        "GlobalLegendAccessControl: Only admin can perform this action"
      );

      await expect(
        legendMarketplace
          .connect(nonAdmin)
          .updateLegendCollection(legendCollection.address)
      ).to.be.revertedWith(
        "GlobalLegendAccessControl: Only admin can perform this action"
      );

      await expect(
        legendMarketplace
          .connect(nonAdmin)
          .setLegendEscrow(legendEscrow.address)
      ).to.be.revertedWith(
        "GlobalLegendAccessControl: Only admin can perform this action"
      );

      await expect(
        legendMarketplace
          .connect(nonAdmin)
          .updateAccessControl(accessControl.address)
      ).to.be.revertedWith(
        "GlobalLegendAccessControl: Only admin can perform this action"
      );
    });
  });

  describe("interactions", () => {
    beforeEach("mint collection + add to drop", async () => {
      await legendFactory.createContracts(800, 900, {
        lensHubProxyAddress: legendFactory.address,
        legendFactoryAddress: legendFactory.address,
        URIArrayValue: URIArray,
        grantNameValue: "new grant other",
        editionAmountValue: editionAmount,
      });

      await legendFactory.createContracts(800, 900, {
        lensHubProxyAddress: legendFactory.address,
        legendFactoryAddress: legendFactory.address,
        URIArrayValue: URIArray,
        grantNameValue: "new grant other 2",
        editionAmountValue: editionAmount,
      });

      await legendCollection.mintCollection(
        10,
        {
          acceptedTokens: [token.address],
          basePrices: ["20000"],
          uri: "uri1",
          printType: "shirt",
          fulfillerId: 1,
          discount: 10,
          grantCollectorsOnly: false,
        },
        "new grant other"
      );
      await legendCollection.mintCollection(
        10,
        {
          acceptedTokens: [token.address],
          basePrices: ["20000"],
          uri: "uri1",
          printType: "shirt",
          fulfillerId: 1,
          discount: 10,
          grantCollectorsOnly: false,
        },
        "new grant other"
      );
      await legendDrop.createDrop([1, 2], "drop_uri_1");

      await legendCollection.mintCollection(
        4,
        {
          acceptedTokens: [token.address],
          basePrices: ["20000"],
          uri: "uri1",
          printType: "shirt",
          fulfillerId: 1,
          discount: 10,
          grantCollectorsOnly: false,
        },
        "new grant other"
      );
      await legendCollection.mintCollection(
        4,
        {
          acceptedTokens: [token.address],
          basePrices: ["20000"],
          uri: "uri1",
          printType: "shirt",
          fulfillerId: 1,
          discount: 10,
          grantCollectorsOnly: false,
        },
        "new grant other 2"
      );
      await legendDrop.createDrop([3, 4], "drop_uri_2");

      // mint with token2
      await legendCollection.mintCollection(
        4,
        {
          acceptedTokens: [token.address, token2.address],
          basePrices: ["50000000000000000000", "50000000000000000000"],
          uri: "uri5",
          printType: "shirt",
          fulfillerId: 1,
          discount: 10,
          grantCollectorsOnly: false,
        },
        "new grant other 2"
      );
      await legendDrop.createDrop([5], "drop_uri_3");
    });

    describe("buy second token address", async () => {
      beforeEach("approve", async () => {
        token2
          .connect(nonAdmin)
          .approve(
            legendMarketplace.address,
            BigNumber.from("50000000000000000000")
          );
      });

      it("purchases with correct second token", async () => {
        expect(
          await legendMarketplace
            .connect(nonAdmin)
            .buyTokens([30], token2.address, "fulfillment data")
        )
          .to.emit(legendMarketplace, "TokensBought")
          .withArgs([30], nonAdmin.address, token2.address);
      });

      it("sends correct second funds to creator", async () => {
        const balanceBefore = await token2.balanceOf(admin.address);
        await legendMarketplace
          .connect(nonAdmin)
          .buyTokens([31], token2.address, "fulfillment data");

        const fulPer = await legendFulfillment.getFulfillerPercent(1);

        const expectedBalance = balanceBefore.add(
          BigNumber.from("50000000000000000000").sub(
            BigNumber.from("50000000000000000000").mul(fulPer).div(100)
          )
        );

        expect(await token2.balanceOf(admin.address)).to.equal(expectedBalance);
      });

      it("sends correct funds to fulfiller", async () => {
        const balanceBefore = await token2.balanceOf(fulfiller.address);
        await legendMarketplace
          .connect(nonAdmin)
          .buyTokens([31], token2.address, "fulfillment data");

        const fulPer = await legendFulfillment.getFulfillerPercent(1);

        const expectedBalance = balanceBefore.add(
          BigNumber.from("50000000000000000000").mul(fulPer).div(100)
        );

        expect(await token2.balanceOf(fulfiller.address)).to.equal(
          expectedBalance
        );
      });
    });

    describe("buy token", () => {
      beforeEach("approve", async () => {
        token
          .connect(nonAdmin)
          .approve(
            legendMarketplace.address,
            BigNumber.from("50000000000000000000")
          );
      });

      it("sends funds to creator", async () => {
        const balanceBefore = await token.balanceOf(admin.address);
        await legendMarketplace
          .connect(nonAdmin)
          .buyTokens(
            [1, 5, 10, 11, 27, 26, 22],
            token.address,
            "fulfillment data"
          );

        const fulPer = await legendFulfillment.getFulfillerPercent(1);
        const expectedBalance = balanceBefore.add(
          BigNumber.from("140000").sub(
            BigNumber.from("140000").mul(fulPer).div(100)
          )
        );

        expect(await token.balanceOf(admin.address)).to.equal(expectedBalance);
      });

      it("sends funds to fulfiller", async () => {
        const balanceBefore = await token.balanceOf(fulfiller.address);
        await legendMarketplace
          .connect(nonAdmin)
          .buyTokens(
            [1, 5, 10, 11, 27, 26, 22],
            token.address,
            "fulfillment data"
          );

        const fulPer = await legendFulfillment.getFulfillerPercent(1);
        const expectedBalance = balanceBefore.add(
          BigNumber.from("140000").mul(fulPer).div(100)
        );

        expect(await token.balanceOf(fulfiller.address)).to.equal(
          expectedBalance
        );
      });

      it("purchase one token", async () => {
        expect(
          await legendMarketplace
            .connect(nonAdmin)
            .buyTokens([6], token.address, "fulfillment data")
        )
          .to.emit(legendMarketplace, "TokensBought")
          .withArgs([6], nonAdmin.address, token.address);
      });
      it("purchase multiple tokens", async () => {
        expect(
          await legendMarketplace
            .connect(nonAdmin)
            .buyTokens(
              [1, 5, 10, 11, 27, 26, 22],
              token.address,
              "fulfillment data"
            )
        )
          .to.emit(legendMarketplace, "TokensBought")
          .withArgs(
            [1, 5, 10, 11, 27, 26, 22],
            nonAdmin.address,
            token.address
          );
      });

      it("reject purchase if not approved", async () => {
        await expect(
          legendMarketplace
            .connect(admin)
            .buyTokens(
              [1, 5, 10, 11, 27, 26, 22],
              token.address,
              "fulfillment data"
            )
        ).to.be.revertedWith("LegendMarket: Insufficient Approval Allowance");
      });

      it("reject purchase if token not in escrow", async () => {
        await legendMarketplace
          .connect(nonAdmin)
          .buyTokens(
            [1, 5, 10, 11, 27, 26, 22],
            token.address,
            "fulfillment data"
          );

        await expect(
          legendMarketplace
            .connect(nonAdmin)
            .buyTokens([22, 10, 3], token.address, "fulfillment data")
        ).to.be.revertedWith("LegendMarket: Token must be owned by Escrow");
      });
      it("reject purchase if insufficient funds", async () => {
        await legendFactory.createContracts(800, 900, {
          lensHubProxyAddress: legendFactory.address,
          legendFactoryAddress: legendFactory.address,
          URIArrayValue: URIArray,
          grantNameValue: "new grant other 3",
          editionAmountValue: editionAmount,
        });

        token
          .connect(nonAdmin)
          .approve(
            legendMarketplace.address,
            BigNumber.from("200000000000000000000")
          );
        await legendCollection.mintCollection(
          4,
          {
            acceptedTokens: [token.address],
            basePrices: ["50000000000000000000"],
            uri: "uri5",
            printType: "shirt",
            fulfillerId: 1,
            discount: 10,
            grantCollectorsOnly: false,
          },
          "new grant other 3"
        );
        await legendCollection.mintCollection(
          4,
          {
            acceptedTokens: [token.address],
            basePrices: ["50000000000000000000"],
            uri: "uri5",
            printType: "shirt",
            fulfillerId: 1,
            discount: 10,
            grantCollectorsOnly: false,
          },
          "new grant other 3"
        );
        await legendDrop.createDrop([6, 7], "drop_uri_3");

        await expect(
          legendMarketplace
            .connect(nonAdmin)
            .buyTokens([34, 37, 38], token.address, "fulfillment data")
        ).to.be.revertedWith("ERC20: transfer amount exceeds balance");
      });

      it("reject purchase if insufficient approval", async () => {
        token
          .connect(nonAdmin)
          .approve(
            legendMarketplace.address,
            BigNumber.from("40000000000000000000")
          );
        // await legendCollection.mintCollection(
        //   "uri1",
        //   10,
        //   "col 1",
        //   [token.address],
        //   ["50000000000000000000"]
        // );
        // await legendCollection.mintCollection(
        //   "uri2",
        //   10,
        //   "col 2",
        //   [token.address],
        //   ["50000000000000000000"]
        // );
        // await legendDrop.createDrop([5, 6], "drop_uri_3");

        await expect(
          legendMarketplace
            .connect(nonAdmin)
            .buyTokens([29], token.address, "fulfillment data")
        ).to.be.revertedWith("LegendMarket: Insufficient Approval Allowance");
      });

      it("reject purchase if token not approved / accepted for that nft + collection", async () => {
        await expect(
          legendMarketplace.buyTokens(
            [13],
            "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619",
            "fulfillment data"
          )
        ).to.be.revertedWith(
          "LegendMarket: Chosen token address is not an accepted token for the collection"
        );
      });
    });

    describe("sold", () => {
      beforeEach("approve and buy for different collections", async () => {
        token
          .connect(nonAdmin)
          .approve(
            legendMarketplace.address,
            BigNumber.from("60000000000000000000")
          );
        legendMarketplace
          .connect(nonAdmin)
          .buyTokens([1, 12, 24, 27, 28], token.address, "fulfillment data");
      });
      it("map how many have been sold in collection", async () => {
        expect(await legendMarketplace.getCollectionSoldCount(1)).to.equal(1);
        expect(await legendMarketplace.getCollectionSoldCount(2)).to.equal(1);
        expect(await legendMarketplace.getCollectionSoldCount(3)).to.equal(1);
        expect(await legendMarketplace.getCollectionSoldCount(4)).to.equal(2);
      });
      it("specific tokens sold in collection", async () => {
        expect(
          await legendMarketplace.getTokensSoldCollection(1)
        ).to.deep.equal([BigNumber.from("1")]);
        expect(
          await legendMarketplace.getTokensSoldCollection(2)
        ).to.deep.equal([BigNumber.from("12")]);
        expect(
          await legendMarketplace.getTokensSoldCollection(3)
        ).to.deep.equal([BigNumber.from("24")]);
        expect(
          await legendMarketplace.getTokensSoldCollection(4)
        ).to.deep.equal([BigNumber.from("27"), BigNumber.from("28")]);
      });
    });
  });

  describe("rejects discount / collector on not collected", () => {
    beforeEach("mint", async () => {
      await legendFactory.createContracts(800, 900, {
        lensHubProxyAddress: legendFactory.address,
        legendFactoryAddress: legendFactory.address,
        URIArrayValue: URIArray,
        grantNameValue: "new grant other 2",
        editionAmountValue: editionAmount,
      });

      await legendCollection.mintCollection(
        10,
        {
          acceptedTokens: [token.address],
          basePrices: ["20000"],
          uri: "uri1",
          printType: "shirt",
          fulfillerId: 1,
          discount: 10,
          grantCollectorsOnly: false,
        },
        "new grant other 2"
      );
    });

    it("doesn't give discount if not collected", async () => {
      const balance = await token.balanceOf(nonAdmin.address);

      await token
        .connect(nonAdmin)
        .approve(
          legendMarketplace.address,
          BigNumber.from("50000000000000000000")
        );

      await legendMarketplace
        .connect(nonAdmin)
        .buyTokens([6], token.address, "fulfillment data");

      expect(await token.balanceOf(nonAdmin.address)).to.equal(
        balance.sub(BigNumber.from("20000"))
      );
    });

    it("doesn't allow purchase if not collected", async () => {
      await legendCollection.mintCollection(
        10,
        {
          acceptedTokens: [token.address],
          basePrices: ["20000"],
          uri: "uri1",
          printType: "shirt",
          fulfillerId: 1,
          discount: 10,
          grantCollectorsOnly: true,
        },
        "new grant other 2"
      );

      await token
        .connect(nonAdmin)
        .approve(
          legendMarketplace.address,
          BigNumber.from("50000000000000000000")
        );

      await expect(
        legendMarketplace
          .connect(nonAdmin)
          .buyTokens([17], token.address, "fulfillment data")
      ).to.be.revertedWith("LegendMarket: Must be authorized grant collector.");
    });
  });

  describe("order getters and setters", () => {
    let block: any;
    beforeEach("mint", async () => {
      await legendFactory.createContracts(800, 900, {
        lensHubProxyAddress: legendFactory.address,
        legendFactoryAddress: legendFactory.address,
        URIArrayValue: URIArray,
        grantNameValue: "new grant other 2",
        editionAmountValue: editionAmount,
      });

      await legendCollection.mintCollection(
        10,
        {
          acceptedTokens: [token.address],
          basePrices: ["20000"],
          uri: "uri1",
          printType: "shirt",
          fulfillerId: 1,
          discount: 10,
          grantCollectorsOnly: false,
        },
        "new grant other 2"
      );

      await token
        .connect(nonAdmin)
        .approve(
          legendMarketplace.address,
          BigNumber.from("80000000000000000000")
        );

      await legendMarketplace
        .connect(nonAdmin)
        .buyTokens([6, 7], token.address, "fulfillment data");
      const blockNumber = await ethers.provider.getBlockNumber();
      block = await ethers.provider.getBlock(blockNumber);
    });

    it("get the order supply", async () => {
      expect(await legendMarketplace.getOrderSupply()).to.equal(2);
    });

    it("get the order token", async () => {
      expect(await legendMarketplace.getOrderTokenId(1)).to.equal(6);
      expect(await legendMarketplace.getOrderTokenId(2)).to.equal(7);
    });

    it("get the order stamp", async () => {
      expect(await legendMarketplace.getOrderTimestamp(1)).to.equal(
        block.timestamp
      );
      expect(await legendMarketplace.getOrderTimestamp(2)).to.equal(
        block.timestamp
      );
    });

    it("get the order details", async () => {
      expect(await legendMarketplace.getOrderDetails(1)).to.equal(
        "fulfillment data"
      );
      expect(await legendMarketplace.getOrderDetails(2)).to.equal(
        "fulfillment data"
      );
    });

    it("get the order buyer", async () => {
      expect(await legendMarketplace.getOrderBuyer(1)).to.equal(
        nonAdmin.address
      );
      expect(await legendMarketplace.getOrderBuyer(2)).to.equal(
        nonAdmin.address
      );
    });

    it("get the order chosen address", async () => {
      expect(await legendMarketplace.getOrderChosenAddress(1)).to.equal(
        token.address
      );
      expect(await legendMarketplace.getOrderChosenAddress(2)).to.equal(
        token.address
      );
    });

    it("get the order status", async () => {
      expect(await legendMarketplace.getOrderStatus(1)).to.equal("ordered");
      expect(await legendMarketplace.getOrderStatus(2)).to.equal("ordered");
    });

    it("get the order is fulfilled", async () => {
      expect(await legendMarketplace.getOrderIsFulfilled(1)).to.equal(false);
      expect(await legendMarketplace.getOrderIsFulfilled(2)).to.equal(false);
    });

    it("get the order fulfiller id", async () => {
      expect(await legendMarketplace.getOrderFulfillerId(1)).to.equal(1);
      expect(await legendMarketplace.getOrderFulfillerId(2)).to.equal(1);
    });

    it("set the order is fulfilled", async () => {
      expect(await legendMarketplace.connect(fulfiller).setOrderisFulfilled(1))
        .to.emit(legendMarketplace, "OrderIsFulfilled")
        .withArgs(1, fulfiller.address);
      expect(await legendMarketplace.connect(fulfiller).setOrderisFulfilled(2))
        .to.emit(legendMarketplace, "OrderIsFulfilled")
        .withArgs(2, fulfiller.address);
    });

    it("only fulfiller can set is fulfilled", async () => {
      await expect(
        legendMarketplace.connect(nonAdmin).setOrderisFulfilled(1)
      ).to.be.revertedWith(
        "LegendMarket: Only the fulfiller can update this status."
      );
      await expect(
        legendMarketplace.connect(nonAdmin).setOrderisFulfilled(2)
      ).to.be.revertedWith(
        "LegendMarket: Only the fulfiller can update this status."
      );
    });

    it("set the order status", async () => {
      expect(await legendMarketplace.connect(fulfiller).setOrderStatus(1, "newstatus"))
        .to.emit(legendMarketplace, "UpdateOrderStatus")
        .withArgs(1, "newstatus", fulfiller.address);
      expect(await legendMarketplace.connect(fulfiller).setOrderStatus(2, "newstatus"))
        .to.emit(legendMarketplace, "UpdateOrderStatus")
        .withArgs(2, "newstatus", fulfiller.address);
    });

    it("only fulfiller can set order status", async () => {
      await expect(
        legendMarketplace.connect(nonAdmin).setOrderStatus(1, "status")
      ).to.be.revertedWith(
        "LegendMarket: Only the fulfiller can update this status."
      );
      await expect(
        legendMarketplace.connect(nonAdmin).setOrderStatus(2, "status")
      ).to.be.revertedWith(
        "LegendMarket: Only the fulfiller can update this status."
      );
    });

    it("set the order details", async () => {
      expect(
        await legendMarketplace.connect(nonAdmin).setOrderDetails(1, "newinfo")
      )
        .to.emit(legendMarketplace, "UpdateOrderDetails")
        .withArgs(1, "newinfo", nonAdmin.address);
      expect(
        await legendMarketplace
          .connect(nonAdmin)
          .setOrderDetails(2, "newinfo")
      )
        .to.emit(legendMarketplace, "UpdateOrderDetails")
        .withArgs(2, "newinfo", nonAdmin.address);
    });

    it("only buyer can set order details", async () => {
      await expect(
        legendMarketplace.setOrderDetails(1, "newinfo")
      ).to.be.revertedWith(
        "LegendMarket: Only the buyer can update their order details."
      );
      await expect(
        legendMarketplace.setOrderDetails(2, "newinfo")
      ).to.be.revertedWith(
        "LegendMarket: Only the buyer can update their order details."
      );
    });
  });
});
