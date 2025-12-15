const { expect } = require("chai");
const { ethers } = require("hardhat");

function median(arr) {
    arr.sort((a, b) => Number(a) - Number(b));
    return arr[Math.floor(arr.length / 2)];
}

describe("Oracle Manipulation Detection", function () {

    it("detects flash spike manipulation", async function () {

        const Mock = await ethers.getContractFactory("MockPriceFeed");
        const Monitor = await ethers.getContractFactory("OracleMonitor");
        const Protocol = await ethers.getContractFactory("SimpleLendingProtocol");

        // true price baseline
        let truePrice = 100;

        // Create 3 oracles
        const o1 = await Mock.deploy(truePrice);
        const o2 = await Mock.deploy(truePrice);
        const o3 = await Mock.deploy(truePrice);

        const monitor = await Monitor.deploy([o1.address, o2.address, o3.address], 500);
        const protocol = await Protocol.deploy(o1.address);

        await protocol.depositCollateral(1);

        let anomalyTimes = [];

        for (let t = 0; t < 200; t++) {

            // random walk for true price (small noise)
            truePrice *= Math.exp((Math.random() - 0.5) * 0.01);

            // update feeds normally
            await o1.setPrice(Math.round(truePrice + (Math.random() - 0.5)));
            await o2.setPrice(Math.round(truePrice + (Math.random() - 0.5)));
            await o3.setPrice(Math.round(truePrice + (Math.random() - 0.5)));

            // attack at t = 100
            if (t === 100) {
                await o1.setPrice(truePrice * 2); // flash spike
                await protocol.borrow(); // attacker borrows at manipulated price
            }

            // run monitor
            const tx = await monitor.check();
            const receipt = await tx.wait();

            const event = receipt.events.find(e => e.event === "AnomalyDetected");
            if (event) anomalyTimes.push(t);
        }

        const firstDet = anomalyTimes.find(t => t >= 100);

        console.log("Detection latency =", firstDet - 100);

        expect(firstDet).to.be.a("number");
    });

});