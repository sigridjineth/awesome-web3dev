const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Counter", async function() {
    let counterFactory;
    let counter;

    before(async() => {
        counterFactory = await ethers.getContractFactory("Counter");
        counter = await counterFactory.deploy("I am DSRV!");
    });

    it("should return the new greeting once it's changed", async() => {
        expect(await counter.greet()).to.equal("I am DSRV!");

        const setCounterTx = await counter.setGreeting("You are also DSRV!");

        // wait until the transaction is mined
        await setCounterTx.wait();

        expect(await counter.greet()).to.equal("You are also DSRV!");
    });

    it("should increment counter by one", async() => {
        // given
        expect(await counter.getCount()).to.equal(0);

        // when
        await counter.incrementCounter();

        // then
        expect(await counter.getCount()).to.equal(1);
    });

    it("should decrement counter by one", async() => {
        // given
        expect(await counter.getCount()).to.equal(1);

        // when
        await counter.decrementCounter();

        // then
        expect(await counter.getCount()).to.equal(0);
    });
});