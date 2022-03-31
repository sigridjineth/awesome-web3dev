const { expect } = require("chai");
const { ethers } = require("hardhat");
// ethers.js is available in global scope, but to being code explicit, adding the line at the top.
// const { ethers } = require("hardhat");

describe("Token Contract", async() => {
    let [owner, addr1, addr2] = null;
    let joonToken;
    let joonTokenFactory;

    before(async() => {
        [owner, addr1, addr2] = await ethers.getSigners();
        joonTokenFactory = await ethers.getContractFactory("Token");
        joonToken = await joonTokenFactory.deploy();
    });

    it("should assign the total supply of tokens to the owner", async() => {
        const ownerBalance = await joonToken.balanceOf(owner.address);
        expect(await joonToken.totalSupply()).to.equal(ownerBalance);
    });

    it("should transfer tokens between accounts", async() => {
        // Transfer 50 tokens from owner to addr1
        await joonToken.transfer(addr1.address, 50);
        expect(await joonToken.balanceOf(addr1.address)).to.equal(50);

        // Transfer 50 tokens from addr1 to addr2
        await joonToken.transfer(addr1.address, 50);
        expect(await joonToken.balanceOf(addr2.address)).to.equal(50);
    });
});