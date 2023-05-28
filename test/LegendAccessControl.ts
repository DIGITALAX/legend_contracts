import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";

describe("LegendAccessControl", () => {
  let legendAccessControl: Contract,
    owner: SignerWithAddress,
    addr1: SignerWithAddress,
    addr2: SignerWithAddress;

  beforeEach(async () => {
    const LegendAccessControl = await ethers.getContractFactory(
      "LegendAccessControl"
    );

    [owner, addr1, addr2] = await ethers.getSigners();

    legendAccessControl = await LegendAccessControl.deploy(
      "LegendAccessControl",
      "LAC"
    );
    await legendAccessControl.deployed();
  });

  it("Should set the right owner", async () => {
    expect(await legendAccessControl.admin()).to.equal(owner.address);
  });

  it("Should return correct isAdmin", async () => {
    expect(await legendAccessControl.isAdmin(owner.address)).to.be.true;
    expect(await legendAccessControl.isAdmin(addr1.address)).to.be.false;
  });

  it("Should allow only admin to remove and update admin", async () => {
    (
      (await expect(
        legendAccessControl.connect(addr1).removeAndUpdateAdmin(addr2.address)
      ).to.be) as any
    ).revertedWith("Only admins can perform this action");
    await legendAccessControl.removeAndUpdateAdmin(addr1.address);
    expect(await legendAccessControl.admin()).to.equal(addr1.address);
  });

  it("Should emit AdminRemoved event when admin is changed", async () => {
    await (
      expect(legendAccessControl.removeAndUpdateAdmin(addr1.address)).to as any
    )
      .emit(legendAccessControl, "AdminRemoved")
      .withArgs(addr1.address);

    expect(await legendAccessControl.isAdmin(addr1.address)).to.be.true;
    expect(await legendAccessControl.isAdmin(owner.address)).to.be.false;
  });
});
