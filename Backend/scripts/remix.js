
(async function() {
  try {
    const activePool = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/ActivePoolTester.json'))
    const borrowerOperations = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/BorrowerOperations.json'))
    const communityIssuance = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/CommunityIssuanceTester.json'))
    const defaultPool = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/DefaultPoolTester.json'))
    const collSurplus = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/CollSurplusPool.json'))
    const gasPool = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/GasPool.json'))
    const zqtyStaking = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/ZQTYStakingTester.json'))
    const zqtyToken = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/ZQTYTokenTester.json'))
    const zusdToken = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/ZUSDTokenTester.json'))
    const lockupFactory = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/LockupContractFactory.json'))
    const multiSig = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/MultiSig.json'))
    const priceFeed = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/PriceFeedTestnet.json'))
    const proxy = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/Proxy.json'))
    const sortedTroves = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/SortedTroves.json'))
    const stabilityPool = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/StabilityPoolTester.json'))
    const troveManager = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/TroveManager.json'))
    const lpTokenWrapper = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/LPTokenWrapper.json'))
    const hintHelpers = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/HintHelpers.json'))
    const ercToken1 = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/MyToken.json'));
    const ercToken2 = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/MyToken.json'));
    const ercToken3 = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/MyToken.json'));
    const ercToken4 = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/MyToken.json'));
    const ercToken5 = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/MyToken.json'));
    
    const signer = (new ethers.providers.Web3Provider(web3Provider)).getSigner()
    let signerAddress = await signer.getAddress();
		//signerAddress = [`${signerAddress}`];

    let activePoolC = new ethers.ContractFactory(activePool.abi, activePool.data.bytecode.object, signer);
    let borrowerOperationsC = new ethers.ContractFactory(borrowerOperations.abi, borrowerOperations.data.bytecode.object, signer);
    let communityIssuanceC = new ethers.ContractFactory(communityIssuance.abi, communityIssuance.data.bytecode.object, signer);
    let defaultPoolC = new ethers.ContractFactory(defaultPool.abi, defaultPool.data.bytecode.object, signer);
    let collSurplusC = new ethers.ContractFactory(collSurplus.abi, collSurplus.data.bytecode.object, signer);
    let gasPoolC = new ethers.ContractFactory(gasPool.abi, gasPool.data.bytecode.object, signer);
    let zqtyStakingC = new ethers.ContractFactory(zqtyStaking.abi, zqtyStaking.data.bytecode.object, signer);
    let zqtyTokenC = new ethers.ContractFactory(zqtyToken.abi, zqtyToken.data.bytecode.object, signer);
    let zusdTokenC = new ethers.ContractFactory(zusdToken.abi, zusdToken.data.bytecode.object, signer);
    let lockupFactoryC = new ethers.ContractFactory(lockupFactory.abi, lockupFactory.data.bytecode.object, signer);
    let multiSigC = new ethers.ContractFactory(multiSig.abi, multiSig.data.bytecode.object, signer);
    let priceFeedC = new ethers.ContractFactory(priceFeed.abi, priceFeed.data.bytecode.object, signer);
    let proxyC = new ethers.ContractFactory(proxy.abi, proxy.data.bytecode.object, signer);
    let sortedTrovesC = new ethers.ContractFactory(sortedTroves.abi, sortedTroves.data.bytecode.object, signer);
    let stabilityPoolC = new ethers.ContractFactory(stabilityPool.abi, stabilityPool.data.bytecode.object, signer);
    let troveManagerC = new ethers.ContractFactory(troveManager.abi, troveManager.data.bytecode.object, signer);
    let lpTokenWrapperC = new ethers.ContractFactory(lpTokenWrapper.abi, lpTokenWrapper.data.bytecode.object, signer);
    let hintHelpersC = new ethers.ContractFactory(hintHelpers.abi, hintHelpers.data.bytecode.object, signer);
    let ercToken1C = new ethers.ContractFactory(ercToken1.abi, ercToken1.data.bytecode.object, signer);
    let ercToken2C = new ethers.ContractFactory(ercToken2.abi, ercToken2.data.bytecode.object, signer);
    let ercToken3C = new ethers.ContractFactory(ercToken3.abi, ercToken3.data.bytecode.object, signer);
    let ercToken4C = new ethers.ContractFactory(ercToken4.abi, ercToken4.data.bytecode.object, signer);
    let ercToken5C = new ethers.ContractFactory(ercToken5.abi, ercToken5.data.bytecode.object, signer);


    let activePoolCntrct = await activePoolC.deploy();
    let borrowerOperationsCntrct = await borrowerOperationsC.deploy();
    let communityIssuanceCntrct = await communityIssuanceC.deploy();
    let defaultPoolCntrct = await defaultPoolC.deploy();
    let collSurplusCntrct = await collSurplusC.deploy();
    let gasPoolCntrct = await gasPoolC.deploy();
    let zqtyStakingCntrct = await zqtyStakingC.deploy();
    let lockupFactoryCntrct = await lockupFactoryC.deploy();
    let multiSigCntrct = await multiSigC.deploy("zqty","zqty",["0xB5874deeec872e6BEB3df88BDc628b8fAc774C08","0xca4d795FD2213a138d675A5d56caC66dC4bf537a"]);
    let priceFeedCntrct = await priceFeedC.deploy();
    let proxyCntrct = await proxyC.deploy("0xB5874deeec872e6BEB3df88BDc628b8fAc774C08");
    let sortedTrovesCntrct = await sortedTrovesC.deploy();
    let stabilityPoolCntrct = await stabilityPoolC.deploy();
    let troveManagerCntrct = await troveManagerC.deploy();
    let lpTokenWrapperCntrct = await lpTokenWrapperC.deploy();
    let hintHelpersCntrct = await hintHelpersC.deploy();
    let ercToken1Cntrct = await ercToken1C.deploy();
    let ercToken2Cntrct = await ercToken2C.deploy();
    let ercToken3Cntrct = await ercToken3C.deploy();
    let ercToken4Cntrct = await ercToken4C.deploy();
    let ercToken5Cntrct = await ercToken5C.deploy();
    let zqtyTokenCntrct = await zqtyTokenC.deploy(communityIssuanceCntrct.address,zqtyStakingCntrct.address,lockupFactoryCntrct.address,proxyCntrct.address,lpTokenWrapperCntrct.address,multiSigCntrct.address);
    let zusdTokenCntrct = await zusdTokenC.deploy(troveManagerCntrct.address,stabilityPoolCntrct.address, borrowerOperationsCntrct.address);
  
  
    let activePoolAddress = activePoolCntrct.address;
    let borrowerOperationsAddress = borrowerOperationsCntrct.address;
    let communityIssuanceAddress = communityIssuanceCntrct.address;
    let defaultPoolAddress = defaultPoolCntrct.address;
    let collSurplusAddress = collSurplusCntrct.address;
    let gasPoolAddress = gasPoolCntrct.address;
    let zqtyStakingAddress = zqtyStakingCntrct.address;
    let zqtyTokenAddress = zqtyTokenCntrct.address;
    let zusdTokenAddress = zusdTokenCntrct.address;
    let lockupFactoryAddress = lockupFactoryCntrct.address;
    let multiSigAddress = multiSigCntrct.address;
    let priceFeedAddress = priceFeedCntrct.address;
    let proxyAddress = proxyCntrct.address;
    let sortedTrovesAddress = sortedTrovesCntrct.address;
    let stabilityPoolAddress = stabilityPoolCntrct.address;
    let troveManagerAddress = troveManagerCntrct.address;
    let lpTokenWrapperAddress = lpTokenWrapperCntrct.address;
    let hintHelpersAddress = hintHelpersCntrct.address;
    let ercToken1Address = ercToken1Cntrct.address;
    let ercToken2Address = ercToken2Cntrct.address;
    let ercToken3Address = ercToken3Cntrct.address;
    let ercToken4Address = ercToken4Cntrct.address;
    let ercToken5Address = ercToken5Cntrct.address;

    console.log(activePoolAddress);
    console.log(borrowerOperationsAddress);
    console.log(communityIssuanceAddress);
    console.log(defaultPoolAddress);
    console.log(collSurplusAddress);
    console.log(gasPoolAddress);
    console.log(zqtyStakingAddress);
    console.log(zqtyTokenAddress);
    console.log(zusdTokenAddress);
    console.log(lockupFactoryAddress);
    console.log(multiSigAddress);
    console.log(priceFeedAddress);
    console.log(proxyAddress);
    console.log(sortedTrovesAddress);
    console.log(stabilityPoolAddress);
    console.log(troveManagerAddress);
    console.log(lpTokenWrapperAddress);
    console.log(hintHelpersAddress);
    console.log(ercToken1Address);
    console.log(ercToken2Address);
    console.log(ercToken3Address);
    console.log(ercToken4Address);
    console.log(ercToken5Address);

    // console.log(activePoolCntrct.deployTransaction.hash);
    // console.log(borrowerOperationsCntrct.deployTransaction.hash);
    // console.log(communityIssuanceCntrct.deployTransaction.hash);
    // console.log(defaultPoolCntrct.deployTransaction.hash);
    // console.log(collSurplusCntrct.deployTransaction.hash);
    // console.log(gasPoolCntrct.deployTransaction.hash);
    // console.log(zqtyStakingCntrct.deployTransaction.hash);
    // console.log(zqtyTokenCntrct.deployTransaction.hash);
    // console.log(zusdTokenCntrct.deployTransaction.hash);
    // console.log(lockupFactoryCntrct.deployTransaction.hash);
    // console.log(multiSigCntrct.deployTransaction.hash);
    // console.log(priceFeedCntrct.deployTransaction.hash);
    // console.log(proxyCntrct.deployTransaction.hash);
    // console.log(sortedTrovesCntrct.deployTransaction.hash);
    // console.log(stabilityPoolCntrct.deployTransaction.hash);
    // console.log(troveManagerCntrct.deployTransaction.hash);
    // console.log(lpTokenWrapperCntrct.deployTransaction.hash);
    // console.log(hintHelpersCntrct.deployTransaction.hash);
    // console.log(ercToken1Cntrct.deployTransaction.hash);
    // console.log(ercToken2Cntrct.deployTransaction.hash);
    // console.log(ercToken3Cntrct.deployTransaction.hash);
    // console.log(ercToken4Cntrct.deployTransaction.hash);
    // console.log(ercToken5Cntrct.deployTransaction.hash);


    await activePoolCntrct.deployed();
    await borrowerOperationsCntrct.deployed();
    await communityIssuanceCntrct.deployed();
    await defaultPoolCntrct.deployed();
    await collSurplusCntrct.deployed();
    await gasPoolCntrct.deployed();
    await zqtyStakingCntrct.deployed();
    await zqtyTokenCntrct.deployed();
    await zusdTokenCntrct.deployed();
    await lockupFactoryCntrct.deployed();
    await multiSigCntrct.deployed();
    await priceFeedCntrct.deployed();
    await proxyCntrct.deployed();
    await sortedTrovesCntrct.deployed();
    await stabilityPoolCntrct.deployed();
    await troveManagerCntrct.deployed();
    await lpTokenWrapperCntrct.deployed();
    await hintHelpersCntrct.deployed();
    await ercToken1Cntrct.deployed();
    await ercToken2Cntrct.deployed();
    await ercToken3Cntrct.deployed();
    await ercToken4Cntrct.deployed();
    await ercToken5Cntrct.deployed();


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
    let troveManagerContract = new ethers.Contract(troveManagerAddress, troveManager.abi, signer);
    let lpTokenWrapperContract = new ethers.Contract(lpTokenWrapperAddress, lpTokenWrapper.abi, signer);
    let hintHelpersContract = new ethers.Contract(hintHelpersAddress, hintHelpers.abi, signer);
    let ercToken1Contract = new ethers.Contract(ercToken1Address, ercToken1.abi, signer);
    let ercToken2Contract = new ethers.Contract(ercToken2Address, ercToken2.abi, signer);
    let ercToken3Contract = new ethers.Contract(ercToken3Address, ercToken3.abi, signer);
    let ercToken4Contract = new ethers.Contract(ercToken4Address, ercToken4.abi, signer);
    let ercToken5Contract = new ethers.Contract(ercToken5Address, ercToken5.abi, signer);


    const activePoolTransaction = await activePoolContract.setAddresses(
      borrowerOperationsAddress,
      troveManagerAddress,
      stabilityPoolAddress,
      defaultPoolAddress);

    const borrowerOperationsTransaction = await borrowerOperationsContract.setAddresses(
      troveManagerAddress,
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
      borrowerOperationsAddress,troveManagerAddress,activePoolAddress);

    const collSurplusTransaction = await collSurplusContract.setAddresses(
      borrowerOperationsAddress,troveManagerAddress,activePoolAddress);

    const zqtyStakingTransaction = await zqtyStakingContract.setAddresses(
      zqtyTokenAddress,
      zusdTokenAddress,
      troveManagerAddress, 
      borrowerOperationsAddress,
      activePoolAddress);
    
    const lockupFactoryTransaction = await lockupFactoryContract.setZQTYTokenAddress(zqtyTokenAddress);

    const sortedTrovesTransaction = await sortedTrovesContract.setParams(100,troveManagerAddress,borrowerOperationsAddress);

    const stabilityPoolTransaction = await stabilityPoolContract.setAddresses(
      borrowerOperationsAddress,
      troveManagerAddress,
      activePoolAddress,
      zusdTokenAddress,
      sortedTrovesAddress,
      priceFeedAddress,
      communityIssuanceAddress);

    const troveManagerTransaction = await troveManagerContract.setAddresses(
      borrowerOperationsAddress,
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

    const hintHelpersTransaction = await hintHelpersContract.setAddresses(sortedTrovesAddress,troveManagerAddress);

    const collateralTokenTransactions = await borrowerOperationsContract.addCollTokenAddress([ercToken1Address,ercToken2Address,ercToken3Address,ercToken4Address,ercToken5Address]);

    const approval = await ercToken2Contract.approve(borrowerOperationsAddress,ercToken2Contract.totalSupply());
    
    
    await activePoolTransaction.wait();
    await borrowerOperationsTransaction.wait();
    await communityIssuanceTransaction.wait();
    await defaultPoolTransaction.wait();
    await collSurplusTransaction.wait();
    await zqtyStakingTransaction.wait();
    await lockupFactoryTransaction.wait();
    await sortedTrovesTransaction.wait();
    await stabilityPoolTransaction.wait();
    await troveManagerTransaction.wait();
    await hintHelpersTransaction.wait();
    await collateralTokenTransactions.wait();
    await approval.wait();

    

    let zusd = BigInt(1800000000000000000000);
    //1158,000000000000000000,000000000000000000,000000000000000000
    let value = BigInt(5000000000000000000);

    let p = BigInt(2000000000000000000000);

    await priceFeedContract.setPrice([p,p,p,p,p,p]);

    //let trove = await borrowerOperationsContract.openTrovewithEth(5000000000000000,zusd,signerAddress,signerAddress, {value: ethers.utils.parseEther("5")});
    let trove = await borrowerOperationsContract.openTrovewithTokens(5000000000000000,1,value,zusd,signerAddress,signerAddress);
    
    await trove.wait();

    // [2000000000000000000000,2000000000000000000000,2000000000000000000000,2000000000000000000000,2000000000000000000000]

    function toPlainString(num) {
        return (''+ +num).replace(/(-?)(\d*)\.?(\d*)e([+-]\d+)/,
          function(a,b,c,d,e) {
            return e < 0
              ? b + '0.' + Array(1-e-c.length).join('0') + c + d
              : b + c + d + Array(e-d.length+1).join('0');
        });
    }

    let price = []; 

        let data = await priceFeedContract.fetchPrice(1);

        for(let i = 0; i < data.length; i++){
            price.push(toPlainString(data[i]));
        }

    let balance = await ercToken1Contract.balanceOf(signerAddress);
    balance = toPlainString(balance._hex);

    let all = await ercToken2Contract.allowance(signerAddress,borrowerOperationsAddress); 
    all = toPlainString(all._hex);

    // Done! The contract is deployed.
    console.log(price);
    console.log(all);
    console.log(signerAddress);

  } catch (e) {
    console.log(e.message)
  }
})();