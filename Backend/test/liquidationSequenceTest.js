const { ethers } = require("hardhat");
const { expect } = require('chai')

const activePoolC = require ("../client/src/artifacts/TestScript/ActivePool.sol/ActivePool.json")
const borrowerOperationsC = require ( "../client/src/artifacts/TestScript/BorrowerOperations.sol/BorrowerOperations.json");
const communityIssuanceC = require ( "../client/src/artifacts/TestScript/CommunityIssuance.sol/CommunityIssuance.json");
const defaultPoolC = require ( "../client/src/artifacts/TestScript/DefaultPool.sol/DefaultPool.json");
const collSurplusC = require ( "../client/src/artifacts/TestScript/CollSurplusPool.sol/CollSurplusPool.json");
const gasPoolC = require ( "../client/src/artifacts/TestScript/GasPool.sol/GasPool.json");
const zqtyStakingC = require ( "../client/src/artifacts/TestScript/ZQTYStaking.sol/ZQTYStaking.json");
const zqtyTokenC = require ( "../client/src/artifacts/TestScript/ZQTYTokenTester.sol/ZQTYTokenTester.json");
const zusdTokenC = require ( "../client/src/artifacts/TestScript/ZUSDTokenTester.sol/ZUSDTokenTester.json");
const lockupFactoryC = require ( "../client/src/artifacts/TestScript/LockupContractFactory.sol/LockupContractFactory.json");
const multiSigC = require ( "../client/src/artifacts/TestScript/Multisig.sol/MultiSig.json");
const priceFeedC = require ( "../client/src/artifacts/TestScript/PriceFeedTestnet.sol/PriceFeedTestnet.json");
const sortedTrovesC = require ( "../client/src/artifacts/TestScript/SortedTroves.sol/SortedTroves.json");
const stabilityPoolC = require ( "../client/src/artifacts/TestScript/StabilityPool.sol/StabilityPool.json");
const troveManager1C = require ( "../client/src/artifacts/TestScript/TroveManager1.sol/TroveManager1.json");
const troveManager2C = require ( "../client/src/artifacts/TestScript/TroveManager2.sol/TroveManager2.json");
const troveManager3C = require ( "../client/src/artifacts/TestScript/TroveManager3.sol/TroveManager3.json");
const hintHelpersC = require ( "../client/src/artifacts/TestScript/HintHelpers.sol/HintHelpers.json");
const proxyC = require ( "../client/src/artifacts/TestScript/Proxy.sol/Proxy.json");
const lpTokenWrapperC = require ( "../client/src/artifacts/TestScript/Unipool.sol/LPTokenWrapper.json");
const ercToken = require ( "../client/src/artifacts/TestScript/AAAERC.sol/MyToken.json");


  describe('Zero loan Unit Tests', async function () {
    let activePool;
    let borrowerOperations;
    let communityIssuance;
    let defaultPool;
    let zqtyStaking;
    let priceFeed;
    let sortedTroves;
    let stabilityPool;
    let proxy;
    let lockupFactory;
    let multiSig;
    let lpToken;
    let zqtyToken;
    let troveManager1;
    let troveManager2;
    let troveManager3;
    let hintHelpers;
    let gasPool;
    let collSurplus;
    let zusdToken;
    let ercToken1;
    let ercToken2;
    let ercToken3;
    let ercToken4;
    let ercToken5
    
    let activePoolCntrct;
    let borrowerOperationsCntrct;
    let communityIssuanceCntrct;
    let defaultPoolCntrct;
    let collSurplusCntrct;
    let gasPoolCntrct;
    let zqtyStakingCntrct;
    let lockupFactoryCntrct;
    let multiSigCntrct;
    let priceFeedCntrct;
    let proxyCntrct;
    let sortedTrovesCntrct;
    let stabilityPoolCntrct;
    let troveManager1Cntrct;
    let troveManager2Cntrct;
    let troveManager3Cntrct;
    let lpTokenWrapperCntrct;
    let hintHelpersCntrct;
    let ercToken1Cntrct;
    let ercToken2Cntrct;
    let ercToken3Cntrct;
    let ercToken4Cntrct;
    let ercToken5Cntrct;
    let zqtyTokenCntrct;
    let zusdTokenCntrct;

    let activePoolAddress;
    let borrowerOperationsAddress;
    let communityIssuanceAddress;
    let defaultPoolAddress;
    let collSurplusAddress;
    let gasPoolAddress;
    let zqtyStakingAddress;
    let zqtyTokenAddress;
    let zusdTokenAddress;
    let lockupFactoryAddress;
    let multiSigAddress;
    let priceFeedAddress;
    let proxyAddress;
    let sortedTrovesAddress;
    let stabilityPoolAddress;
    let troveManager1Address;
    let troveManager2Address;
    let troveManager3Address;
    let lpTokenWrapperAddress;
    let hintHelpersAddress;
    let ercToken1Address;
    let ercToken2Address;
    let ercToken3Address;
    let ercToken4Address;
    let ercToken5Address;
    
    let activePoolContract;
    let borrowerOperationsContract;
    let communityIssuanceContract;
    let defaultPoolContract;
    let collSurplusContract;
    let gasPoolContract;
    let zqtyStakingContract;
    let zqtyTokenContract ;
    let zusdTokenContract;
    let lockupFactoryContract;
    let multiSigContract;
    let priceFeedContract;
    let proxyContract;
    let sortedTrovesContract;
    let stabilityPoolContract;
    let troveManager1Contract;
    let troveManager2Contract;
    let troveManager3Contract;
    let lpTokenWrapperContract;
    let hintHelpersContract;
    let ercToken1Contract;
    let ercToken2Contract;
    let ercToken3Contract;
    let ercToken4Contract;
    let ercToken5Contract;

    let signers;
  
    async function hint(zusd, eth) {
      const liquidationReserve = await troveManager1Contract.ZUSD_GAS_COMPENSATION()
      const expectedFee = await troveManager2Contract.getBorrowingFeeWithDecay(zusd)
      const expectedDebt = zusd.add(expectedFee).add(liquidationReserve)
  
      const _1e20 = ethers.utils.parseUnits('100')
      let NICR = eth.mul(_1e20).div(expectedDebt)
      NICR = BigInt(NICR)
  
      let numTroves = await sortedTrovesContract.getSize(0)
      let numTrials = numTroves.mul(15)
  
      let { 0: approxHint } = await hintHelpersContract.getApproxHint(0, NICR, numTrials, 42)  // random seed of 42
  
      return { 0: upperHint, 1: lowerHint } = await sortedTrovesContract.findInsertPosition('0', NICR, approxHint, approxHint)
    }

    async function openTrovewithEth(signerId, ethAmount, zusdAmount, upperHint, lowerHint) {
      await borrowerOperationsContract.connect(signers[signerId]).openTrovewithEth(5000000000000000, zusdAmount, upperHint, lowerHint, {value: ethAmount});
    }

    async function openTrovewithTokens(signerId, tokenId, tokenAmount, zusdAmount, upperHint, lowerHint) {
      await borrowerOperationsContract.connect(signers[signerId]).openTrovewithTokens(5000000000000000, tokenId, tokenAmount, zusdAmount, upperHint, lowerHint);
    }

    async function liquidateinSequence(tokenId, n) {
      try {
        const price = [
            ethers.utils.parseUnits('1500'),
            ethers.utils.parseUnits('1500'),
            ethers.utils.parseUnits('1500'),
            ethers.utils.parseUnits('100'),
            ethers.utils.parseUnits('10'),
            ethers.utils.parseUnits('0.1'),
          ];

        await priceFeedContract.connect(signers[19]).setTokenPrice(tokenId, price[tokenId]);
        await troveManager3Contract.connect(signers[19]).liquidateTroves(tokenId, n);
      }
      catch(error) {
        console.log(error.reason);
        return(error.reason);
      }
    }

    async function approval(signerId, tokenId, tokenAmount) {

      const ercTokenContracts = [
        null, // 0th index unused
        ercToken1Contract,
        ercToken2Contract,
        ercToken3Contract,
        ercToken4Contract,
        ercToken5Contract
      ];
        
      const ercTokenContract = ercTokenContracts[tokenId];

      await ercTokenContract.connect(signers[signerId]).approve(borrowerOperationsAddress, tokenAmount);
    }

    describe('Sequence Liquidation', async function () {
      before(async () => {
        try {
  
          activePool = await ethers.getContractFactory("ActivePool");
          borrowerOperations = await ethers.getContractFactory("BorrowerOperations");
          communityIssuance = await ethers.getContractFactory("CommunityIssuance");
          defaultPool = await ethers.getContractFactory("DefaultPool");
          zqtyStaking = await ethers.getContractFactory("ZQTYStaking");
          priceFeed = await ethers.getContractFactory("PriceFeedTestnet");
          sortedTroves = await ethers.getContractFactory("SortedTroves");
          stabilityPool = await ethers.getContractFactory("StabilityPool");
          proxy = await ethers.getContractFactory("Proxy");
          lockupFactory = await ethers.getContractFactory("LockupContractFactory");
          multiSig = await ethers.getContractFactory("MultiSig");
          lpToken = await ethers.getContractFactory("LPTokenWrapper");
          zqtyToken = await ethers.getContractFactory("ZQTYTokenTester");
          troveManager1 = await ethers.getContractFactory("TroveManager1");
          troveManager2 = await ethers.getContractFactory("TroveManager2");
          troveManager3 = await ethers.getContractFactory("TroveManager3");
          hintHelpers = await ethers.getContractFactory("HintHelpers");
          gasPool = await ethers.getContractFactory("GasPool");
          collSurplus = await ethers.getContractFactory("CollSurplusPool");
          zusdToken = await ethers.getContractFactory("ZUSDTokenTester");
          ercToken1 = await ethers.getContractFactory("MyToken");
          ercToken2 = await ethers.getContractFactory("MyToken");
          ercToken3 = await ethers.getContractFactory("MyToken");
          ercToken4 = await ethers.getContractFactory("MyToken");
          ercToken5 = await ethers.getContractFactory("MyToken");
  
          activePoolCntrct = await activePool.deploy();
          borrowerOperationsCntrct = await borrowerOperations.deploy();
          communityIssuanceCntrct = await communityIssuance.deploy();
          defaultPoolCntrct = await defaultPool.deploy();
          collSurplusCntrct = await collSurplus.deploy();
          gasPoolCntrct = await gasPool.deploy();
          zqtyStakingCntrct = await zqtyStaking.deploy();
          lockupFactoryCntrct = await lockupFactory.deploy();
          multiSigCntrct = await multiSig.deploy("zqty","zqty",["0xB5874deeec872e6BEB3df88BDc628b8fAc774C08","0xca4d795FD2213a138d675A5d56caC66dC4bf537a"]);
          priceFeedCntrct = await priceFeed.deploy();
          proxyCntrct = await proxy.deploy("0xB5874deeec872e6BEB3df88BDc628b8fAc774C08");
          sortedTrovesCntrct = await sortedTroves.deploy();
          stabilityPoolCntrct = await stabilityPool.deploy();
          troveManager1Cntrct = await troveManager1.deploy();
          troveManager2Cntrct = await troveManager2.deploy();
          troveManager3Cntrct = await troveManager3.deploy();
          lpTokenWrapperCntrct = await lpToken.deploy();
          hintHelpersCntrct = await hintHelpers.deploy();
          ercToken1Cntrct = await ercToken1.deploy();
          ercToken2Cntrct = await ercToken2.deploy();
          ercToken3Cntrct = await ercToken3.deploy();
          ercToken4Cntrct = await ercToken4.deploy();
          ercToken5Cntrct = await ercToken5.deploy();
          zqtyTokenCntrct = await zqtyToken.deploy(communityIssuanceCntrct.address,zqtyStakingCntrct.address,lockupFactoryCntrct.address,proxyCntrct.address,lpTokenWrapperCntrct.address,multiSigCntrct.address);
          zusdTokenCntrct = await zusdToken.deploy(troveManager1Cntrct.address,troveManager2Cntrct.address,troveManager3Cntrct.address,stabilityPoolCntrct.address, borrowerOperationsCntrct.address);
  
          activePoolAddress = activePoolCntrct.address;
          borrowerOperationsAddress = borrowerOperationsCntrct.address;
          communityIssuanceAddress = communityIssuanceCntrct.address;
          defaultPoolAddress = defaultPoolCntrct.address;
          collSurplusAddress = collSurplusCntrct.address;
          gasPoolAddress = gasPoolCntrct.address;
          zqtyStakingAddress = zqtyStakingCntrct.address;
          zqtyTokenAddress = zqtyTokenCntrct.address;
          zusdTokenAddress = zusdTokenCntrct.address;
          lockupFactoryAddress = lockupFactoryCntrct.address;
          multiSigAddress = multiSigCntrct.address;
          priceFeedAddress = priceFeedCntrct.address;
          proxyAddress = proxyCntrct.address;
          sortedTrovesAddress = sortedTrovesCntrct.address;
          stabilityPoolAddress = stabilityPoolCntrct.address;
          troveManager1Address = troveManager1Cntrct.address;
          troveManager2Address = troveManager2Cntrct.address;
          troveManager3Address = troveManager3Cntrct.address;
          lpTokenWrapperAddress = lpTokenWrapperCntrct.address;
          hintHelpersAddress = hintHelpersCntrct.address;
          ercToken1Address = ercToken1Cntrct.address;
          ercToken2Address = ercToken2Cntrct.address;
          ercToken3Address = ercToken3Cntrct.address;
          ercToken4Address = ercToken4Cntrct.address;
          ercToken5Address = ercToken5Cntrct.address;
  
          console.log('');
  
          console.log(`ActivePoolAddress = "${activePoolAddress}"`);
          console.log(`BorrowerOperationsAddress = "${borrowerOperationsAddress}"`);
          console.log(`CommunityIssuanceAddress = "${communityIssuanceAddress}"`);
          console.log(`DefaultPoolAddress = "${defaultPoolAddress}"`);
          console.log(`ZUSDTokenAddress = "${zusdTokenAddress}"`);
          console.log(`ZQTYTokenAddress = "${zqtyTokenAddress}"`);
          console.log(`ZQTYStakingAddress = "${zqtyStakingAddress}"`);
          console.log(`TroveManagerAddress1 = "${troveManager1Address}"`);
          console.log(`TroveManagerAddress2 = "${troveManager2Address}"`);
          console.log(`TroveManagerAddress3 = "${troveManager3Address}"`);
          console.log(`SortedTrovesAddress = "${sortedTrovesAddress}"`);
          console.log(`StabilityPoolAddress = "${stabilityPoolAddress}"`);
          console.log(`PriceFeedAddress = "${priceFeedAddress}"`);
          console.log(`ProxyAddress = "${proxyAddress}"`);
          console.log(`LockupFactoryAddress = "${lockupFactoryAddress}"`);
          console.log(`MultiSigAddress = "${multiSigAddress}"`);
          console.log(`LPTokenWrapperAddress = "${lpTokenWrapperAddress}"`);
          console.log(`GasPoolAddress = "${gasPoolAddress}"`);
          console.log(`CollSurplusAddress = "${collSurplusAddress}"`);
          console.log(`HintHelpersAddress = "${hintHelpersAddress}"`);
  
          console.log(`erctoken1Address = "${ercToken1Address}"`);
          console.log(`erctoken2Address = "${ercToken2Address}"`);
          console.log(`erctoken3Address = "${ercToken3Address}"`);
          console.log(`erctoken4Address = "${ercToken4Address}"`);
          console.log(`erctoken5Address = "${ercToken5Address}"`);
  
          signers = await ethers.getSigners();
  
          // console.log('');
  
          // console.log(signers.length);
  
          console.log('');
        
          activePoolContract = new ethers.Contract(activePoolAddress, activePoolC.abi, signers[0]);
          borrowerOperationsContract = new ethers.Contract(borrowerOperationsAddress, borrowerOperationsC.abi, signers[0]);
          communityIssuanceContract = new ethers.Contract(communityIssuanceAddress, communityIssuanceC.abi, signers[0]);
          defaultPoolContract = new ethers.Contract(defaultPoolAddress, defaultPoolC.abi, signers[0]);
          collSurplusContract = new ethers.Contract(collSurplusAddress, collSurplusC.abi, signers[0]);
          gasPoolContract = new ethers.Contract(gasPoolAddress, gasPoolC.abi, signers[0]);
          zqtyStakingContract = new ethers.Contract(zqtyStakingAddress, zqtyStakingC.abi, signers[0]);
          zqtyTokenContract = new ethers.Contract(zqtyTokenAddress, zqtyTokenC.abi, signers[0]);
          zusdTokenContract = new ethers.Contract(zusdTokenAddress, zusdTokenC.abi, signers[0]);
          lockupFactoryContract = new ethers.Contract(lockupFactoryAddress, lockupFactoryC.abi, signers[0]);
          multiSigContract = new ethers.Contract(multiSigAddress, multiSigC.abi, signers[0]);
          priceFeedContract = new ethers.Contract(priceFeedAddress, priceFeedC.abi, signers[0]);
          proxyContract = new ethers.Contract(proxyAddress, proxyC.abi, signers[0]);
          sortedTrovesContract = new ethers.Contract(sortedTrovesAddress, sortedTrovesC.abi, signers[0]);
          stabilityPoolContract = new ethers.Contract(stabilityPoolAddress, stabilityPoolC.abi, signers[0]);
          troveManager1Contract = new ethers.Contract(troveManager1Address, troveManager1C.abi, signers[0]);
          troveManager2Contract = new ethers.Contract(troveManager2Address, troveManager2C.abi, signers[0]);
          troveManager3Contract = new ethers.Contract(troveManager3Address, troveManager3C.abi, signers[0]);
          lpTokenWrapperContract = new ethers.Contract(lpTokenWrapperAddress, lpTokenWrapperC.abi, signers[0]);
          hintHelpersContract = new ethers.Contract(hintHelpersAddress, hintHelpersC.abi, signers[0]);
          ercToken1Contract = new ethers.Contract(ercToken1Address, ercToken.abi, signers[0]);
          ercToken2Contract = new ethers.Contract(ercToken2Address, ercToken.abi, signers[0]);
          ercToken3Contract = new ethers.Contract(ercToken3Address, ercToken.abi, signers[0]);
          ercToken4Contract = new ethers.Contract(ercToken4Address, ercToken.abi, signers[0]);
          ercToken5Contract = new ethers.Contract(ercToken5Address, ercToken.abi, signers[0]);
  
  
          const activePoolTransaction = await activePoolContract.setAddresses(
            borrowerOperationsAddress,
            troveManager1Address,
            troveManager2Address,
            troveManager3Address,
            stabilityPoolAddress,
            defaultPoolAddress);
      
          const borrowerOperationsTransaction = await borrowerOperationsContract.setAddresses(
            troveManager1Address,
            troveManager2Address,
            troveManager3Address,
            activePoolAddress,
            defaultPoolAddress,
            stabilityPoolAddress,
            gasPoolAddress,
            collSurplusAddress,
            priceFeedAddress,
            sortedTrovesAddress,
            zusdTokenAddress,
            zqtyStakingAddress);
      
          const communityIssuanceTransaction = await communityIssuanceContract.setAddresses(
            zqtyTokenAddress,stabilityPoolAddress);
          
          const defaultPoolTransaction = await defaultPoolContract.setAddresses(
            borrowerOperationsAddress,troveManager1Address,troveManager2Address,troveManager3Address,activePoolAddress);
      
          const collSurplusTransaction = await collSurplusContract.setAddresses(
            borrowerOperationsAddress,troveManager1Address,troveManager2Address,troveManager3Address,activePoolAddress);
      
          const zqtyStakingTransaction = await zqtyStakingContract.setAddresses(
            zqtyTokenAddress,
            zusdTokenAddress,
            troveManager1Address,
            troveManager2Address,
            troveManager3Address,
            borrowerOperationsAddress,
            activePoolAddress);
          
          const lockupFactoryTransaction = await lockupFactoryContract.setZQTYTokenAddress(zqtyTokenAddress);
      
          const sortedTrovesTransaction = await sortedTrovesContract.setParams(100,troveManager1Address,troveManager2Address,troveManager3Address,borrowerOperationsAddress);
      
          const stabilityPoolTransaction = await stabilityPoolContract.setAddresses(
            borrowerOperationsAddress,
            troveManager1Address,
            troveManager2Address,
            troveManager3Address,
            activePoolAddress,
            zusdTokenAddress,
            sortedTrovesAddress,
            priceFeedAddress,
            communityIssuanceAddress);
      
          const troveManager1Transaction = await troveManager1Contract.setAddresses(
            borrowerOperationsAddress,
            troveManager2Address,
            troveManager3Address,
            activePoolAddress,
            defaultPoolAddress,
            stabilityPoolAddress,
            gasPoolAddress,
            collSurplusAddress,
            zusdTokenAddress,
            sortedTrovesAddress,
            zqtyTokenAddress,
            zqtyStakingAddress);
      
          const troveManager2Transaction = await troveManager2Contract.setAddresses(
            borrowerOperationsAddress,
            troveManager1Address,
            activePoolAddress,
            defaultPoolAddress,
            stabilityPoolAddress,
            gasPoolAddress,
            collSurplusAddress,
            priceFeedAddress,
            zusdTokenAddress,
            sortedTrovesAddress,
            zqtyTokenAddress,
            zqtyStakingAddress);
          
          const troveManager3Transaction = await troveManager3Contract.setAddresses(
            borrowerOperationsAddress,
            troveManager1Address,
            troveManager2Address,
            activePoolAddress,
            defaultPoolAddress,
            stabilityPoolAddress,
            gasPoolAddress,
            collSurplusAddress,
            priceFeedAddress,
            zusdTokenAddress,
            sortedTrovesAddress,
            zqtyTokenAddress);
      
          const hintHelpersTransaction = await hintHelpersContract.setAddresses(sortedTrovesAddress,troveManager1Address,troveManager2Address,troveManager3Address);
      
          const collateralTokenTransactions = await borrowerOperationsContract.addCollTokenAddress([ercToken1Address,ercToken2Address,ercToken3Address,ercToken4Address,ercToken5Address]);
          
          let p = BigInt(2000000000000000000000);
  
          await activePoolTransaction.wait();
          await borrowerOperationsTransaction.wait();
          await communityIssuanceTransaction.wait();
          await defaultPoolTransaction.wait();
          await collSurplusTransaction.wait();
          await zqtyStakingTransaction.wait();
          await lockupFactoryTransaction.wait();
          await sortedTrovesTransaction.wait();
          await stabilityPoolTransaction.wait();
          await troveManager1Transaction.wait();
          await troveManager2Transaction.wait();
          await troveManager3Transaction.wait();
          await hintHelpersTransaction.wait();
          await collateralTokenTransactions.wait();
  
          let i;
          for(i = 1; i < 20; i++) { 
            const transfer1 = await ercToken1Contract.transfer(signers[i].address,BigInt(50000000000000000000000));
            const transfer2 = await ercToken2Contract.transfer(signers[i].address,BigInt(50000000000000000000000));
            const transfer3 = await ercToken3Contract.transfer(signers[i].address,BigInt(50000000000000000000000));
            const transfer4 = await ercToken4Contract.transfer(signers[i].address,BigInt(50000000000000000000000));
            const transfer5 = await ercToken5Contract.transfer(signers[i].address,BigInt(50000000000000000000000));
  
            await transfer1.wait();
            await transfer2.wait();
            await transfer3.wait();
            await transfer4.wait();
            await transfer5.wait();
          }
        }
        catch(error) {
          console.log(error.reason);
          throw (error.reason);
        }
  
      })

      it("OpenTrove with 5 ETH and 1800 ZUSD", async () => {
        const signerId = 1;
        const eth = ethers.utils.parseUnits('5')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,eth);
      
        // let previousBalance = await zusdTokenContract.balanceOf(signers[1].address);
        await openTrovewithEth(signerId, eth, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
        // console.log("Signer 1's ZUSD Balance:");
        // console.log(`Previous value: ${previousBalance}`);
        // console.log(`After value: ${afterBalance}`);
        // console.log('');      
      })

      it("OpenTrove with 1.25 ETH and 1800 ZUSD", async () => {
        const signerId = 2;
        const eth = ethers.utils.parseUnits('1.25')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,eth);

        await openTrovewithEth(signerId, eth, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })

      it("OpenTrove with 1.15 ETH and 1800 ZUSD", async () => {
        const signerId = 3;
        const eth = ethers.utils.parseUnits('1.15')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,eth);

        await openTrovewithEth(signerId, eth, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })

      it("OpenTrove with 5 WETH Token and 1800 ZUSD", async () => {
        const signerId = 4;
        const tokenId = 1;
        const token = ethers.utils.parseUnits('5')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })
      
      it("OpenTrove with 1.25 WETH Token and 1800 ZUSD", async () => {
        const signerId = 5;
        const tokenId = 1;
        const token = ethers.utils.parseUnits('1.25')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })

      it("OpenTrove with 1.15 WETH Token and 1800 ZUSD", async () => {
        const signerId = 6;
        const tokenId = 1;
        const token = ethers.utils.parseUnits('1.15')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })

      it("OpenTrove with 5 WBTC Token and 1800 ZUSD", async () => {
        const signerId = 7;
        const tokenId = 2;
        const token = ethers.utils.parseUnits('5')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })
      
      it("OpenTrove with 1.25 WBTC Token and 1800 ZUSD", async () => {
        const signerId = 8;
        const tokenId = 2;
        const token = ethers.utils.parseUnits('1.25')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })

      it("OpenTrove with 1.15 WBTC Token and 1800 ZUSD", async () => {
        const signerId = 9;
        const tokenId = 2;
        const token = ethers.utils.parseUnits('1.15')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })

      it("OpenTrove with 10 WBNB Token and 1800 ZUSD", async () => {
        const signerId = 10;
        const tokenId = 3;
        const token = ethers.utils.parseUnits('10')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })
      
      it("OpenTrove with 8.5 WBNB Token and 1800 ZUSD", async () => {
        const signerId = 11;
        const tokenId = 3;
        const token = ethers.utils.parseUnits('8.5')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');    
      })

      it("OpenTrove with 8.25 WBNB Token and 1800 ZUSD", async () => {
        const signerId = 12;
        const tokenId = 3;
        const token = ethers.utils.parseUnits('8.25')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log(''); 
      })

      it("OpenTrove with 250 WSOL Token and 1800 ZUSD", async () => {
        const signerId = 13;
        const tokenId = 4;
        const token = ethers.utils.parseUnits('250')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })
      
      it("OpenTrove with 125 WSOL Token and 1800 ZUSD", async () => {
        const signerId = 14;
        const tokenId = 4;
        const token = ethers.utils.parseUnits('125')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');     
      })

      it("OpenTrove with 120 WSOL Token and 1800 ZUSD", async () => {
        const signerId = 15;
        const tokenId = 4;
        const token = ethers.utils.parseUnits('120')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })

      it("OpenTrove with 5000 USDC Token and 1800 ZUSD", async () => {
        const signerId = 16;
        const tokenId = 5;
        const token = ethers.utils.parseUnits('5000')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })
      
      it("OpenTrove with 2750 USDC Token and 1800 ZUSD", async () => {
        const signerId = 17;
        const tokenId = 5;
        const token = ethers.utils.parseUnits('2750')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })

      it("OpenTrove with 2500 USDC Token and 1800 ZUSD", async () => {
        const signerId = 18;
        const tokenId = 5;
        const token = ethers.utils.parseUnits('2500')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })

      // it("Sequence Liquidate with same price ETH Troves", async () => {  
      //     const tokenId = 0;

      //     let previousBalance = await zusdTokenContract.balanceOf(signers[19].address);
      //     expect(previousBalance).to.equal(0);

      //     let error = await liquidateinSequence(tokenId, 2);

      //     expect(error).to.include("revert", "VM Exception while processing transaction: reverted with reason string 'TroveManager: nothing to liquidate'");

      //     console.log('');
      // })

      async function size() {
          try {
              let j;
              let troves = [];
              for(j = 0; j < 6; j++) { 
                  let result = await sortedTrovesContract.getSize(j);
                  troves[j] = result;
              }
              
              return troves;
          }
          catch(error) {
              console.log(error);        
          }
      }

      it("Size", async () => {  
          console.log('');

          let troves = await size();

          expect(troves.length).to.equal(6);
          
          console.log('');
      })

      // it("Revert when Sequence Liquidate all the ETH Troves", async () => {  
      //     const tokenId = 0;

      //     let previousBalance = await zusdTokenContract.balanceOf(signers[19].address);
      //     expect(previousBalance).to.equal(0);

      //     let error = await liquidateinSequence(tokenId, 3);

      //     expect(error).to.include("revert", "VM Exception while processing transaction: reverted with reason string 'TroveManager: n greater than the number of troves'");

      //     console.log('');
      // })

      it("Sequence Liquidate 2 ETH Troves", async () => {  
          const tokenId = 0;
          const zusd = ethers.utils.parseUnits('400')

          let previousBalance = await zusdTokenContract.balanceOf(signers[19].address);
          expect(previousBalance).to.equal(0);

          await liquidateinSequence(tokenId, 2);

          let afterBalance = await zusdTokenContract.balanceOf(signers[19].address);
          expect(afterBalance).to.equal(zusd);

          console.log('');
      })

      // it("Revert when Sequence Liquidate all the WETH Troves", async () => {  
      //     const tokenId = 1;

      //     let error = await liquidateinSequence(tokenId, 3);

      //     expect(error).to.include("revert", "VM Exception while processing transaction: reverted with reason string 'TroveManager: n greater than the number of troves'");

      //     console.log('');
      // })

      it("Sequence Liquidate 2 WETH Troves", async () => {  
          const tokenId = 1;
          const zusd = ethers.utils.parseUnits('800')

          await liquidateinSequence(tokenId, 2);

          let afterBalance = await zusdTokenContract.balanceOf(signers[19].address);
          expect(afterBalance).to.equal(zusd);

          console.log('');
      })

      // it("Revert when Sequence Liquidate all the WBTC Troves", async () => {  
      //     const tokenId = 2;

      //     let error = await liquidateinSequence(tokenId, 3);

      //     expect(error).to.include("revert", "VM Exception while processing transaction: reverted with reason string 'TroveManager: n greater than the number of troves'");

      //     console.log('');
      // })

      it("Sequence Liquidate 2 WBTC Troves", async () => {  
          const tokenId = 2;
          const zusd = ethers.utils.parseUnits('1200')

          await liquidateinSequence(tokenId, 2);

          let afterBalance = await zusdTokenContract.balanceOf(signers[19].address);
          expect(afterBalance).to.equal(zusd);

          console.log('');
      })

      // it("Revert when Sequence Liquidate all the WBNB Troves", async () => {  
      //     const tokenId = 3;

      //     let error = await liquidateinSequence(tokenId, 3);

      //     expect(error).to.include("revert", "VM Exception while processing transaction: reverted with reason string 'TroveManager: n greater than the number of troves'");

      //     console.log('');
      // })

      it("Sequence Liquidate 2 WBNB Troves", async () => {  
          const tokenId = 3;
          const zusd = ethers.utils.parseUnits('1600')

          await liquidateinSequence(tokenId, 2);

          let afterBalance = await zusdTokenContract.balanceOf(signers[19].address);
          expect(afterBalance).to.equal(zusd);

          console.log('');
      })

      // it("Revert when Sequence Liquidate all the WSOL Troves", async () => {  
      //     const tokenId = 4;

      //     let error = await liquidateinSequence(tokenId, 3);

      //     expect(error).to.include("revert", "VM Exception while processing transaction: reverted with reason string 'TroveManager: n greater than the number of troves'");

      //     console.log('');
      // })

      it("Sequence Liquidate 2 WSOL Troves", async () => {  
          const tokenId = 4;
          const zusd = ethers.utils.parseUnits('2000')

          await liquidateinSequence(tokenId, 2);

          let afterBalance = await zusdTokenContract.balanceOf(signers[19].address);
          expect(afterBalance).to.equal(zusd);

          console.log('');
      })

      // it("Revert when Sequence Liquidate all the USDC Troves", async () => {  
      //     const tokenId = 5;

      //     let error = await liquidateinSequence(tokenId, 3);

      //     expect(error).to.include("revert", "VM Exception while processing transaction: reverted with reason string 'TroveManager: n greater than the number of troves'");

      //     console.log('');
      // })

      it("Sequence Liquidate 2 USDC Troves", async () => {  
          const tokenId = 5;
          const zusd = ethers.utils.parseUnits('2400')

          await liquidateinSequence(tokenId, 2);

          let afterBalance = await zusdTokenContract.balanceOf(signers[19].address);
          expect(afterBalance).to.equal(zusd);

          console.log('');
      })
    })

    console.log('');

    describe('Random Liquidation', async function () {
      before(async () => {
        try {
  
          activePool = await ethers.getContractFactory("ActivePool");
          borrowerOperations = await ethers.getContractFactory("BorrowerOperations");
          communityIssuance = await ethers.getContractFactory("CommunityIssuance");
          defaultPool = await ethers.getContractFactory("DefaultPool");
          zqtyStaking = await ethers.getContractFactory("ZQTYStaking");
          priceFeed = await ethers.getContractFactory("PriceFeedTestnet");
          sortedTroves = await ethers.getContractFactory("SortedTroves");
          stabilityPool = await ethers.getContractFactory("StabilityPool");
          proxy = await ethers.getContractFactory("Proxy");
          lockupFactory = await ethers.getContractFactory("LockupContractFactory");
          multiSig = await ethers.getContractFactory("MultiSig");
          lpToken = await ethers.getContractFactory("LPTokenWrapper");
          zqtyToken = await ethers.getContractFactory("ZQTYTokenTester");
          troveManager1 = await ethers.getContractFactory("TroveManager1");
          troveManager2 = await ethers.getContractFactory("TroveManager2");
          troveManager3 = await ethers.getContractFactory("TroveManager3");
          hintHelpers = await ethers.getContractFactory("HintHelpers");
          gasPool = await ethers.getContractFactory("GasPool");
          collSurplus = await ethers.getContractFactory("CollSurplusPool");
          zusdToken = await ethers.getContractFactory("ZUSDTokenTester");
          ercToken1 = await ethers.getContractFactory("MyToken");
          ercToken2 = await ethers.getContractFactory("MyToken");
          ercToken3 = await ethers.getContractFactory("MyToken");
          ercToken4 = await ethers.getContractFactory("MyToken");
          ercToken5 = await ethers.getContractFactory("MyToken");
  
          activePoolCntrct = await activePool.deploy();
          borrowerOperationsCntrct = await borrowerOperations.deploy();
          communityIssuanceCntrct = await communityIssuance.deploy();
          defaultPoolCntrct = await defaultPool.deploy();
          collSurplusCntrct = await collSurplus.deploy();
          gasPoolCntrct = await gasPool.deploy();
          zqtyStakingCntrct = await zqtyStaking.deploy();
          lockupFactoryCntrct = await lockupFactory.deploy();
          multiSigCntrct = await multiSig.deploy("zqty","zqty",["0xB5874deeec872e6BEB3df88BDc628b8fAc774C08","0xca4d795FD2213a138d675A5d56caC66dC4bf537a"]);
          priceFeedCntrct = await priceFeed.deploy();
          proxyCntrct = await proxy.deploy("0xB5874deeec872e6BEB3df88BDc628b8fAc774C08");
          sortedTrovesCntrct = await sortedTroves.deploy();
          stabilityPoolCntrct = await stabilityPool.deploy();
          troveManager1Cntrct = await troveManager1.deploy();
          troveManager2Cntrct = await troveManager2.deploy();
          troveManager3Cntrct = await troveManager3.deploy();
          lpTokenWrapperCntrct = await lpToken.deploy();
          hintHelpersCntrct = await hintHelpers.deploy();
          ercToken1Cntrct = await ercToken1.deploy();
          ercToken2Cntrct = await ercToken2.deploy();
          ercToken3Cntrct = await ercToken3.deploy();
          ercToken4Cntrct = await ercToken4.deploy();
          ercToken5Cntrct = await ercToken5.deploy();
          zqtyTokenCntrct = await zqtyToken.deploy(communityIssuanceCntrct.address,zqtyStakingCntrct.address,lockupFactoryCntrct.address,proxyCntrct.address,lpTokenWrapperCntrct.address,multiSigCntrct.address);
          zusdTokenCntrct = await zusdToken.deploy(troveManager1Cntrct.address,troveManager2Cntrct.address,troveManager3Cntrct.address,stabilityPoolCntrct.address, borrowerOperationsCntrct.address);
  
          activePoolAddress = activePoolCntrct.address;
          borrowerOperationsAddress = borrowerOperationsCntrct.address;
          communityIssuanceAddress = communityIssuanceCntrct.address;
          defaultPoolAddress = defaultPoolCntrct.address;
          collSurplusAddress = collSurplusCntrct.address;
          gasPoolAddress = gasPoolCntrct.address;
          zqtyStakingAddress = zqtyStakingCntrct.address;
          zqtyTokenAddress = zqtyTokenCntrct.address;
          zusdTokenAddress = zusdTokenCntrct.address;
          lockupFactoryAddress = lockupFactoryCntrct.address;
          multiSigAddress = multiSigCntrct.address;
          priceFeedAddress = priceFeedCntrct.address;
          proxyAddress = proxyCntrct.address;
          sortedTrovesAddress = sortedTrovesCntrct.address;
          stabilityPoolAddress = stabilityPoolCntrct.address;
          troveManager1Address = troveManager1Cntrct.address;
          troveManager2Address = troveManager2Cntrct.address;
          troveManager3Address = troveManager3Cntrct.address;
          lpTokenWrapperAddress = lpTokenWrapperCntrct.address;
          hintHelpersAddress = hintHelpersCntrct.address;
          ercToken1Address = ercToken1Cntrct.address;
          ercToken2Address = ercToken2Cntrct.address;
          ercToken3Address = ercToken3Cntrct.address;
          ercToken4Address = ercToken4Cntrct.address;
          ercToken5Address = ercToken5Cntrct.address;
  
          console.log('');
  
          console.log(`ActivePoolAddress = "${activePoolAddress}"`);
          console.log(`BorrowerOperationsAddress = "${borrowerOperationsAddress}"`);
          console.log(`CommunityIssuanceAddress = "${communityIssuanceAddress}"`);
          console.log(`DefaultPoolAddress = "${defaultPoolAddress}"`);
          console.log(`ZUSDTokenAddress = "${zusdTokenAddress}"`);
          console.log(`ZQTYTokenAddress = "${zqtyTokenAddress}"`);
          console.log(`ZQTYStakingAddress = "${zqtyStakingAddress}"`);
          console.log(`TroveManagerAddress1 = "${troveManager1Address}"`);
          console.log(`TroveManagerAddress2 = "${troveManager2Address}"`);
          console.log(`TroveManagerAddress3 = "${troveManager3Address}"`);
          console.log(`SortedTrovesAddress = "${sortedTrovesAddress}"`);
          console.log(`StabilityPoolAddress = "${stabilityPoolAddress}"`);
          console.log(`PriceFeedAddress = "${priceFeedAddress}"`);
          console.log(`ProxyAddress = "${proxyAddress}"`);
          console.log(`LockupFactoryAddress = "${lockupFactoryAddress}"`);
          console.log(`MultiSigAddress = "${multiSigAddress}"`);
          console.log(`LPTokenWrapperAddress = "${lpTokenWrapperAddress}"`);
          console.log(`GasPoolAddress = "${gasPoolAddress}"`);
          console.log(`CollSurplusAddress = "${collSurplusAddress}"`);
          console.log(`HintHelpersAddress = "${hintHelpersAddress}"`);
  
          console.log(`erctoken1Address = "${ercToken1Address}"`);
          console.log(`erctoken2Address = "${ercToken2Address}"`);
          console.log(`erctoken3Address = "${ercToken3Address}"`);
          console.log(`erctoken4Address = "${ercToken4Address}"`);
          console.log(`erctoken5Address = "${ercToken5Address}"`);
  
          signers = await ethers.getSigners();
  
          // console.log('');
  
          // console.log(signers.length);
  
          console.log('');
        
          activePoolContract = new ethers.Contract(activePoolAddress, activePoolC.abi, signers[0]);
          borrowerOperationsContract = new ethers.Contract(borrowerOperationsAddress, borrowerOperationsC.abi, signers[0]);
          communityIssuanceContract = new ethers.Contract(communityIssuanceAddress, communityIssuanceC.abi, signers[0]);
          defaultPoolContract = new ethers.Contract(defaultPoolAddress, defaultPoolC.abi, signers[0]);
          collSurplusContract = new ethers.Contract(collSurplusAddress, collSurplusC.abi, signers[0]);
          gasPoolContract = new ethers.Contract(gasPoolAddress, gasPoolC.abi, signers[0]);
          zqtyStakingContract = new ethers.Contract(zqtyStakingAddress, zqtyStakingC.abi, signers[0]);
          zqtyTokenContract = new ethers.Contract(zqtyTokenAddress, zqtyTokenC.abi, signers[0]);
          zusdTokenContract = new ethers.Contract(zusdTokenAddress, zusdTokenC.abi, signers[0]);
          lockupFactoryContract = new ethers.Contract(lockupFactoryAddress, lockupFactoryC.abi, signers[0]);
          multiSigContract = new ethers.Contract(multiSigAddress, multiSigC.abi, signers[0]);
          priceFeedContract = new ethers.Contract(priceFeedAddress, priceFeedC.abi, signers[0]);
          proxyContract = new ethers.Contract(proxyAddress, proxyC.abi, signers[0]);
          sortedTrovesContract = new ethers.Contract(sortedTrovesAddress, sortedTrovesC.abi, signers[0]);
          stabilityPoolContract = new ethers.Contract(stabilityPoolAddress, stabilityPoolC.abi, signers[0]);
          troveManager1Contract = new ethers.Contract(troveManager1Address, troveManager1C.abi, signers[0]);
          troveManager2Contract = new ethers.Contract(troveManager2Address, troveManager2C.abi, signers[0]);
          troveManager3Contract = new ethers.Contract(troveManager3Address, troveManager3C.abi, signers[0]);
          lpTokenWrapperContract = new ethers.Contract(lpTokenWrapperAddress, lpTokenWrapperC.abi, signers[0]);
          hintHelpersContract = new ethers.Contract(hintHelpersAddress, hintHelpersC.abi, signers[0]);
          ercToken1Contract = new ethers.Contract(ercToken1Address, ercToken.abi, signers[0]);
          ercToken2Contract = new ethers.Contract(ercToken2Address, ercToken.abi, signers[0]);
          ercToken3Contract = new ethers.Contract(ercToken3Address, ercToken.abi, signers[0]);
          ercToken4Contract = new ethers.Contract(ercToken4Address, ercToken.abi, signers[0]);
          ercToken5Contract = new ethers.Contract(ercToken5Address, ercToken.abi, signers[0]);
  
  
          const activePoolTransaction = await activePoolContract.setAddresses(
            borrowerOperationsAddress,
            troveManager1Address,
            troveManager2Address,
            troveManager3Address,
            stabilityPoolAddress,
            defaultPoolAddress);
      
          const borrowerOperationsTransaction = await borrowerOperationsContract.setAddresses(
            troveManager1Address,
            troveManager2Address,
            troveManager3Address,
            activePoolAddress,
            defaultPoolAddress,
            stabilityPoolAddress,
            gasPoolAddress,
            collSurplusAddress,
            priceFeedAddress,
            sortedTrovesAddress,
            zusdTokenAddress,
            zqtyStakingAddress);
      
          const communityIssuanceTransaction = await communityIssuanceContract.setAddresses(
            zqtyTokenAddress,stabilityPoolAddress);
          
          const defaultPoolTransaction = await defaultPoolContract.setAddresses(
            borrowerOperationsAddress,troveManager1Address,troveManager2Address,troveManager3Address,activePoolAddress);
      
          const collSurplusTransaction = await collSurplusContract.setAddresses(
            borrowerOperationsAddress,troveManager1Address,troveManager2Address,troveManager3Address,activePoolAddress);
      
          const zqtyStakingTransaction = await zqtyStakingContract.setAddresses(
            zqtyTokenAddress,
            zusdTokenAddress,
            troveManager1Address,
            troveManager2Address,
            troveManager3Address,
            borrowerOperationsAddress,
            activePoolAddress);
          
          const lockupFactoryTransaction = await lockupFactoryContract.setZQTYTokenAddress(zqtyTokenAddress);
      
          const sortedTrovesTransaction = await sortedTrovesContract.setParams(100,troveManager1Address,troveManager2Address,troveManager3Address,borrowerOperationsAddress);
      
          const stabilityPoolTransaction = await stabilityPoolContract.setAddresses(
            borrowerOperationsAddress,
            troveManager1Address,
            troveManager2Address,
            troveManager3Address,
            activePoolAddress,
            zusdTokenAddress,
            sortedTrovesAddress,
            priceFeedAddress,
            communityIssuanceAddress);
      
          const troveManager1Transaction = await troveManager1Contract.setAddresses(
            borrowerOperationsAddress,
            troveManager2Address,
            troveManager3Address,
            activePoolAddress,
            defaultPoolAddress,
            stabilityPoolAddress,
            gasPoolAddress,
            collSurplusAddress,
            zusdTokenAddress,
            sortedTrovesAddress,
            zqtyTokenAddress,
            zqtyStakingAddress);
      
          const troveManager2Transaction = await troveManager2Contract.setAddresses(
            borrowerOperationsAddress,
            troveManager1Address,
            activePoolAddress,
            defaultPoolAddress,
            stabilityPoolAddress,
            gasPoolAddress,
            collSurplusAddress,
            priceFeedAddress,
            zusdTokenAddress,
            sortedTrovesAddress,
            zqtyTokenAddress,
            zqtyStakingAddress);
          
          const troveManager3Transaction = await troveManager3Contract.setAddresses(
            borrowerOperationsAddress,
            troveManager1Address,
            troveManager2Address,
            activePoolAddress,
            defaultPoolAddress,
            stabilityPoolAddress,
            gasPoolAddress,
            collSurplusAddress,
            priceFeedAddress,
            zusdTokenAddress,
            sortedTrovesAddress,
            zqtyTokenAddress);
      
          const hintHelpersTransaction = await hintHelpersContract.setAddresses(sortedTrovesAddress,troveManager1Address,troveManager2Address,troveManager3Address);
      
          const collateralTokenTransactions = await borrowerOperationsContract.addCollTokenAddress([ercToken1Address,ercToken2Address,ercToken3Address,ercToken4Address,ercToken5Address]);
          
          let p = BigInt(2000000000000000000000);
  
          await activePoolTransaction.wait();
          await borrowerOperationsTransaction.wait();
          await communityIssuanceTransaction.wait();
          await defaultPoolTransaction.wait();
          await collSurplusTransaction.wait();
          await zqtyStakingTransaction.wait();
          await lockupFactoryTransaction.wait();
          await sortedTrovesTransaction.wait();
          await stabilityPoolTransaction.wait();
          await troveManager1Transaction.wait();
          await troveManager2Transaction.wait();
          await troveManager3Transaction.wait();
          await hintHelpersTransaction.wait();
          await collateralTokenTransactions.wait();
  
          let i;
          for(i = 1; i < 20; i++) { 
            const transfer1 = await ercToken1Contract.transfer(signers[i].address,BigInt(50000000000000000000000));
            const transfer2 = await ercToken2Contract.transfer(signers[i].address,BigInt(50000000000000000000000));
            const transfer3 = await ercToken3Contract.transfer(signers[i].address,BigInt(50000000000000000000000));
            const transfer4 = await ercToken4Contract.transfer(signers[i].address,BigInt(50000000000000000000000));
            const transfer5 = await ercToken5Contract.transfer(signers[i].address,BigInt(50000000000000000000000));
  
            await transfer1.wait();
            await transfer2.wait();
            await transfer3.wait();
            await transfer4.wait();
            await transfer5.wait();
          }
        }
        catch(error) {
          console.log(error.reason);
          throw (error.reason);
        }
  
      })

      it("OpenTrove with 5 ETH and 1800 ZUSD", async () => {
        const signerId = 1;
        const eth = ethers.utils.parseUnits('5')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,eth);
      
        // let previousBalance = await zusdTokenContract.balanceOf(signers[1].address);
        await openTrovewithEth(signerId, eth, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
        // console.log("Signer 1's ZUSD Balance:");
        // console.log(`Previous value: ${previousBalance}`);
        // console.log(`After value: ${afterBalance}`);
        // console.log('');      
      })

      it("OpenTrove with 1.25 ETH and 1800 ZUSD", async () => {
        const signerId = 2;
        const eth = ethers.utils.parseUnits('1.25')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,eth);

        await openTrovewithEth(signerId, eth, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })

      it("OpenTrove with 1.15 ETH and 1800 ZUSD", async () => {
        const signerId = 3;
        const eth = ethers.utils.parseUnits('1.15')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,eth);

        await openTrovewithEth(signerId, eth, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })

      it("OpenTrove with 5 WETH Token and 1800 ZUSD", async () => {
        const signerId = 4;
        const tokenId = 1;
        const token = ethers.utils.parseUnits('5')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })
      
      it("OpenTrove with 1.25 WETH Token and 1800 ZUSD", async () => {
        const signerId = 5;
        const tokenId = 1;
        const token = ethers.utils.parseUnits('1.25')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })

      it("OpenTrove with 1.15 WETH Token and 1800 ZUSD", async () => {
        const signerId = 6;
        const tokenId = 1;
        const token = ethers.utils.parseUnits('1.15')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })

      it("OpenTrove with 5 WBTC Token and 1800 ZUSD", async () => {
        const signerId = 7;
        const tokenId = 2;
        const token = ethers.utils.parseUnits('5')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })
      
      it("OpenTrove with 1.25 WBTC Token and 1800 ZUSD", async () => {
        const signerId = 8;
        const tokenId = 2;
        const token = ethers.utils.parseUnits('1.25')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })

      it("OpenTrove with 1.15 WBTC Token and 1800 ZUSD", async () => {
        const signerId = 9;
        const tokenId = 2;
        const token = ethers.utils.parseUnits('1.15')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })

      it("OpenTrove with 10 WBNB Token and 1800 ZUSD", async () => {
        const signerId = 10;
        const tokenId = 3;
        const token = ethers.utils.parseUnits('10')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })
      
      it("OpenTrove with 8.5 WBNB Token and 1800 ZUSD", async () => {
        const signerId = 11;
        const tokenId = 3;
        const token = ethers.utils.parseUnits('8.5')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');    
      })

      it("OpenTrove with 8.25 WBNB Token and 1800 ZUSD", async () => {
        const signerId = 12;
        const tokenId = 3;
        const token = ethers.utils.parseUnits('8.25')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log(''); 
      })

      it("OpenTrove with 250 WSOL Token and 1800 ZUSD", async () => {
        const signerId = 13;
        const tokenId = 4;
        const token = ethers.utils.parseUnits('250')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })
      
      it("OpenTrove with 125 WSOL Token and 1800 ZUSD", async () => {
        const signerId = 14;
        const tokenId = 4;
        const token = ethers.utils.parseUnits('125')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');     
      })

      it("OpenTrove with 120 WSOL Token and 1800 ZUSD", async () => {
        const signerId = 15;
        const tokenId = 4;
        const token = ethers.utils.parseUnits('120')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })

      it("OpenTrove with 5000 USDC Token and 1800 ZUSD", async () => {
        const signerId = 16;
        const tokenId = 5;
        const token = ethers.utils.parseUnits('5000')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })
      
      it("OpenTrove with 2750 USDC Token and 1800 ZUSD", async () => {
        const signerId = 17;
        const tokenId = 5;
        const token = ethers.utils.parseUnits('2750')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })

      it("OpenTrove with 2500 USDC Token and 1800 ZUSD", async () => {
        const signerId = 18;
        const tokenId = 5;
        const token = ethers.utils.parseUnits('2500')
        const zusd = ethers.utils.parseUnits('1800')

        const { 0: upperHint, 1: lowerHint } = await hint(zusd,token);

        await approval(signerId, tokenId, token);

        await openTrovewithTokens(signerId, tokenId, token, zusd, upperHint, lowerHint);
        let previousBalance = await zusdTokenContract.balanceOf(signers[signerId].address);
        expect(previousBalance).to.equal(zusd);

        console.log('');
      })

      // it("Sequence Liquidate with same price ETH Troves", async () => {  
      //     const tokenId = 0;

      //     let previousBalance = await zusdTokenContract.balanceOf(signers[19].address);
      //     expect(previousBalance).to.equal(0);

      //     let error = await liquidateinSequence(tokenId, 2);

      //     expect(error).to.include("revert", "VM Exception while processing transaction: reverted with reason string 'TroveManager: nothing to liquidate'");

      //     console.log('');
      // })

      async function size() {
          try {
              let j;
              let troves = [];
              for(j = 0; j < 6; j++) { 
                  let result = await sortedTrovesContract.getSize(j);
                  troves[j] = result;
              }
              
              return troves;
          }
          catch(error) {
              console.log(error);        
          }
      }

      it("Size", async () => {  
          let troves = await size();

          expect(troves.length).to.equal(6);
      })

      // it("Revert when Sequence Liquidate all the ETH Troves", async () => {  
      //     const tokenId = 0;

      //     let previousBalance = await zusdTokenContract.balanceOf(signers[19].address);
      //     expect(previousBalance).to.equal(0);

      //     let error = await liquidateinSequence(tokenId, 3);

      //     expect(error).to.include("revert", "VM Exception while processing transaction: reverted with reason string 'TroveManager: n greater than the number of troves'");

      //     console.log('');
      // })

      it("Sequence Liquidate 2 ETH Troves", async () => {  
          const tokenId = 0;
          const zusd = ethers.utils.parseUnits('400')

          let previousBalance = await zusdTokenContract.balanceOf(signers[19].address);
          expect(previousBalance).to.equal(0);

          await liquidateinSequence(tokenId, 2);

          let afterBalance = await zusdTokenContract.balanceOf(signers[19].address);
          expect(afterBalance).to.equal(zusd);

          console.log('');
      })

      // it("Revert when Sequence Liquidate all the WETH Troves", async () => {  
      //     const tokenId = 1;

      //     let error = await liquidateinSequence(tokenId, 3);

      //     expect(error).to.include("revert", "VM Exception while processing transaction: reverted with reason string 'TroveManager: n greater than the number of troves'");

      //     console.log('');
      // })

      it("Sequence Liquidate 1 WETH Troves", async () => {  
          const tokenId = 1;
          const zusd = ethers.utils.parseUnits('600')

          await liquidateinSequence(tokenId, 1);

          let afterBalance = await zusdTokenContract.balanceOf(signers[19].address);
          expect(afterBalance).to.equal(zusd);

          console.log('');
      })

      // it("Revert when Sequence Liquidate all the WBTC Troves", async () => {  
      //     const tokenId = 2;

      //     let error = await liquidateinSequence(tokenId, 3);

      //     expect(error).to.include("revert", "VM Exception while processing transaction: reverted with reason string 'TroveManager: n greater than the number of troves'");

      //     console.log('');
      // })

      it("Sequence Liquidate 2 WBTC Troves", async () => {  
          const tokenId = 2;
          const zusd = ethers.utils.parseUnits('1000')

          await liquidateinSequence(tokenId, 2);

          let afterBalance = await zusdTokenContract.balanceOf(signers[19].address);
          expect(afterBalance).to.equal(zusd);

          console.log('');
      })

      it("Sequence Liquidate 1 WETH Troves", async () => {  
        const tokenId = 1;
        const zusd = ethers.utils.parseUnits('1200')

        await liquidateinSequence(tokenId, 1);

        let afterBalance = await zusdTokenContract.balanceOf(signers[19].address);
        expect(afterBalance).to.equal(zusd);

        console.log('');
    })


      // it("Revert when Sequence Liquidate all the WBNB Troves", async () => {  
      //     const tokenId = 3;

      //     let error = await liquidateinSequence(tokenId, 3);

      //     expect(error).to.include("revert", "VM Exception while processing transaction: reverted with reason string 'TroveManager: n greater than the number of troves'");

      //     console.log('');
      // })

      // it("Revert when Sequence Liquidate all the WSOL Troves", async () => {  
      //     const tokenId = 4;

      //     let error = await liquidateinSequence(tokenId, 3);

      //     expect(error).to.include("revert", "VM Exception while processing transaction: reverted with reason string 'TroveManager: n greater than the number of troves'");

      //     console.log('');
      // })
      it("Sequence Liquidate 1 USDC Troves", async () => {  
        const tokenId = 5;
        const zusd = ethers.utils.parseUnits('1400')

        await liquidateinSequence(tokenId, 1);

        let afterBalance = await zusdTokenContract.balanceOf(signers[19].address);
        expect(afterBalance).to.equal(zusd);

        console.log('');
    })

      it("Sequence Liquidate 2 WSOL Troves", async () => {  
          const tokenId = 4;
          const zusd = ethers.utils.parseUnits('1800')

          await liquidateinSequence(tokenId, 2);

          let afterBalance = await zusdTokenContract.balanceOf(signers[19].address);
          expect(afterBalance).to.equal(zusd);

          console.log('');
      })

      // it("Revert when Sequence Liquidate all the USDC Troves", async () => {  
      //     const tokenId = 5;

      //     let error = await liquidateinSequence(tokenId, 3);

      //     expect(error).to.include("revert", "VM Exception while processing transaction: reverted with reason string 'TroveManager: n greater than the number of troves'");

      //     console.log('');
      // })

      it("Sequence Liquidate 1 USDC Troves", async () => {  
          const tokenId = 5;
          const zusd = ethers.utils.parseUnits('2000')

          await liquidateinSequence(tokenId, 1);

          let afterBalance = await zusdTokenContract.balanceOf(signers[19].address);
          expect(afterBalance).to.equal(zusd);

          console.log('');
      })

      it("Sequence Liquidate 2 WBNB Troves", async () => {  
        const tokenId = 3;
        const zusd = ethers.utils.parseUnits('2400')

        await liquidateinSequence(tokenId, 2);

        let afterBalance = await zusdTokenContract.balanceOf(signers[19].address);
        expect(afterBalance).to.equal(zusd);

        console.log('');
    })
    })

  })
