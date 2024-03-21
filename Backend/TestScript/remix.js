import './web3-lib';

(async function() {
  try {
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
    let troveManager1C = new ethers.ContractFactory(troveManager1.abi, troveManager1.data.bytecode.object, signer);
    let troveManager2C = new ethers.ContractFactory(troveManager2.abi, troveManager2.data.bytecode.object, signer);
    let troveManager3C = new ethers.ContractFactory(troveManager3.abi, troveManager3.data.bytecode.object, signer);
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
    let troveManager1Cntrct = await troveManager1C.deploy();
    let troveManager2Cntrct = await troveManager2C.deploy();
    let troveManager3Cntrct = await troveManager3C.deploy();
    let lpTokenWrapperCntrct = await lpTokenWrapperC.deploy();
    let hintHelpersCntrct = await hintHelpersC.deploy();
    let ercToken1Cntrct = await ercToken1C.deploy();
    let ercToken2Cntrct = await ercToken2C.deploy();
    let ercToken3Cntrct = await ercToken3C.deploy();
    let ercToken4Cntrct = await ercToken4C.deploy();
    let ercToken5Cntrct = await ercToken5C.deploy();
    let zqtyTokenCntrct = await zqtyTokenC.deploy(communityIssuanceCntrct.address,zqtyStakingCntrct.address,lockupFactoryCntrct.address,proxyCntrct.address,lpTokenWrapperCntrct.address,multiSigCntrct.address);
    let zusdTokenCntrct = await zusdTokenC.deploy(troveManager1Cntrct.address,troveManager2Cntrct.address,troveManager3Cntrct.address,stabilityPoolCntrct.address, borrowerOperationsCntrct.address);
  
  
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
    let troveManager1Address = troveManager1Cntrct.address;
    let troveManager2Address = troveManager2Cntrct.address;
    let troveManager3Address = troveManager3Cntrct.address;
    let lpTokenWrapperAddress = lpTokenWrapperCntrct.address;
    let hintHelpersAddress = hintHelpersCntrct.address;
    let ercToken1Address = ercToken1Cntrct.address;
    let ercToken2Address = ercToken2Cntrct.address;
    let ercToken3Address = ercToken3Cntrct.address;
    let ercToken4Address = ercToken4Cntrct.address;
    let ercToken5Address = ercToken5Cntrct.address;

    console.log(`let activePoolAddress = "${activePoolAddress}"`);
    console.log(`let borrowerOperationsAddress = "${borrowerOperationsAddress}"`);
    console.log(`let communityIssuanceAddress = "${communityIssuanceAddress}"`);
    console.log(`let defaultPoolAddress = "${defaultPoolAddress}"`);
    console.log(`let collSurplusAddress = "${collSurplusAddress}"`);
    console.log(`let gasPoolAddress = "${gasPoolAddress}"`);
    console.log(`let zqtyStakingAddress = "${zqtyStakingAddress}"`);
    console.log(`let zqtyTokenAddress = "${zqtyTokenAddress}"`);
    console.log(`let zusdTokenAddress = "${zusdTokenAddress}"`);
    console.log(`let lockupFactoryAddress = "${lockupFactoryAddress}"`);
    console.log(`let multiSigAddress = "${multiSigAddress}"`);
    console.log(`let priceFeedAddress = "${priceFeedAddress}"`);
    console.log(`let proxyAddress = "${proxyAddress}"`);
    console.log(`let sortedTrovesAddress = "${sortedTrovesAddress}"`);
    console.log(`let stabilityPoolAddress = "${stabilityPoolAddress}"`);
    console.log(`let troveManager1Address = "${troveManager1Address}"`);
    console.log(`let troveManager2Address = "${troveManager2Address}"`);
    console.log(`let troveManager3Address = "${troveManager3Address}"`);
    console.log(`let lpTokenWrapperAddress = "${lpTokenWrapperAddress}"`);
    console.log(`let hintHelpersAddress = "${hintHelpersAddress}"`);
    console.log(`let ercToken1Address = "${ercToken1Address}"`);
    console.log(`let ercToken2Address = "${ercToken2Address}"`);
    console.log(`let ercToken3Address = "${ercToken3Address}"`);
    console.log(`let ercToken4Address = "${ercToken4Address}"`);
    console.log(`let ercToken5Address = "${ercToken5Address}"`);

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
    // console.log(troveManager1Cntrct.deployTransaction.hash);
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
    await troveManager1Cntrct.deployed();
    await troveManager2Cntrct.deployed();
    await troveManager3Cntrct.deployed();
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

    const approval = await ercToken1Contract.approve(borrowerOperationsAddress,ercToken1Contract.totalSupply());
    
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
    await approval.wait();

    let i;
    for(i = 1; i < 19; i++) {
      const provider = new ethers.providers.Web3Provider(web3.currentProvider);
      
      let signer;
      const accounts = await provider.listAccounts();
      const newSigner = provider.getSigner(accounts[i]);

      signer = newSigner;
      let signerAddress = await signer.getAddress();

      const transfer1 = await ercToken1Contract.transfer(signerAddress,BigInt(50000000000000000000000));
      const transfer2 = await ercToken2Contract.transfer(signerAddress,BigInt(50000000000000000000000));
      const transfer3 = await ercToken3Contract.transfer(signerAddress,BigInt(50000000000000000000000));
      const transfer4 = await ercToken4Contract.transfer(signerAddress,BigInt(50000000000000000000000));
      const transfer5 = await ercToken5Contract.transfer(signerAddress,BigInt(50000000000000000000000));

      await transfer1.wait();
      await transfer2.wait();
      await transfer3.wait();
      await transfer4.wait();
      await transfer5.wait();
    }
    
    // let fee = BigInt(5000000000000000);
    // let value = BigInt(5000000000000000000);
    // let zusd = BigInt(1800000000000000000000);
    // let add = "0x0000000000000000000000000000000000000000";

    // [2000000000000000000000,2000000000000000000000,21000000000000000000000,300000000000000000000,20000000000000000000,1000000000000000000]

    let eth = BigInt(2000000000000000000000);
    let btc = BigInt(30000000000000000000000);
    let bnb = BigInt(300000000000000000000);
    let sol = BigInt(20000000000000000000);
    let usd = BigInt(1000000000000000000);

    const priceTransaction = await priceFeedContract.setPrice([eth,eth,btc,bnb,sol,usd]);
		await priceTransaction.wait();

    // ["0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419","0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419","0x86392dC19c0b719886221c78AB11eb8Cf5c52812","0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c","0xfdFD9C85aD200c506Cf9e21F1FD8dd01932FBB23","0x547a514d5e3769680Ce22B2361c10Ea13619e8a9","0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9"]

    // const price1 = await priceFeedContract.setAddresses(["0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419"], { gasLimit: 30000000 });
    // const price2 = await priceFeedContract.setAddresses(["0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419"], { gasLimit: 30000000 });
    // const price3 = await priceFeedContract.setAddresses(["0x86392dC19c0b719886221c78AB11eb8Cf5c52812"], { gasLimit: 30000000 });
    // const price4 = await priceFeedContract.setAddresses(["0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c"], { gasLimit: 30000000 });
    // const price5 = await priceFeedContract.setAddresses(["0xfdFD9C85aD200c506Cf9e21F1FD8dd01932FBB23"], { gasLimit: 30000000 });
    // const price6 = await priceFeedContract.setAddresses(["0x547a514d5e3769680Ce22B2361c10Ea13619e8a9"], { gasLimit: 30000000 });
    // const price7 = await priceFeedContract.setAddresses(["0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9"], { gasLimit: 30000000 });

    // await price1.wait();
    // await price2.wait();
    // await price3.wait();
    // await price4.wait();
    // await price5.wait();
    // await price6.wait();
    // await price7.wait();

    //let trove = await borrowerOperationsContract.openTrovewithEth(5000000000000000,zusd,signerAddress,signerAddress, {value: ethers.utils.parseEther("5")});
    // let trove = await borrowerOperationsContract.openTrovewithTokens(5000000000000000,1,value,zusd,signerAddress,signerAddress, { gasLimit: 30000000 });
    
    // await trove.wait();

    //let coll = await borrowerOperationsContract.addColl(0,signerAddress,signerAddress, {value: ethers.utils.parseEther("5")});
    // let coll = await borrowerOperationsContract.addColl(1,signerAddress,signerAddress);
    
    // await coll.wait();

    // const trans = await zusdTokenContract.transfer('0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2',zusd);
    
    // await trans.wait();

    // ['2000000000000000000000','2000000000000000000000','2000000000000000000000','2000000000000000000000,'2000000000000000000000']

    function toPlainString(num) {
        return (''+ +num).replace(/(-?)(\d*)\.?(\d*)e([+-]\d+)/,
          function(a,b,c,d,e) {
            return e < 0
              ? b + '0.' + Array(1-e-c.length).join('0') + c + d
              : b + c + d + Array(e-d.length+1).join('0');
        });
    }

    let price = []; 

    const data = await priceFeedContract.fetchEntirePrice();

    // await data.wait();

    for(let i = 0; i < data.length; i++){
      price.push(toPlainString(data[i]._hex));
    }

    // let balance = await zusdTokenContract.balanceOf('0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2');
    // balance = toPlainString(balance._hex);

    // Done! The contract is deployed.
    console.log(price);
    // console.log(balance);
    console.log(borrowerOperationsAddress);

  } catch (e) {
    console.log(e.message)
  }
})();