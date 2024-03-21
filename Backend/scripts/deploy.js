async function main() {

    const activepool = await ethers.getContractFactory("ActivePool");
    const activepoolContract = await activepool.deploy();
    await activepoolContract.deployed();

    const borrower = await ethers.getContractFactory("BorrowerOperations");
    const borrowerContract = await borrower.deploy();
    await borrowerContract.deployed();

    const community = await ethers.getContractFactory("CommunityIssuance");
    const communityissuanceContract = await community.deploy();
    await communityissuanceContract.deployed();

    const defaultpool = await ethers.getContractFactory("DefaultPool");
    const defaultpoolContract = await defaultpool.deploy();
    await defaultpoolContract.deployed();

    const zqtystaking = await ethers.getContractFactory("ZQTYStaking");
    const zqtystakingContract = await zqtystaking.deploy();
    await zqtystakingContract.deployed();

    const pricefeed = await ethers.getContractFactory("PriceFeedTestnet");
    const pricefeedContract = await pricefeed.deploy();
    await pricefeedContract.deployed();

    const sortedtroves = await ethers.getContractFactory("SortedTroves");
    const sortedtrovesContract = await sortedtroves.deploy();
    await sortedtrovesContract.deployed();;

    const stabilitypool = await ethers.getContractFactory("StabilityPool");
    const stabilitypoolContract = await stabilitypool.deploy();
    await stabilitypoolContract.deployed();

    const proxy = await ethers.getContractFactory("Proxy");
    const proxyContract = await proxy.deploy("0xB5874deeec872e6BEB3df88BDc628b8fAc774C08");
    await proxyContract.deployed();

    const lockupfactory = await ethers.getContractFactory("LockupContractFactory");
    const lockupfactoryContract = await lockupfactory.deploy();
    await lockupfactoryContract.deployed();

    const multisig = await ethers.getContractFactory("MultiSig");
    const multisigContract = await multisig.deploy("zqty","zqty",["0xB5874deeec872e6BEB3df88BDc628b8fAc774C08","0xca4d795FD2213a138d675A5d56caC66dC4bf537a"]);
    await multisigContract.deployed();

    const lptoken = await ethers.getContractFactory("LPTokenWrapper");
    const lptokenContract = await lptoken.deploy();
    await lptokenContract.deployed();

    const zqtytoken = await ethers.getContractFactory("ZQTYToken");
    const zqtytokenContract = await zqtytoken.deploy(communityissuanceContract.address,zqtystakingContract.address,lockupfactoryContract.address,proxyContract.address,lptokenContract.address,multisigContract.address);
    await zqtytokenContract.deployed();

    const trovemanager1 = await ethers.getContractFactory("TroveManager1");
    const trovemanager1Contract = await trovemanager1.deploy();
    await trovemanager1Contract.deployed();

    const trovemanager2 = await ethers.getContractFactory("TroveManager2");
    const trovemanager2Contract = await trovemanager2.deploy();
    await trovemanager2Contract.deployed();

    const trovemanager3 = await ethers.getContractFactory("TroveManager3");
    const trovemanager3Contract = await trovemanager3.deploy();
    await trovemanager3Contract.deployed();

    const hintHelpers = await ethers.getContractFactory("HintHelpers");
    const hintHelpersContract = await hintHelpers.deploy();
    await hintHelpersContract.deployed();

    const gaspool = await ethers.getContractFactory("GasPool");
    const gaspoolContract = await gaspool.deploy();
    await gaspoolContract.deployed();

    const collSurplus = await ethers.getContractFactory("CollSurplusPool");
    const collsurplusContract = await collSurplus.deploy();
    await collsurplusContract.deployed();    

    const zusdtoken = await ethers.getContractFactory("ZUSDToken");
    const zusdtokenContract = await zusdtoken.deploy(trovemanager1Contract.address,trovemanager2Contract.address,trovemanager3Contract.address,stabilitypoolContract.address, borrowerContract.address);
    await zusdtokenContract.deployed();
    
    const erctoken1 = await ethers.getContractFactory("MyToken");
    const erctokenContract1 = await erctoken1.deploy();
    await erctokenContract1.deployed();

    const erctoken2 = await ethers.getContractFactory("MyToken");
    const erctokenContract2 = await erctoken2.deploy();
    await erctokenContract2.deployed();

    const erctoken3 = await ethers.getContractFactory("MyToken");
    const erctokenContract3 = await erctoken3.deploy();
    await erctokenContract3.deployed();

    const erctoken4 = await ethers.getContractFactory("MyToken");
    const erctokenContract4 = await erctoken4.deploy();
    await erctokenContract4.deployed();

    const erctoken5 = await ethers.getContractFactory("MyToken");
    const erctokenContract5 = await erctoken5.deploy();
    await erctokenContract5.deployed();

    console.log(`const ActivePoolAddress = "${activepoolContract.address}"`);
    console.log(`const BorrowerOperationsAddress = "${borrowerContract.address}"`);
    console.log(`const CommunityIssuanceAddress = "${communityissuanceContract.address}"`);
    console.log(`const DefaultPoolAddress = "${defaultpoolContract.address}"`);
    console.log(`const ZUSDTokenAddress = "${zusdtokenContract.address}"`);
    console.log(`const ZQTYTokenAddress = "${zqtytokenContract.address}"`);
    console.log(`const ZQTYStakingAddress = "${zqtystakingContract.address}"`);
    console.log(`const TroveManager1Address = "${trovemanager1Contract.address}"`);
    console.log(`const TroveManager2Address = "${trovemanager2Contract.address}"`);
    console.log(`const TroveManager3Address = "${trovemanager3Contract.address}"`);
    console.log(`const SortedTrovesAddress = "${sortedtrovesContract.address}"`);
    console.log(`const StabilityPoolAddress = "${stabilitypoolContract.address}"`);
    console.log(`const PriceFeedAddress = "${pricefeedContract.address}"`);
    console.log(`const ProxyAddress = "${proxyContract.address}"`);
    console.log(`const LockupFactoryAddress = "${lockupfactoryContract.address}"`);
    console.log(`const MultiSigAddress = "${multisigContract.address}"`);
    console.log(`const LPTokenWrapperAddress = "${lptokenContract.address}"`);
    console.log(`const GasPoolAddress = "${gaspoolContract.address}"`);
    console.log(`const CollSurplusAddress = "${collsurplusContract.address}"`);
    console.log(`const HintHelpersAddress = "${hintHelpersContract.address}"`);

    console.log(`const erctoken1Address = "${erctokenContract1.address}"`);
    console.log(`const erctoken2Address = "${erctokenContract2.address}"`);
    console.log(`const erctoken3Address = "${erctokenContract3.address}"`);
    console.log(`const erctoken4Address = "${erctokenContract4.address}"`);
    console.log(`const erctoken5Address = "${erctokenContract5.address}"`);

  }
  
  main()
    .then(() => {
    })
    .catch((error) => {
      console.error('failed to deploy Contract', error);
    });