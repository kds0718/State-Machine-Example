const MakeWidgets = artifacts.require('MakeWidgets');
const SupplyChain = artifacts.require('SupplyChain');
const toBytes32 = require("./utils/toBytes32.js");

const padInt = (value) => {
    return web3.padLeft(web3.toHex(value).slice(2), 64);
  };

const timeTravel = function (time) {
    return new Promise((resolve, reject) => {
      web3.currentProvider.sendAsync({
        jsonrpc: "2.0",
        method: "evm_increaseTime",
        params: [time], // 86400 is num seconds in day
        id: new Date().getTime()
      }, (err, result) => {
        if(err){ return reject(err) }
        return resolve(result)
      });
    })
  }

const mineBlock = function () {
    return new Promise((resolve, reject) => {
      web3.currentProvider.sendAsync({
        jsonrpc: "2.0",
        method: "evm_mine"
      }, (err, result) => {
        if(err){ return reject(err) }
        return resolve(result)
      });
    })
  }

contract('SupplyChain', function(accounts){
    const owner = accounts[0];

    let makewidgets;
    let supplychain; 
    let widgetAddress; 

    beforeEach(async function() {
        makewidgets = await MakeWidgets.new();
        await makewidgets.widgetOrder(); 
        widgetAddress = await makewidgets.orderList(0);
    });

    describe('SETUP ', async function() {
        it('Should start in setup state', async function() { 
            let result = await SupplyChain.at(widgetAddress).getCurrentStateId();
            assert.equal(web3.toUtf8(result), 'setup');
        });
        it('Should allow you to set a start time for production', async function(){
            let block = web3.eth.blockNumber; 
            let currentTimestamp = web3.eth.getBlock(block).timestamp;
            let result = await SupplyChain.at(widgetAddress).setStartTime(200000);
            let time = result.logs[0].args._startTime; 
            assert.equal(currentTimestamp+200000, time.toNumber());
        });
    })
    
    describe('PRODUCTION', async function(){
        it('Should allow you to start production after start time', async function() {
            await SupplyChain.at(widgetAddress).setStartTime(200000);
            await timeTravel(300000);
            await mineBlock();
            let result = await SupplyChain.at(widgetAddress).startProduction(); 
            let resultOne = await SupplyChain.at(widgetAddress).getCurrentStateId();
            assert.equal(web3.toUtf8(resultOne), 'production');
        });
        it('Should allow you to end production during production', async function() {
            await SupplyChain.at(widgetAddress).setStartTime(200000);
            await timeTravel(300000);
            await mineBlock();
            let result = await SupplyChain.at(widgetAddress).startProduction(); 
            await timeTravel(1000);
            await mineBlock();
            let resultOne = await SupplyChain.at(widgetAddress).endProduction(); 
            let resultTwo = await SupplyChain.at(widgetAddress).productionEndTime(); 
            let resultThree = await SupplyChain.at(widgetAddress).getCurrentStateId();
            assert.isAbove(resultTwo, 0);
            assert.equal(web3.toUtf8(resultThree), 'quality');
        })
    })
})