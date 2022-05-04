import { expect } from "chai";
import { ethers, waffle } from "hardhat";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { stETH, stETHcrvPool, crvLPtoken, yvault } from "../constants";

describe("Strategy", function () {
  it("Should execute investment", async function () {
    const signers: SignerWithAddress[] = await ethers.getSigners();
    const investor = signers[0];
    const provider = waffle.provider;

    const Strategy = await ethers.getContractFactory("Strategy");
    const strategy = await Strategy.deploy(
      stETH, // Lido
      stETHcrvPool, // stETH-ETH Curve pool
      crvLPtoken, // Curve LP token
      yvault // Yearn vault
    );

    await strategy.deployed();

    const initialBalance = await provider.getBalance(investor.address);

    const amount = ethers.utils.parseEther("100.0");

    const investTX = await strategy.invest(amount, {value: amount});
    await investTX.wait();

    //const disinvestTX = await strategy.disinvest();
    //await disinvestTX.wait();

    const finalBalance = await provider.getBalance(investor.address);

    expect(initialBalance).to.be.gt(finalBalance);
  });
});
