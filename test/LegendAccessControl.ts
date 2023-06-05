import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";

describe("LegendAccessControl", () => {
  let legendAccessControl: Contract,
    owner: SignerWithAddress,
    addr1: SignerWithAddress,
    addr2: SignerWithAddress,
    addr3: SignerWithAddress;

  beforeEach(async () => {
    const LegendAccessControl = await ethers.getContractFactory(
      "LegendAccessControl"
    );

    [owner, addr1, addr2, addr3] = await ethers.getSigners();

    legendAccessControl = await LegendAccessControl.deploy(
      "LegendAccessControl",
      "LAC",
      owner.address
    );
    await legendAccessControl.deployed();
  });

  it("Should only let admins add new admins", async () => {
    expect(await legendAccessControl.addAdmin(addr2.address))
      .to.emit(legendAccessControl, "AdminAdded")
      .withArgs(addr2.address);

    await expect(
      legendAccessControl.connect(addr1).addAdmin(addr3.address)
    ).to.be.revertedWith(
      "LegendAccessControl: Only admins can perform this action"
    );
  });

  it("Should return correct isAdmin", async () => {
    expect(await legendAccessControl.isAdmin(owner.address)).to.be.true;
    expect(await legendAccessControl.isAdmin(addr1.address)).to.be.false;
  });

  it("Should allow only admin to remove", async () => {
    await expect(
      legendAccessControl.connect(addr1).removeAdmin(addr2.address)
    ).to.be.revertedWith(
      "LegendAccessControl: Only admins can perform this action"
    );
    await legendAccessControl.removeAdmin(addr1.address);
    expect(await legendAccessControl.isAdmin(addr1.address)).to.be.false;
  });

  it("Should emit AdminRemoved event when admin is changed", async () => {
    await (expect(legendAccessControl.removeAdmin(addr1.address)).to as any)
      .emit(legendAccessControl, "AdminRemoved")
      .withArgs(addr1.address);

    expect(await legendAccessControl.isAdmin(addr1.address)).to.be.false;
    expect(await legendAccessControl.isAdmin(owner.address)).to.be.true;
  });
});
