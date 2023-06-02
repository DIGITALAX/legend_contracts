import { ethers } from "hardhat";
import { Contract } from "ethers";
import { solidity } from "ethereum-waffle";
import chai from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
chai.use(solidity);
const { expect } = chai;

describe("LegendPayment", function () {
  let accessControl: Contract,
    legendPayment: Contract,
    admin: SignerWithAddress,
    nonAdmin: SignerWithAddress,
    token: Contract;

  beforeEach(async () => {
    [admin, nonAdmin] = await ethers.getSigners();
    const AccessControl = await ethers.getContractFactory(
      "GlobalLegendAccessControl"
    );
    const LegendPayment = await ethers.getContractFactory("LegendPayment");

    accessControl = await AccessControl.deploy("LegendAccessControl", "LAC");
    legendPayment = await LegendPayment.deploy(accessControl.address);

    // deploy test erc20 and transfer to nonAdmin
    const ERC20 = await ethers.getContractFactory("TestToken");
    token = await ERC20.deploy();
  });

  describe("approve tokens and mint", () => {
    beforeEach("verify tokens", async () => {
      await legendPayment.setVerifiedPaymentTokens([
        token.address,
        "0x0000000000000000000000000000000000001010",
        "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619",
      ]);
    });

    it("checks tokens are verified", async () => {
      const actual = (await legendPayment.getVerifiedPaymentTokens()).map(
        (address: string) => address.toLowerCase()
      );
      expect(actual).to.deep.equal(
        [
          token.address,
          "0x0000000000000000000000000000000000001010",
          "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619",
        ].map((address: string) => address.toLowerCase())
      );
    });

    it("fails verification for non-admin", async () => {
      await (
        expect(
          legendPayment
            .connect(nonAdmin)
            .setVerifiedPaymentTokens([
              token.address,
              "0x0000000000000000000000000000000000001010",
              "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619",
            ])
        ).to.be as any
      ).revertedWith("LegendAccessControl: Only admin can perform this action");
    });

    it("updates verified tokens", async () => {
      await legendPayment.setVerifiedPaymentTokens([token.address]);
      expect(await legendPayment.getVerifiedPaymentTokens()).to.deep.equal([
        token.address,
      ]);
    });

    it("updates access control", async () => {
      const oldAddress = accessControl.address;
      const AccessControl = await ethers.getContractFactory(
        "GlobalLegendAccessControl"
      );
      accessControl = await AccessControl.deploy("LegendAccessControl", "LAC");
      (
        expect(await legendPayment.updateAccessControl(accessControl.address))
          .to as any
      )
        .emit(legendPayment, "AccessControlUpdated")
        .withArgs(oldAddress, accessControl.address, admin.address);
      expect(await legendPayment.getAccessControlContract()).to.equal(
        accessControl.address
      );
    });

    it("fails access control update for non-admin", async () => {
      await (
        expect(
          legendPayment.connect(nonAdmin).updateAccessControl(token.address)
        ).to.be as any
      ).revertedWith("LegendAccessControl: Only admin can perform this action");
    });
  });
});
