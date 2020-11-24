 

pragma solidity ^0.5.2;
pragma experimental "ABIEncoderV2";
 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

 

pragma solidity 0.5.7;


 
library RebalancingLibrary {

     

    enum State { Default, Proposal, Rebalance, Drawdown }

     

    struct AuctionPriceParameters {
        uint256 auctionStartTime;
        uint256 auctionTimeToPivot;
        uint256 auctionStartPrice;
        uint256 auctionPivotPrice;
    }

    struct BiddingParameters {
        uint256 minimumBid;
        uint256 remainingCurrentSets;
        uint256[] combinedCurrentUnits;
        uint256[] combinedNextSetUnits;
        address[] combinedTokenArray;
    }
}

 

 

pragma solidity 0.5.7;




 
interface IAuctionPriceCurve {

     
    function priceDivisor()
        external
        view
        returns (uint256);

     
    function validateAuctionPriceParameters(
        RebalancingLibrary.AuctionPriceParameters calldata _auctionPriceParameters
    )
        external
        view;

     
    function getCurrentPrice(
        RebalancingLibrary.AuctionPriceParameters calldata _auctionPriceParameters
    )
        external
        view
        returns (uint256, uint256);
}

 

 

pragma solidity 0.5.7;


 
interface ICore {
     
    function transferProxy()
        external
        view
        returns (address);

     
    function vault()
        external
        view
        returns (address);

     
    function exchangeIds(
        uint8 _exchangeId
    )
        external
        view
        returns (address);

     
    function validSets(address)
        external
        view
        returns (bool);

     
    function validModules(address)
        external
        view
        returns (bool);

     
    function validPriceLibraries(
        address _priceLibrary
    )
        external
        view
        returns (bool);

     
    function issue(
        address _set,
        uint256 _quantity
    )
        external;

     
    function issueTo(
        address _recipient,
        address _set,
        uint256 _quantity
    )
        external;

     
    function issueInVault(
        address _set,
        uint256 _quantity
    )
        external;

     
    function redeem(
        address _set,
        uint256 _quantity
    )
        external;

     
    function redeemTo(
        address _recipient,
        address _set,
        uint256 _quantity
    )
        external;

     
    function redeemInVault(
        address _set,
        uint256 _quantity
    )
        external;

     
    function redeemAndWithdrawTo(
        address _set,
        address _to,
        uint256 _quantity,
        uint256 _toExclude
    )
        external;

     
    function batchDeposit(
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external;

     
    function batchWithdraw(
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external;

     
    function deposit(
        address _token,
        uint256 _quantity
    )
        external;

     
    function withdraw(
        address _token,
        uint256 _quantity
    )
        external;

     
    function internalTransfer(
        address _token,
        address _to,
        uint256 _quantity
    )
        external;

     
    function createSet(
        address _factory,
        address[] calldata _components,
        uint256[] calldata _units,
        uint256 _naturalUnit,
        bytes32 _name,
        bytes32 _symbol,
        bytes calldata _callData
    )
        external
        returns (address);

     
    function depositModule(
        address _from,
        address _to,
        address _token,
        uint256 _quantity
    )
        external;

     
    function withdrawModule(
        address _from,
        address _to,
        address _token,
        uint256 _quantity
    )
        external;

     
    function batchDepositModule(
        address _from,
        address _to,
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external;

     
    function batchWithdrawModule(
        address _from,
        address _to,
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external;

     
    function issueModule(
        address _owner,
        address _recipient,
        address _set,
        uint256 _quantity
    )
        external;

     
    function redeemModule(
        address _burnAddress,
        address _incrementAddress,
        address _set,
        uint256 _quantity
    )
        external;

     
    function batchIncrementTokenOwnerModule(
        address[] calldata _tokens,
        address _owner,
        uint256[] calldata _quantities
    )
        external;

     
    function batchDecrementTokenOwnerModule(
        address[] calldata _tokens,
        address _owner,
        uint256[] calldata _quantities
    )
        external;

     
    function batchTransferBalanceModule(
        address[] calldata _tokens,
        address _from,
        address _to,
        uint256[] calldata _quantities
    )
        external;

     
    function transferModule(
        address _token,
        uint256 _quantity,
        address _from,
        address _to
    )
        external;

     
    function batchTransferModule(
        address[] calldata _tokens,
        uint256[] calldata _quantities,
        address _from,
        address _to
    )
        external;
}

 

 

pragma solidity 0.5.7;



 

interface IRebalancingSetToken {

     
    function auctionLibrary()
        external
        view
        returns (address);

     
    function totalSupply()
        external
        view
        returns (uint256);

     
    function proposalStartTime()
        external
        view
        returns (uint256);

     
    function lastRebalanceTimestamp()
        external
        view
        returns (uint256);

     
    function rebalanceInterval()
        external
        view
        returns (uint256);

     
    function rebalanceState()
        external
        view
        returns (RebalancingLibrary.State);

     
    function startingCurrentSetAmount()
        external
        view
        returns (uint256);

     
    function balanceOf(
        address owner
    )
        external
        view
        returns (uint256);

     
    function propose(
        address _nextSet,
        address _auctionLibrary,
        uint256 _auctionTimeToPivot,
        uint256 _auctionStartPrice,
        uint256 _auctionPivotPrice
    )
        external;

     
    function naturalUnit()
        external
        view
        returns (uint256);

     
    function currentSet()
        external
        view
        returns (address);

     
    function nextSet()
        external
        view
        returns (address);

     
    function unitShares()
        external
        view
        returns (uint256);

     
    function burn(
        address _from,
        uint256 _quantity
    )
        external;

     
    function placeBid(
        uint256 _quantity
    )
        external
        returns (address[] memory, uint256[] memory, uint256[] memory);

     
    function getCombinedTokenArrayLength()
        external
        view
        returns (uint256);

     
    function getCombinedTokenArray()
        external
        view
        returns (address[] memory);

     
    function getFailedAuctionWithdrawComponents()
        external
        view
        returns (address[] memory);

     
    function getAuctionPriceParameters()
        external
        view
        returns (uint256[] memory);

     
    function getBiddingParameters()
        external
        view
        returns (uint256[] memory);

     
    function getBidPrice(
        uint256 _quantity
    )
        external
        view
        returns (uint256[] memory, uint256[] memory);

}

 

 

pragma solidity 0.5.7;

 
interface ISetToken {

     

     
    function naturalUnit()
        external
        view
        returns (uint256);

     
    function getComponents()
        external
        view
        returns (address[] memory);

     
    function getUnits()
        external
        view
        returns (uint256[] memory);

     
    function tokenIsComponent(
        address _tokenAddress
    )
        external
        view
        returns (bool);

     
    function mint(
        address _issuer,
        uint256 _quantity
    )
        external;

     
    function burn(
        address _from,
        uint256 _quantity
    )
        external;

     
    function transfer(
        address to,
        uint256 value
    )
        external;
}

 

 

pragma solidity 0.5.7;


 
interface IMedian {

     
    function read()
        external
        view
        returns (bytes32);

     
    function peek()
        external
        view
        returns (bytes32, bool);
}

 

 

pragma solidity 0.5.7;







 
library FlexibleTimingManagerLibrary {
    using SafeMath for uint256;

     
    function validateManagerPropose(
        IRebalancingSetToken _rebalancingSetInterface
    )
        internal
    {
         
        uint256 lastRebalanceTimestamp = _rebalancingSetInterface.lastRebalanceTimestamp();
        uint256 rebalanceInterval = _rebalancingSetInterface.rebalanceInterval();
        require(
            block.timestamp >= lastRebalanceTimestamp.add(rebalanceInterval),
            "FlexibleTimingManagerLibrary.proposeNewRebalance: Rebalance interval not elapsed"
        );

         
         
        require(
            _rebalancingSetInterface.rebalanceState() == RebalancingLibrary.State.Default,
            "FlexibleTimingManagerLibrary.proposeNewRebalance: State must be in Default"
        );
    }

     
    function calculateAuctionPriceParameters(
        uint256 _currentSetDollarAmount,
        uint256 _nextSetDollarAmount,
        uint256 _timeIncrement,
        uint256 _auctionLibraryPriceDivisor,
        uint256 _auctionTimeToPivot
    )
        internal
        view
        returns (uint256, uint256)
    {
         
        uint256 fairValue = _nextSetDollarAmount.mul(_auctionLibraryPriceDivisor).div(_currentSetDollarAmount);
         
        uint256 onePercentSlippage = fairValue.div(100);

         
        uint256 timeIncrements = _auctionTimeToPivot.div(_timeIncrement);
         
         
         
        uint256 halfPriceRange = timeIncrements.mul(onePercentSlippage).div(2);

         
        uint256 auctionStartPrice = fairValue.sub(halfPriceRange);
         
        uint256 auctionPivotPrice = fairValue.add(halfPriceRange);

        return (auctionStartPrice, auctionPivotPrice);
    }

     
    function queryPriceData(
        address _priceFeedAddress
    )
        internal
        view
        returns (uint256)
    {
         
        bytes32 priceInBytes = IMedian(_priceFeedAddress).read();

        return uint256(priceInBytes);
    }

     
    function calculateSetTokenDollarValue(
        uint256[] memory _tokenPrices,
        uint256 _naturalUnit,
        uint256[] memory _units,
        uint256[] memory _tokenDecimals
    )
        internal
        view
        returns (uint256)
    {
        uint256 setDollarAmount = 0;

         
        for (uint256 i = 0; i < _tokenPrices.length; i++) {
            uint256 tokenDollarValue = calculateTokenAllocationAmountUSD(
                _tokenPrices[i],
                _naturalUnit,
                _units[i],
                _tokenDecimals[i]
            );

            setDollarAmount = setDollarAmount.add(tokenDollarValue);
        }

        return setDollarAmount;
    }

     
    function calculateTokenAllocationAmountUSD(
        uint256 _tokenPrice,
        uint256 _naturalUnit,
        uint256 _unit,
        uint256 _tokenDecimals
    )
        internal
        view
        returns (uint256)
    {
        uint256 SET_TOKEN_DECIMALS = 18;

         
        uint256 componentUnitsInFullToken = _unit
            .mul(10 ** SET_TOKEN_DECIMALS)
            .div(_naturalUnit);

         
        uint256 allocationUSDValue = _tokenPrice
            .mul(componentUnitsInFullToken)
            .div(10 ** _tokenDecimals);

        require(
            allocationUSDValue > 0,
            "FlexibleTimingManagerLibrary.calculateTokenAllocationAmountUSD: Value must be > 0"
        );

        return allocationUSDValue;
    }
}

 

 

pragma solidity 0.5.7;



 
interface IAllocator {

     
    function determineNewAllocation(
        uint256 _targetBaseAssetAllocation,
        uint256 _allocationPrecision,
        ISetToken _currentCollateralSet
    )
        external
        returns (ISetToken);

     
    function calculateCollateralSetValue(
        ISetToken _collateralSet
    )
        external
        view
        returns(uint256);
}

 

 

pragma solidity 0.5.7;


 
interface ITrigger {
     
    function isBullish()
        external
        view
        returns (bool);
}

 

 

pragma solidity 0.5.7;












 
contract AssetPairManager {
    using SafeMath for uint256;

     

    event InitialProposeCalled(
        address indexed rebalancingSetToken
    );

     
    uint256 constant private HUNDRED = 100;

     
    ICore public core;
    IAllocator public allocator;
    ITrigger public trigger;
    IAuctionPriceCurve public auctionLibrary;
    IRebalancingSetToken public rebalancingSetToken;
    uint256 public baseAssetAllocation;   
    uint256 public allocationDenominator;
    uint256 public bullishBaseAssetAllocation;
    uint256 public bearishBaseAssetAllocation;
    uint256 public auctionStartPercentage;  
    uint256 public auctionPivotPercentage;   
    uint256 public auctionTimeToPivot;

     
    uint256 public signalConfirmationMinTime;
     
    uint256 public signalConfirmationMaxTime;
     
    uint256 public recentInitialProposeTimestamp;

    address public initializerAddress;

     
    constructor(
        ICore _core,
        IAllocator _allocator,
        ITrigger _trigger,
        IAuctionPriceCurve _auctionLibrary,
        uint256 _baseAssetAllocation,
        uint256 _allocationDenominator,
        uint256 _bullishBaseAssetAllocation,
        uint256 _auctionTimeToPivot,
        uint256[2] memory _auctionPriceBounds,
        uint256[2] memory _signalConfirmationBounds
    )
        public
    {
         
        require(
            _bullishBaseAssetAllocation <= _allocationDenominator,
            "AssetPairManager.constructor: Passed bullishBaseAssetAllocation must be less than allocationDenominator."
        );

        bullishBaseAssetAllocation = _bullishBaseAssetAllocation;
        bearishBaseAssetAllocation = _allocationDenominator.sub(_bullishBaseAssetAllocation);

         
        require(
            bullishBaseAssetAllocation == _baseAssetAllocation || bearishBaseAssetAllocation == _baseAssetAllocation,
            "AssetPairManager.constructor: Passed baseAssetAllocation must equal bullish or bearish allocations."
        );

         
        require(
            _signalConfirmationBounds[1] >= _signalConfirmationBounds[0],
            "AssetPairManager.constructor: Confirmation max time must be greater than min time."
        );

        core = _core;
        allocator = _allocator;
        trigger = _trigger;
        auctionLibrary = _auctionLibrary;
        baseAssetAllocation = _baseAssetAllocation;
        allocationDenominator = _allocationDenominator;
        auctionTimeToPivot = _auctionTimeToPivot;
        auctionStartPercentage = _auctionPriceBounds[0];
        auctionPivotPercentage = _auctionPriceBounds[1];
        signalConfirmationMinTime = _signalConfirmationBounds[0];
        signalConfirmationMaxTime = _signalConfirmationBounds[1];
        initializerAddress = msg.sender;
    }

     

     
    function initialize(
        IRebalancingSetToken _rebalancingSetToken
    )
        external
    {
         
        require(
            msg.sender == initializerAddress,
            "AssetPairManager.initialize: Only the contract deployer can initialize"
        );

         
        require(   
            core.validSets(address(_rebalancingSetToken)),
            "AssetPairManager.initialize: Invalid or disabled RebalancingSetToken address"
        );

        rebalancingSetToken = _rebalancingSetToken;
         
        initializerAddress = address(0);
    }

     
    function initialPropose()
        external
    {
         
        require(
            address(rebalancingSetToken) != address(0),
            "AssetPairManager.confirmPropose: Manager must be initialized with RebalancingSetToken."
        );

         
        FlexibleTimingManagerLibrary.validateManagerPropose(rebalancingSetToken);

         
        require(
            hasConfirmationWindowElapsed(),
            "AssetPairManager.initialPropose: Not enough time passed from last proposal."
        );

         
        uint256 newBaseAssetAllocation = calculateBaseAssetAllocation();

         
        require(
            newBaseAssetAllocation != baseAssetAllocation,
            "AssetPairManager.initialPropose: No change in allocation detected."
        );

         
        recentInitialProposeTimestamp = block.timestamp;

        emit InitialProposeCalled(address(rebalancingSetToken));
    }

      
    function confirmPropose()
        external
    {
         
        require(
            address(rebalancingSetToken) != address(0),
            "AssetPairManager.confirmPropose: Manager must be initialized with RebalancingSetToken."
        );

         
        FlexibleTimingManagerLibrary.validateManagerPropose(rebalancingSetToken);

         
        require(
            inConfirmationWindow(),
            "AssetPairManager.confirmPropose: Confirming signal must be within confirmation window."
        );

         
        uint256 newBaseAssetAllocation = calculateBaseAssetAllocation();

         
        require(
            newBaseAssetAllocation != baseAssetAllocation,
            "AssetPairManager.confirmPropose: No change in allocation detected."
        );

         
        ISetToken currentCollateralSet = ISetToken(rebalancingSetToken.currentSet());

         
         
        ISetToken nextSet = allocator.determineNewAllocation(
            newBaseAssetAllocation,
            allocationDenominator,
            currentCollateralSet
        );

         
        uint256 currentSetDollarValue = allocator.calculateCollateralSetValue(
            currentCollateralSet
        );

        uint256 nextSetDollarValue = allocator.calculateCollateralSetValue(
            nextSet
        );

         
        uint256 auctionPriceDivisor = auctionLibrary.priceDivisor();

         
        (
            uint256 auctionStartPrice,
            uint256 auctionPivotPrice
        ) = calculateAuctionPriceParameters(
            currentSetDollarValue,
            nextSetDollarValue,
            auctionPriceDivisor
        );

         
        rebalancingSetToken.propose(
            address(nextSet),
            address(auctionLibrary),
            auctionTimeToPivot,
            auctionStartPrice,
            auctionPivotPrice
        );

         
        baseAssetAllocation = newBaseAssetAllocation;
    }

     
    function canInitialPropose()
        external
        view
        returns (bool)
    {
         
         
        return rebalancingSetTokenInValidState()
            && calculateBaseAssetAllocation() != baseAssetAllocation
            && hasConfirmationWindowElapsed();
    }

     
    function canConfirmPropose()
        external
        view
        returns (bool)
    {
         
         
        return rebalancingSetTokenInValidState()
            && calculateBaseAssetAllocation() != baseAssetAllocation
            && inConfirmationWindow();
    }

     

     
    function calculateBaseAssetAllocation()
        internal
        view
        returns (uint256)
    {
        return trigger.isBullish() ? bullishBaseAssetAllocation : bearishBaseAssetAllocation;
    }

     
    function calculateAuctionPriceParameters(
        uint256 _currentSetDollarAmount,
        uint256 _nextSetDollarAmount,
        uint256 _auctionLibraryPriceDivisor
    )
        internal
        view
        returns (uint256, uint256)
    {
         
        uint256 fairValue = _nextSetDollarAmount.mul(_auctionLibraryPriceDivisor).div(_currentSetDollarAmount);
         
        uint256 onePercentSlippage = fairValue.div(HUNDRED);

         
        uint256 auctionStartPrice = fairValue.sub(
            auctionStartPercentage.mul(onePercentSlippage)
        );
         
        uint256 auctionPivotPrice = fairValue.add(
            auctionPivotPercentage.mul(onePercentSlippage)
        );

        return (auctionStartPrice, auctionPivotPrice);
    }

      
    function rebalancingSetTokenInValidState()
        internal
        view
        returns (bool)
    {
         
        uint256 lastRebalanceTimestamp = rebalancingSetToken.lastRebalanceTimestamp();
        uint256 rebalanceInterval = rebalancingSetToken.rebalanceInterval();

         
        return block.timestamp.sub(lastRebalanceTimestamp) >= rebalanceInterval &&
            rebalancingSetToken.rebalanceState() == RebalancingLibrary.State.Default;
    }

     
    function hasConfirmationWindowElapsed()
        internal
        view
        returns (bool)
    {
        return block.timestamp.sub(recentInitialProposeTimestamp) > signalConfirmationMaxTime;
    }

     
    function inConfirmationWindow()
        internal
        view
        returns (bool)
    {
        uint256 timeSinceInitialPropose = block.timestamp.sub(recentInitialProposeTimestamp);
        return timeSinceInitialPropose >= signalConfirmationMinTime && timeSinceInitialPropose <= signalConfirmationMaxTime;
    }
}