import './web3-lib';

(async function() {
  try {
    let i = 0;

    for(i = 0; i < 6; i++) {
      let n = i;

      const provider = new ethers.providers.Web3Provider(web3.currentProvider);
      
      let signer;
      const accounts = await provider.listAccounts();
      const newSigner = provider.getSigner(accounts[n]);

      signer = newSigner;
      let signerAddress = await signer.getAddress();

let activePoolAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3"
let borrowerOperationsAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
let communityIssuanceAddress = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"
let defaultPoolAddress = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9"
let collSurplusAddress = "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9"
let gasPoolAddress = "0x5FC8d32690cc91D4c39d9d3abcBD16989F875707"
let zqtyStakingAddress = "0x0165878A594ca255338adfa4d48449f69242Eb8F"
let zqtyTokenAddress = "0x322813Fd9A801c5507c9de605d63CEA4f2CE6c44"
let zusdTokenAddress = "0xa85233C63b9Ee964Add6F2cffe00Fd84eb32338f"
let lockupFactoryAddress = "0xa513E6E4b8f2a923D98304ec87F64353C4D5C853"
let multiSigAddress = "0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6"
let priceFeedAddress = "0x8A791620dd6260079BF849Dc5567aDC3F2FdC318"
let proxyAddress = "0x610178dA211FEF7D417bC0e6FeD39F05609AD788"
let sortedTrovesAddress = "0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e"
let stabilityPoolAddress = "0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0"
let troveManager1Address = "0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82"
let troveManager2Address = "0x9A676e781A523b5d0C0e43731313A708CB607508"
let troveManager3Address = "0x0B306BF915C4d645ff596e518fAf3F9669b97016"
let lpTokenWrapperAddress = "0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1"
let hintHelpersAddress = "0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE"
let ercToken1Address = "0x68B1D87F95878fE05B998F19b66F4baba5De1aed"
let ercToken2Address = "0x3Aa5ebB10DC797CAC828524e59A333d0A371443c"
let ercToken3Address = "0xc6e7DF5E7b4f2A278906862b61205850344D4e7d"
let ercToken4Address = "0x59b670e9fA9D0A427751Af201D676719a970857b"
let ercToken5Address = "0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1"

      const activePool = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/ActivePool.json'))
      const borrowerOperations = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/BorrowerOperations.json'))
      const communityIssuance = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/CommunityIssuance.json'))
      const defaultPool = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/DefaultPool.json'))
      const collSurplus = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/CollSurplusPool.json'))
      const gasPool = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/GasPool.json'))
      const zqtyStaking = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/ZQTYStaking.json'))
      const zqtyToken = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/ZQTYToken.json'))
      const zusdToken = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/ZUSDToken.json'))
      const lockupFactory = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/LockupContractFactory.json'))
      const multiSig = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/MultiSig.json'))
      const priceFeed = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/PriceFeedTestnet.json'))
      const proxy = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/Proxy.json'))
      const sortedTroves = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/SortedTroves.json'))
      const stabilityPool = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/StabilityPool.json'))
      const troveManager1 = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/TroveManager1.json'))
      const troveManager2 = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/TroveManager2.json'))
      const troveManager3 = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/TroveManager3.json'))
      const lpTokenWrapper = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/LPTokenWrapper.json'))
      const hintHelpers = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/HintHelpers.json'))
      const ercToken1 = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/MyToken.json'));
      const ercToken2 = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/MyToken.json'));
      const ercToken3 = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/MyToken.json'));
      const ercToken4 = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/MyToken.json'));
      const ercToken5 = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/MyToken.json'));

      let activePoolContract = new ethers.Contract(activePoolAddress, activePool.abi, signer);
      let borrowerOperationsContract = new ethers.Contract(borrowerOperationsAddress, borrowerOperations.abi, signer);
      let communityIssuanceContract = new ethers.Contract(communityIssuanceAddress, communityIssuance.abi, signer);
      let defaultPoolContract = new ethers.Contract(defaultPoolAddress, defaultPool.abi, signer);
      let collSurplusContract = new ethers.Contract(collSurplusAddress, collSurplus.abi, signer);
      let gasPoolContract = new ethers.Contract(gasPoolAddress, gasPool.abi, signer);
      let zqtyStakingContract = new ethers.Contract(zqtyStakingAddress, zqtyStaking.abi, signer);
      let zqtyTokenContract = new ethers.Contract(zqtyTokenAddress, zqtyToken.abi, signer);
      let zusdTokenContract = new ethers.Contract(zusdTokenAddress, zusdToken.abi, signer);
      let lockupFactoryContract = new ethers.Contract(lockupFactoryAddress, lockupFactory.abi, signer);
      let multiSigContract = new ethers.Contract(multiSigAddress, multiSig.abi, signer);
      let priceFeedContract = new ethers.Contract(priceFeedAddress, priceFeed.abi, signer);
      let proxyContract = new ethers.Contract(proxyAddress, proxy.abi, signer);
      let sortedTrovesContract = new ethers.Contract(sortedTrovesAddress, sortedTroves.abi, signer);
      let stabilityPoolContract = new ethers.Contract(stabilityPoolAddress, stabilityPool.abi, signer);
      let troveManager1Contract = new ethers.Contract(troveManager1Address, troveManager1.abi, signer);
      let troveManager2Contract = new ethers.Contract(troveManager2Address, troveManager2.abi, signer);
      let troveManager3Contract = new ethers.Contract(troveManager3Address, troveManager3.abi, signer);
      let lpTokenWrapperContract = new ethers.Contract(lpTokenWrapperAddress, lpTokenWrapper.abi, signer);
      let hintHelpersContract = new ethers.Contract(hintHelpersAddress, hintHelpers.abi, signer);
      let ercToken1Contract = new ethers.Contract(ercToken1Address, ercToken1.abi, signer);
      let ercToken2Contract = new ethers.Contract(ercToken2Address, ercToken2.abi, signer);
      let ercToken3Contract = new ethers.Contract(ercToken3Address, ercToken3.abi, signer);
      let ercToken4Contract = new ethers.Contract(ercToken4Address, ercToken4.abi, signer);
      let ercToken5Contract = new ethers.Contract(ercToken5Address, ercToken5.abi, signer);

      const approval = await ercToken1Contract.approve(borrowerOperationsAddress,ercToken1Contract.totalSupply());

      await approval.wait;

      const toWei = web3.utils.toWei
      const toBN = web3.utils.toBN

      let fee = '5000000000000000';
      let val = '5000000000000000000';
      let zusd = toWei('1800');
      let add = "0x0000000000000000000000000000000000000000";
      let trove;
      let redeem;

      let eth = "5";

      if(n == 0) {val = "5000000000000000000"}
      if(n == 1) {val = "1250000000000000000"}
      if(n == 2) {val = "1150000000000000000"}

      // if(n == 0) {eth = "5"}
      // if(n == 1) {eth = "1.25";}
      // if(n == 2) {eth = "1.25";}

      if(n == 3) {eth = "5"}
      if(n == 4) {eth = "1.25";}
      if(n == 5) {eth = "1.15";}

      if(n!=7){
        const LUSDAmount = toBN(toWei('1800')) // borrower wants to withdraw 2500 LUSD
        const ETHColl = toBN(toWei('5')) // borrower wants to lock 5 ETH collateral

        const liquidationReserve = await troveManager1Contract.ZUSD_GAS_COMPENSATION()
        const expectedFee = await troveManager2Contract.getBorrowingFeeWithDecay(zusd)
        const expectedDebt =  parseInt(zusd) + parseInt(expectedFee) + parseInt(liquidationReserve)

        const _1e20 = toBN(toWei('100'))
        let NICR = val * _1e20 / expectedDebt
        NICR = BigInt(NICR)

        // Get an approximate address hint from the deployed HintHelper contract. Use (15 * number of troves) trials 
        // to get an approx. hint that is close to the right position.
        let numTroves = await sortedTrovesContract.getSize(0)
        let numTrials = numTroves.mul(15)

        let { 0: approxHint } = await hintHelpersContract.getApproxHint(0,NICR, numTrials, 42)  // random seed of 42

        let hint = `"${approxHint}"`;
        console.log(hint);

        console.log(String(NICR));

        // Use the approximate hint to get the exact upper and lower hints from the deployed SortedTroves contract
        let { 0: upperHint, 1: lowerHint } = await sortedTrovesContract.findInsertPosition('0',NICR, approxHint, approxHint)

        // Finally, call openTrove with the exact upperHint and lowerHint
        const maxFee = '5'.concat('0'.repeat(16)) // Slippage protection: 5%

        n < 3 ? trove = await borrowerOperationsContract.openTrovewithTokens(fee,1,val,zusd,upperHint,lowerHint) : 
        trove = await borrowerOperationsContract.openTrovewithEth(fee, zusd, upperHint, lowerHint, {value: ethers.utils.parseEther(eth)})
      
        await trove.wait();
      }

      else {
        // Get the redemptions hints from the deployed HintHelpers contract
        const redemptionhint = await hintHelpersContract.getRedemptionHints(0, "1810000000000000000000", "2000000000000000000000", 50)

        const { 0: firstRedemptionHint, 1: partialRedemptionNewICR, 2: truncatedLUSDAmount } = redemptionhint

        let numTroves = await sortedTrovesContract.getSize(0);
        let numTrials = numTroves.mul(15);

        // Get the approximate partial redemption hint
        const { hintAddress: approxPartialRedemptionHint } = await hintHelpersContract.getApproxHint(0,partialRedemptionNewICR, numTrials, 42)
        
        /* Use the approximate partial redemption hint to get the exact partial redemption hint from the 
        * deployed SortedTroves contract
        */
        const exactPartialRedemptionHint = (await sortedTrovesContract.findInsertPosition(0,partialRedemptionNewICR,
          approxPartialRedemptionHint,
          approxPartialRedemptionHint))

        const maxFee = '5'.concat('0'.repeat(16)) // Slippage protection: 5%

        console.log(
          zusd,
          0,
          toPlainString(truncatedLUSDAmount),
          firstRedemptionHint,
          exactPartialRedemptionHint[0],
          exactPartialRedemptionHint[1],
          toPlainString(partialRedemptionNewICR),
          0,
          
        )

        /* Finally, perform the on-chain redemption, passing the truncated LUSD amount, the correct hints, and the expected
        * ICR of the final partially redeemed trove in the sequence. 
        */
        redeem = await troveManager2Contract.redeemCollateral(
          0,
          truncatedLUSDAmount,
          firstRedemptionHint,
          exactPartialRedemptionHint[0],
          exactPartialRedemptionHint[1],
          partialRedemptionNewICR,
          0,
          "150000000000000000"
        ),
        {gaslimit: "1000000000000000000"}
      }

      //let coll = await borrowerOperationsContract.addColl(0,signerAddress,signerAddress, {value: ethers.utils.parseEther("5")});
      // let coll = await borrowerOperationsContract.addColl(1,signerAddress,signerAddress);
      
      // await coll.wait(); 1:2000 - 1800; 

      if(n == 5) {
        const p = await priceFeedContract.setPrice(['1500000000000000000000','1500000000000000000000','21000000000000000000000','3000000000000000000000','200000000000000000000','10000000000000000000']);
        await p.wait();
      }

      if(n > 0 && n != 7){
        const trans = await zusdTokenContract.transfer(accounts[6],zusd);
        await trans.wait();
      }

      // [2000000000000000000000,2000000000000000000000,21000000000000000000000,300000000000000000000,20000000000000000000,1000000000000000000]

      // let eth = BigInt(2000000000000000000000);
      // let btc = BigInt(21000000000000000000000);
      // let bnb = BigInt(3000000000000000000000);
      // let sol = BigInt(200000000000000000000);
      // let usd = BigInt(10000000000000000000);

      // await priceFeedContract.setPrice(['1500000000000000000000',eth,'21000000000000000000000',bnb,sol,usd]);

      

      let balance = await zusdTokenContract.balanceOf(accounts[6]);
      balance = toPlainString(balance._hex);

      // ["0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db","0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"]

      // Done! The contract is deployed.
      n <= 6 ? console.log(trove.hash) : console.log(redeem.hash);
      console.log(balance);
      
      n == 5 ? console.log([`"${accounts[1]}"`,`"${accounts[2]}"`,`"${accounts[4]}"`,`"${accounts[5]}"`]) : n;
    }

    function toPlainString(num) {
        return (''+ +num).replace(/(-?)(\d*)\.?(\d*)e([+-]\d+)/,
          function(a,b,c,d,e) {
            return e < 0
              ? b + '0.' + Array(1-e-c.length).join('0') + c + d
              : b + c + d + Array(e-d.length+1).join('0');
        });
    }

    let index = 0;
    for(index = 0; index < 6; index++) {
      const provider = new ethers.providers.Web3Provider(web3.currentProvider);
      
      const accounts = await provider.listAccounts();
      const newSigner = provider.getSigner(accounts[index]);

      let troveAddress = "0xaE036c65C649172b43ef7156b009c6221B596B8b"
      const trove = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/Backend/TestScript/artifacts/TroveManager1.json'))
      let troveManager = new ethers.Contract(troveAddress, trove.abi, newSigner);

      let debt = await troveManager.getTroveDebt(accounts[index]);

      console.log(toPlainString(debt._hex));
    }

  } catch (e) {
    console.log(e.message)
  }
})();

// ["0x4cea8721f0Cf83c74263487b8Ca86D4Deba3196f","0x3A25B7ac7EB7C3E453a114D8fFaE0eA8Bb09c57b","0xE19Bd6e2b81A73cb9DdA99372f82B75A74fd564c","0xbFA845D1F17BD546e210AF66855C10CDcbFcD1F9","0x0EC2176DE6CE162E4e53260125778F20D2b6d6Ab"]