import './web3-lib';

(async function() {
    try 
    {
        let i;

        let activePoolContract;
        let borrowerOperationsContract;
        let communityIssuanceContract;
        let defaultPoolContract;
        let collSurplusContract;
        let gasPoolContract;
        let zqtyStakingContract;
        let zqtyTokenContract;
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

        for( i = 1; i < 20; i++) {
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

            activePoolContract = new ethers.Contract(activePoolAddress, activePool.abi, signer);
            borrowerOperationsContract = new ethers.Contract(borrowerOperationsAddress, borrowerOperations.abi, signer);
            communityIssuanceContract = new ethers.Contract(communityIssuanceAddress, communityIssuance.abi, signer);
            defaultPoolContract = new ethers.Contract(defaultPoolAddress, defaultPool.abi, signer);
            collSurplusContract = new ethers.Contract(collSurplusAddress, collSurplus.abi, signer);
            gasPoolContract = new ethers.Contract(gasPoolAddress, gasPool.abi, signer);
            zqtyStakingContract = new ethers.Contract(zqtyStakingAddress, zqtyStaking.abi, signer);
            zqtyTokenContract = new ethers.Contract(zqtyTokenAddress, zqtyToken.abi, signer);
            zusdTokenContract = new ethers.Contract(zusdTokenAddress, zusdToken.abi, signer);
            lockupFactoryContract = new ethers.Contract(lockupFactoryAddress, lockupFactory.abi, signer);
            multiSigContract = new ethers.Contract(multiSigAddress, multiSig.abi, signer);
            priceFeedContract = new ethers.Contract(priceFeedAddress, priceFeed.abi, signer);
            proxyContract = new ethers.Contract(proxyAddress, proxy.abi, signer);
            sortedTrovesContract = new ethers.Contract(sortedTrovesAddress, sortedTroves.abi, signer);
            stabilityPoolContract = new ethers.Contract(stabilityPoolAddress, stabilityPool.abi, signer);
            troveManager1Contract = new ethers.Contract(troveManager1Address, troveManager1.abi, signer);
            troveManager2Contract = new ethers.Contract(troveManager2Address, troveManager2.abi, signer);
            troveManager3Contract = new ethers.Contract(troveManager3Address, troveManager3.abi, signer);
            lpTokenWrapperContract = new ethers.Contract(lpTokenWrapperAddress, lpTokenWrapper.abi, signer);
            hintHelpersContract = new ethers.Contract(hintHelpersAddress, hintHelpers.abi, signer);
            ercToken1Contract = new ethers.Contract(ercToken1Address, ercToken1.abi, signer);
            ercToken2Contract = new ethers.Contract(ercToken2Address, ercToken2.abi, signer);
            ercToken3Contract = new ethers.Contract(ercToken3Address, ercToken3.abi, signer);
            ercToken4Contract = new ethers.Contract(ercToken4Address, ercToken4.abi, signer);
            ercToken5Contract = new ethers.Contract(ercToken5Address, ercToken5.abi, signer);

            const toWei = web3.utils.toWei
            const toBN = web3.utils.toBN

            let fee = '5000000000000000';
            let val = '5000000000000000000';
            let zusd = toWei('1800');
            let add = "0x0000000000000000000000000000000000000000";
            let trove;

            let eth;

            if(n == 1 || n == 4 || n == 7) {eth = "5000000000000000000"; val = "5000000000000000000"}
            if(n == 2 || n == 5 || n == 8) {eth = "1250000000000000000"; val = "1250000000000000000"}
            if(n == 3 || n == 6 || n == 9) {eth = "1150000000000000000"; val = "1150000000000000000"}

            if(n == 10) {val = "10000000000000000000"}
            if(n == 11) {val = "8500000000000000000"}
            if(n == 12) {val = "8250000000000000000"}

            if(n == 13) {val = "250000000000000000000"}
            if(n == 14) {val = "125000000000000000000"}
            if(n == 15) {val = "120000000000000000000"}

            if(n == 16) {val = "5000000000000000000000"}
            if(n == 17) {val = "2750000000000000000000"}
            if(n == 18) {val = "2500000000000000000000"}



            if(n != 19) {
                const LUSDAmount = toBN(toWei('1800')) // borrower wants to withdraw 2500 LUSD
                const ETHColl = toBN(toWei('5')) // borrower wants to lock 5 ETH collateral

                const liquidationReserve = await troveManager1Contract.ZUSD_GAS_COMPENSATION()
                const expectedFee = await troveManager2Contract.getBorrowingFeeWithDecay(zusd)
                const expectedDebt =  parseInt(zusd) + parseInt(expectedFee) + parseInt(liquidationReserve)

                const _1e20 = toBN(toWei('100'))
                let NICR = val * _1e20 / expectedDebt
                // NICR = String(NICR);
                // console.log(NICR);

                NICR = BigInt(NICR);

                // Get an approximate address hint from the deployed HintHelper contract. Use (15 * number of troves) trials 
                // to get an approx. hint that is close to the right position.
                let numTroves = await sortedTrovesContract.getSize(0)
                let numTrials = numTroves.mul(15)

                let { 0: approxHint } = await hintHelpersContract.getApproxHint(0,NICR, numTrials, 42)  // random seed of 42

                let hint = `"${approxHint}"`;

                // Use the approximate hint to get the exact upper and lower hints from the deployed SortedTroves contract
                let { 0: upperHint, 1: lowerHint } = await sortedTrovesContract.findInsertPosition('0',NICR, approxHint, approxHint)

                // Finally, call openTrove with the exact upperHint and lowerHint
                const maxFee = '5'.concat('0'.repeat(16)) // Slippage protection: 5%

                // console.log(fee, zusd, upperHint, lowerHint, eth);

                if(n < 4) {
                    trove = await borrowerOperationsContract.openTrovewithEth(fee, zusd, upperHint, lowerHint, {value: eth});

                    await trove.wait();

                    let trans = await zusdTokenContract.transfer('0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199',zusd);

                    trans.wait();
                } 
                else {
                    let id;
                    if(n > 3 && n < 7) {
                        id = 1;
                    }
                    else if(n > 6 && n < 10) {
                        id = 2;
                    }
                    else if(n > 9 && n < 13) {
                        id = 3;
                    }
                    else if(n > 12 && n < 16) {
                        id = 4;
                    }
                    else if(n > 15 && n < 19) {
                        id = 5;
                    }
                    
                    const ercTokenContracts = [
                        null, // 0th index unused
                        ercToken1Contract,
                        ercToken2Contract,
                        ercToken3Contract,
                        ercToken4Contract,
                        ercToken5Contract
                    ];
                        
                    const ercTokenContract = ercTokenContracts[id];

                    let transac = await ercTokenContract.approve(borrowerOperationsAddress, val);

                    transac.wait();

                    trove = await borrowerOperationsContract.openTrovewithTokens(fee,id,val,zusd,upperHint,lowerHint);

                    await trove.wait();

                    let bal = await zusdTokenContract.balanceOf(signerAddress);
                    let trans = await zusdTokenContract.transfer('0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199',zusd);
                    // let trans = await stabilityPoolContract.provideToSP(bal);

                    trans.wait();
                }
            }

            if(n == 18) {
                const p = await priceFeedContract.setPrice(['1500000000000000000000','1500000000000000000000','1500000000000000000000','100000000000000000000','10000000000000000000','500000000000000000']);
                await p.wait();
            }

            if(n == 20) {
                let j;
                for(j = 0; j < 6 ; j++) {
                    let liquidate = await troveManager3Contract.liquidateTroves(j, 2, { gasLimit: 30000000 });
                    await liquidate.wait();

                    console.log(liquidate.hash);
                }
            }

            // [2000000000000000000000,2000000000000000000000,21000000000000000000000,300000000000000000000,20000000000000000000,1000000000000000000]
            // ["1500000000000000000000","1500000000000000000000","1500000000000000000000","100000000000000000000","10000000000000000000","500000000000000000"]
            // let eth = BigInt(2000000000000000000000);
            // let btc = BigInt(21000000000000000000000);
            // let bnb = BigInt(3000000000000000000000);
            // let sol = BigInt(200000000000000000000);
            // let usd = BigInt(10000000000000000000);

            //   let balance = await zusdTokenContract.balanceOf(accounts[6]);
            //   balance = toPlainString(balance._hex);

            // Done! The contract is deployed.
            if(n < 19) console.log("Signer " + i + ": " + trove.hash);
        }

        let k;
        for(k = 1; k < 6; k++) {
            const ercTokenContracts = [
                null, // 0th index unused
                ercToken1Contract,
                ercToken2Contract,
                ercToken3Contract,
                ercToken4Contract,
                ercToken5Contract
            ];

            const ercTokenContract = ercTokenContracts[k];
            let bal = await ercTokenContract.balanceOf('0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199');

            console.log(toPlainString(bal._hex));
        }
    
        function toPlainString(num) {
            return (''+ +num).replace(/(-?)(\d*)\.?(\d*)e([+-]\d+)/,
            function(a,b,c,d,e) {
                return e < 0
                ? b + '0.' + Array(1-e-c.length).join('0') + c + d
                : b + c + d + Array(e-d.length+1).join('0');
            });
        }
    }
    catch (e) {
        console.log(e.message)
    }
})();

7738989440000000000000 * 8500000000000000000 / 1e18

24108000000000000000000
12054000000000000000000
36162000000000000000000

65781410240000000000000
65781410240000000000000000000000000000000
967373680000000000000000

7292480000000000000,6146240000000000000,5000000000000000000,26750000000000000000,495000000000000000000,10250000000000000000000
95520000000000000,1241760000000000000,2388000000000000000,0,0,0