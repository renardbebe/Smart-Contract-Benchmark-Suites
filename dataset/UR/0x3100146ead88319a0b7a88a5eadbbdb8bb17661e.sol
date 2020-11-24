 

 

pragma solidity ^0.5.2;
pragma experimental "ABIEncoderV2";

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.2;


 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

 

pragma solidity ^0.5.2;

 
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



 

interface IRebalancingSetToken {

     
    function totalSupply()
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

     
    function getBiddingParameters()
        external
        view
        returns (uint256[] memory);

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




library SetTokenLibrary {
    using SafeMath for uint256;

    struct SetDetails {
        uint256 naturalUnit;
        address[] components;
        uint256[] units;
    }

     
    function validateTokensAreComponents(
        address _set,
        address[] calldata _tokens
    )
        external
        view
    {
        for (uint256 i = 0; i < _tokens.length; i++) {
             
            require(
                ISetToken(_set).tokenIsComponent(_tokens[i]),
                "SetTokenLibrary.validateTokensAreComponents: Component must be a member of Set"
            );

        }
    }

     
    function isMultipleOfSetNaturalUnit(
        address _set,
        uint256 _quantity
    )
        external
        view
    {
        require(
            _quantity.mod(ISetToken(_set).naturalUnit()) == 0,
            "SetTokenLibrary.isMultipleOfSetNaturalUnit: Quantity is not a multiple of nat unit"
        );
    }

     
    function getSetDetails(
        address _set
    )
        internal
        view
        returns (SetDetails memory)
    {
         
        ISetToken setToken = ISetToken(_set);

         
        uint256 naturalUnit = setToken.naturalUnit();
        address[] memory components = setToken.getComponents();
        uint256[] memory units = setToken.getUnits();

        return SetDetails({
            naturalUnit: naturalUnit,
            components: components,
            units: units
        });
    }
}

 

 

pragma solidity 0.5.7;


 
interface IOracle {

     
    function read()
        external
        view
        returns (uint256);
}

 

 

pragma solidity 0.5.7;


 
interface IMetaOracleV2 {

     
    function read(
        uint256 _dataDays
    )
        external
        view
        returns (uint256);
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











 
contract MACOStrategyManagerV2 {
    using SafeMath for uint256;

     
    uint256 constant AUCTION_LIB_PRICE_DIVISOR = 1000;
    uint256 constant ALLOCATION_PRICE_RATIO_LIMIT = 4;

    uint256 constant TEN_MINUTES_IN_SECONDS = 600;

     
    uint256 constant STABLE_ASSET_PRICE = 10 ** 18;
    uint256 constant SET_TOKEN_DECIMALS = 10 ** 18;

     
    address public contractDeployer;
    address public rebalancingSetTokenAddress;
    address public coreAddress;
    address public setTokenFactory;
    address public auctionLibrary;

    IMetaOracleV2 public movingAveragePriceFeedInstance;
    IOracle public riskAssetOracleInstance;

    address public stableAssetAddress;
    address public riskAssetAddress;
    address public stableCollateralAddress;
    address public riskCollateralAddress;

    uint256 public stableAssetDecimals;
    uint256 public riskAssetDecimals;

    uint256 public auctionTimeToPivot;
    uint256 public movingAverageDays;
    uint256 public lastCrossoverConfirmationTimestamp;

    uint256 public crossoverConfirmationMinTime;
    uint256 public crossoverConfirmationMaxTime;

     

    event LogManagerProposal(
        uint256 riskAssetPrice,
        uint256 movingAveragePrice
    );

     
    constructor(
        address _coreAddress,
        IMetaOracleV2 _movingAveragePriceFeed,
        IOracle _riskAssetOracle,
        address _stableAssetAddress,
        address _riskAssetAddress,
        address[2] memory _collateralAddresses,
        address _setTokenFactory,
        address _auctionLibrary,
        uint256 _movingAverageDays,
        uint256 _auctionTimeToPivot,
        uint256[2] memory _crossoverConfirmationBounds
    )
        public
    {
        contractDeployer = msg.sender;
        coreAddress = _coreAddress;
        movingAveragePriceFeedInstance = _movingAveragePriceFeed;
        riskAssetOracleInstance = _riskAssetOracle;
        setTokenFactory = _setTokenFactory;
        auctionLibrary = _auctionLibrary;

        stableAssetAddress = _stableAssetAddress;
        riskAssetAddress = _riskAssetAddress;
        stableCollateralAddress = _collateralAddresses[0];
        riskCollateralAddress = _collateralAddresses[1];

        auctionTimeToPivot = _auctionTimeToPivot;
        movingAverageDays = _movingAverageDays;
        lastCrossoverConfirmationTimestamp = 0;

        crossoverConfirmationMinTime = _crossoverConfirmationBounds[0];
        crossoverConfirmationMaxTime = _crossoverConfirmationBounds[1];

        address[] memory initialStableCollateralComponents = ISetToken(_collateralAddresses[0]).getComponents();
        address[] memory initialRiskCollateralComponents = ISetToken(_collateralAddresses[1]).getComponents();

        require(
            crossoverConfirmationMaxTime > crossoverConfirmationMinTime,
            "MACOStrategyManager.constructor: Max confirmation time must be greater than min."
        );

        require(
            initialStableCollateralComponents[0] == _stableAssetAddress,
            "MACOStrategyManager.constructor: Stable collateral component must match stable asset."
        );

        require(
            initialRiskCollateralComponents[0] == _riskAssetAddress,
            "MACOStrategyManager.constructor: Risk collateral component must match risk asset."
        );

         
        stableAssetDecimals = ERC20Detailed(_stableAssetAddress).decimals();
        riskAssetDecimals = ERC20Detailed(_riskAssetAddress).decimals();
    }

     

     
    function initialize(
        address _rebalancingSetTokenAddress
    )
        external
    {
         
        require(
            msg.sender == contractDeployer,
            "MACOStrategyManager.initialize: Only the contract deployer can initialize"
        );

         
        require(
            ICore(coreAddress).validSets(_rebalancingSetTokenAddress),
            "MACOStrategyManager.initialize: Invalid or disabled RebalancingSetToken address"
        );

        rebalancingSetTokenAddress = _rebalancingSetTokenAddress;
        contractDeployer = address(0);
    }

     
    function initialPropose()
        external
    {
         
        require(
            block.timestamp > lastCrossoverConfirmationTimestamp.add(crossoverConfirmationMaxTime),
            "MACOStrategyManager.initialPropose: 12 hours must pass before new proposal initiated"
        );

         
        FlexibleTimingManagerLibrary.validateManagerPropose(IRebalancingSetToken(rebalancingSetTokenAddress));

         
        (
            uint256 riskAssetPrice,
            uint256 movingAveragePrice
        ) = getPriceData();

         
        checkPriceTriggerMet(riskAssetPrice, movingAveragePrice);

        lastCrossoverConfirmationTimestamp = block.timestamp;
    }

     
    function confirmPropose()
        external
    {
         
        require(
            block.timestamp >= lastCrossoverConfirmationTimestamp.add(crossoverConfirmationMinTime) &&
            block.timestamp <= lastCrossoverConfirmationTimestamp.add(crossoverConfirmationMaxTime),
            "MACOStrategyManager.confirmPropose: Confirming signal must be within bounds of the initial propose"
        );

         
        FlexibleTimingManagerLibrary.validateManagerPropose(IRebalancingSetToken(rebalancingSetTokenAddress));

         
        (
            uint256 riskAssetPrice,
            uint256 movingAveragePrice
        ) = getPriceData();

         
        checkPriceTriggerMet(riskAssetPrice, movingAveragePrice);

         
         
        (
            address nextSetAddress,
            uint256 currentSetDollarValue,
            uint256 nextSetDollarValue
        ) = determineNewAllocation(
            riskAssetPrice
        );

         
        (
            uint256 auctionStartPrice,
            uint256 auctionPivotPrice
        ) = FlexibleTimingManagerLibrary.calculateAuctionPriceParameters(
            currentSetDollarValue,
            nextSetDollarValue,
            TEN_MINUTES_IN_SECONDS,
            AUCTION_LIB_PRICE_DIVISOR,
            auctionTimeToPivot
        );

         
        IRebalancingSetToken(rebalancingSetTokenAddress).propose(
            nextSetAddress,
            auctionLibrary,
            auctionTimeToPivot,
            auctionStartPrice,
            auctionPivotPrice
        );

        emit LogManagerProposal(
            riskAssetPrice,
            movingAveragePrice
        );
    }

     

     
    function usingRiskCollateral()
        internal
        view
        returns (bool)
    {
         
        address[] memory currentCollateralComponents = ISetToken(rebalancingSetTokenAddress).getComponents();

         
        return (currentCollateralComponents[0] == riskCollateralAddress);
    }

     
    function getPriceData()
        internal
        view
        returns(uint256, uint256)
    {
         
        uint256 riskAssetPrice = riskAssetOracleInstance.read();
        uint256 movingAveragePrice = movingAveragePriceFeedInstance.read(movingAverageDays);

        return (riskAssetPrice, movingAveragePrice);
    }

     
    function checkPriceTriggerMet(
        uint256 _riskAssetPrice,
        uint256 _movingAveragePrice
    )
        internal
        view
    {
        if (usingRiskCollateral()) {
             
            require(
                _movingAveragePrice > _riskAssetPrice,
                "MACOStrategyManager.checkPriceTriggerMet: Risk asset price must be below moving average price"
            );
        } else {
             
            require(
                _movingAveragePrice < _riskAssetPrice,
                "MACOStrategyManager.checkPriceTriggerMet: Risk asset price must be above moving average price"
            );
        }
    }

     
    function determineNewAllocation(
        uint256 _riskAssetPrice
    )
        internal
        returns (address, uint256, uint256)
    {
         
         
        (
            uint256 stableCollateralDollarValue,
            uint256 riskCollateralDollarValue
        ) = checkForNewAllocation(_riskAssetPrice);

        (
            address nextSetAddress,
            uint256 currentSetDollarValue,
            uint256 nextSetDollarValue
        ) = usingRiskCollateral() ? (stableCollateralAddress, riskCollateralDollarValue, stableCollateralDollarValue) :
            (riskCollateralAddress, stableCollateralDollarValue, riskCollateralDollarValue);

        return (nextSetAddress, currentSetDollarValue, nextSetDollarValue);
    }

     
    function checkForNewAllocation(
        uint256 _riskAssetPrice
    )
        internal
        returns(uint256, uint256)
    {
         
        SetTokenLibrary.SetDetails memory stableCollateralDetails = SetTokenLibrary.getSetDetails(
            stableCollateralAddress
        );
        SetTokenLibrary.SetDetails memory riskCollateralDetails = SetTokenLibrary.getSetDetails(
            riskCollateralAddress
        );

         
        uint256 stableCollateralDollarValue = FlexibleTimingManagerLibrary.calculateTokenAllocationAmountUSD(
            STABLE_ASSET_PRICE,
            stableCollateralDetails.naturalUnit,
            stableCollateralDetails.units[0],
            stableAssetDecimals
        );
        uint256 riskCollateralDollarValue = FlexibleTimingManagerLibrary.calculateTokenAllocationAmountUSD(
            _riskAssetPrice,
            riskCollateralDetails.naturalUnit,
            riskCollateralDetails.units[0],
            riskAssetDecimals
        );

         
        if (riskCollateralDollarValue.mul(ALLOCATION_PRICE_RATIO_LIMIT) <= stableCollateralDollarValue ||
            riskCollateralDollarValue >= stableCollateralDollarValue.mul(ALLOCATION_PRICE_RATIO_LIMIT)) {
             
            return determineNewCollateralParameters(
                _riskAssetPrice,
                stableCollateralDollarValue,
                riskCollateralDollarValue,
                stableCollateralDetails,
                riskCollateralDetails
            );
        } else {
            return (stableCollateralDollarValue, riskCollateralDollarValue);
        }
    }

     
    function determineNewCollateralParameters(
        uint256 _riskAssetPrice,
        uint256 _stableCollateralValue,
        uint256 _riskCollateralValue,
        SetTokenLibrary.SetDetails memory _stableCollateralDetails,
        SetTokenLibrary.SetDetails memory _riskCollateralDetails
    )
        internal
        returns (uint256, uint256)
    {
        uint256 stableCollateralDollarValue;
        uint256 riskCollateralDollarValue;

        if (usingRiskCollateral()) {
             
            address[] memory nextSetComponents = new address[](1);
            nextSetComponents[0] = stableAssetAddress;

            (
                uint256[] memory nextSetUnits,
                uint256 nextNaturalUnit
            ) = getNewCollateralSetParameters(
                _riskCollateralValue,
                STABLE_ASSET_PRICE,
                stableAssetDecimals,
                _stableCollateralDetails.naturalUnit
            );

             
            stableCollateralAddress = ICore(coreAddress).createSet(
                setTokenFactory,
                nextSetComponents,
                nextSetUnits,
                nextNaturalUnit,
                bytes32("STBLCollateral"),
                bytes32("STBLMACO"),
                ""
            );
             
            stableCollateralDollarValue = FlexibleTimingManagerLibrary.calculateTokenAllocationAmountUSD(
                STABLE_ASSET_PRICE,
                nextNaturalUnit,
                nextSetUnits[0],
                stableAssetDecimals
            );
            riskCollateralDollarValue = _riskCollateralValue;
        } else {
             
            address[] memory nextSetComponents = new address[](1);
            nextSetComponents[0] = riskAssetAddress;

            (
                uint256[] memory nextSetUnits,
                uint256 nextNaturalUnit
            ) = getNewCollateralSetParameters(
                _stableCollateralValue,
                _riskAssetPrice,
                riskAssetDecimals,
                _riskCollateralDetails.naturalUnit
            );

             
            riskCollateralAddress = ICore(coreAddress).createSet(
                setTokenFactory,
                nextSetComponents,
                nextSetUnits,
                nextNaturalUnit,
                bytes32("RISKCollateral"),
                bytes32("RISKMACO"),
                ""
            );

             
            riskCollateralDollarValue = FlexibleTimingManagerLibrary.calculateTokenAllocationAmountUSD(
                _riskAssetPrice,
                nextNaturalUnit,
                nextSetUnits[0],
                riskAssetDecimals
            );
            stableCollateralDollarValue = _stableCollateralValue;
        }

        return (stableCollateralDollarValue, riskCollateralDollarValue);
    }

     
    function getNewCollateralSetParameters(
        uint256 _currentCollateralUSDValue,
        uint256 _replacementUnderlyingPrice,
        uint256 _replacementUnderlyingDecimals,
        uint256 _replacementCollateralNaturalUnit
    )
        internal
        pure
        returns (uint256[] memory, uint256)
    {
         
         
        uint256[] memory nextSetUnits = new uint256[](1);

        uint256 potentialNextUnit = 0;
        uint256 naturalUnitMultiplier = 1;
        uint256 nextNaturalUnit;

         
         
        while (potentialNextUnit == 0) {
            nextNaturalUnit = _replacementCollateralNaturalUnit.mul(naturalUnitMultiplier);
            potentialNextUnit = calculateNextSetUnits(
                _currentCollateralUSDValue,
                _replacementUnderlyingPrice,
                _replacementUnderlyingDecimals,
                nextNaturalUnit
            );
            naturalUnitMultiplier = naturalUnitMultiplier.mul(10);
        }

        nextSetUnits[0] = potentialNextUnit;
        return (nextSetUnits, nextNaturalUnit);
    }

     
    function calculateNextSetUnits(
        uint256 _currentCollateralUSDValue,
        uint256 _replacementUnderlyingPrice,
        uint256 _replacementUnderlyingDecimals,
        uint256 _replacementCollateralNaturalUnit
    )
        internal
        pure
        returns (uint256)
    {
        return _currentCollateralUSDValue
            .mul(10 ** _replacementUnderlyingDecimals)
            .mul(_replacementCollateralNaturalUnit)
            .div(SET_TOKEN_DECIMALS.mul(_replacementUnderlyingPrice));
    }
}