 

pragma solidity ^0.4.24;
contract EIP20Interface {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract EIP20NonStandardInterface {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
     

     
     
     
     
    function transfer(address _to, uint256 _value) public;

     
     
     
     
     

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public;

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ErrorReporter {

     
    event Failure(uint error, uint info, uint detail);

    enum Error {
        NO_ERROR,
        OPAQUE_ERROR,  
        UNAUTHORIZED,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW,
        DIVISION_BY_ZERO,
        BAD_INPUT,
        TOKEN_INSUFFICIENT_ALLOWANCE,
        TOKEN_INSUFFICIENT_BALANCE,
        TOKEN_TRANSFER_FAILED,
        MARKET_NOT_SUPPORTED,
        SUPPLY_RATE_CALCULATION_FAILED,
        BORROW_RATE_CALCULATION_FAILED,
        TOKEN_INSUFFICIENT_CASH,
        TOKEN_TRANSFER_OUT_FAILED,
        INSUFFICIENT_LIQUIDITY,
        INSUFFICIENT_BALANCE,
        INVALID_COLLATERAL_RATIO,
        MISSING_ASSET_PRICE,
        EQUITY_INSUFFICIENT_BALANCE,
        INVALID_CLOSE_AMOUNT_REQUESTED,
        ASSET_NOT_PRICED,
        INVALID_LIQUIDATION_DISCOUNT,
        INVALID_COMBINED_RISK_PARAMETERS,
        ZERO_ORACLE_ADDRESS,
        CONTRACT_PAUSED
    }

     
    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        BORROW_ACCOUNT_LIQUIDITY_CALCULATION_FAILED,
        BORROW_ACCOUNT_SHORTFALL_PRESENT,
        BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        BORROW_AMOUNT_LIQUIDITY_SHORTFALL,
        BORROW_AMOUNT_VALUE_CALCULATION_FAILED,
        BORROW_CONTRACT_PAUSED,
        BORROW_MARKET_NOT_SUPPORTED,
        BORROW_NEW_BORROW_INDEX_CALCULATION_FAILED,
        BORROW_NEW_BORROW_RATE_CALCULATION_FAILED,
        BORROW_NEW_SUPPLY_INDEX_CALCULATION_FAILED,
        BORROW_NEW_SUPPLY_RATE_CALCULATION_FAILED,
        BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_TOTAL_BORROW_CALCULATION_FAILED,
        BORROW_NEW_TOTAL_CASH_CALCULATION_FAILED,
        BORROW_ORIGINATION_FEE_CALCULATION_FAILED,
        BORROW_TRANSFER_OUT_FAILED,
        EQUITY_WITHDRAWAL_AMOUNT_VALIDATION,
        EQUITY_WITHDRAWAL_CALCULATE_EQUITY,
        EQUITY_WITHDRAWAL_MODEL_OWNER_CHECK,
        EQUITY_WITHDRAWAL_TRANSFER_OUT_FAILED,
        LIQUIDATE_ACCUMULATED_BORROW_BALANCE_CALCULATION_FAILED,
        LIQUIDATE_ACCUMULATED_SUPPLY_BALANCE_CALCULATION_FAILED_BORROWER_COLLATERAL_ASSET,
        LIQUIDATE_ACCUMULATED_SUPPLY_BALANCE_CALCULATION_FAILED_LIQUIDATOR_COLLATERAL_ASSET,
        LIQUIDATE_AMOUNT_SEIZE_CALCULATION_FAILED,
        LIQUIDATE_BORROW_DENOMINATED_COLLATERAL_CALCULATION_FAILED,
        LIQUIDATE_CLOSE_AMOUNT_TOO_HIGH,
        LIQUIDATE_CONTRACT_PAUSED,
        LIQUIDATE_DISCOUNTED_REPAY_TO_EVEN_AMOUNT_CALCULATION_FAILED,
        LIQUIDATE_NEW_BORROW_INDEX_CALCULATION_FAILED_BORROWED_ASSET,
        LIQUIDATE_NEW_BORROW_INDEX_CALCULATION_FAILED_COLLATERAL_ASSET,
        LIQUIDATE_NEW_BORROW_RATE_CALCULATION_FAILED_BORROWED_ASSET,
        LIQUIDATE_NEW_SUPPLY_INDEX_CALCULATION_FAILED_BORROWED_ASSET,
        LIQUIDATE_NEW_SUPPLY_INDEX_CALCULATION_FAILED_COLLATERAL_ASSET,
        LIQUIDATE_NEW_SUPPLY_RATE_CALCULATION_FAILED_BORROWED_ASSET,
        LIQUIDATE_NEW_TOTAL_BORROW_CALCULATION_FAILED_BORROWED_ASSET,
        LIQUIDATE_NEW_TOTAL_CASH_CALCULATION_FAILED_BORROWED_ASSET,
        LIQUIDATE_NEW_TOTAL_SUPPLY_BALANCE_CALCULATION_FAILED_BORROWER_COLLATERAL_ASSET,
        LIQUIDATE_NEW_TOTAL_SUPPLY_BALANCE_CALCULATION_FAILED_LIQUIDATOR_COLLATERAL_ASSET,
        LIQUIDATE_FETCH_ASSET_PRICE_FAILED,
        LIQUIDATE_TRANSFER_IN_FAILED,
        LIQUIDATE_TRANSFER_IN_NOT_POSSIBLE,
        REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_CONTRACT_PAUSED,
        REPAY_BORROW_NEW_BORROW_INDEX_CALCULATION_FAILED,
        REPAY_BORROW_NEW_BORROW_RATE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_SUPPLY_INDEX_CALCULATION_FAILED,
        REPAY_BORROW_NEW_SUPPLY_RATE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BORROW_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_CASH_CALCULATION_FAILED,
        REPAY_BORROW_TRANSFER_IN_FAILED,
        REPAY_BORROW_TRANSFER_IN_NOT_POSSIBLE,
        SET_ASSET_PRICE_CHECK_ORACLE,
        SET_MARKET_INTEREST_RATE_MODEL_OWNER_CHECK,
        SET_ORACLE_OWNER_CHECK,
        SET_ORIGINATION_FEE_OWNER_CHECK,
        SET_PAUSED_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_RISK_PARAMETERS_OWNER_CHECK,
        SET_RISK_PARAMETERS_VALIDATION,
        SUPPLY_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        SUPPLY_CONTRACT_PAUSED,
        SUPPLY_MARKET_NOT_SUPPORTED,
        SUPPLY_NEW_BORROW_INDEX_CALCULATION_FAILED,
        SUPPLY_NEW_BORROW_RATE_CALCULATION_FAILED,
        SUPPLY_NEW_SUPPLY_INDEX_CALCULATION_FAILED,
        SUPPLY_NEW_SUPPLY_RATE_CALCULATION_FAILED,
        SUPPLY_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        SUPPLY_NEW_TOTAL_CASH_CALCULATION_FAILED,
        SUPPLY_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        SUPPLY_TRANSFER_IN_FAILED,
        SUPPLY_TRANSFER_IN_NOT_POSSIBLE,
        SUPPORT_MARKET_FETCH_PRICE_FAILED,
        SUPPORT_MARKET_OWNER_CHECK,
        SUPPORT_MARKET_PRICE_CHECK,
        SUSPEND_MARKET_OWNER_CHECK,
        WITHDRAW_ACCOUNT_LIQUIDITY_CALCULATION_FAILED,
        WITHDRAW_ACCOUNT_SHORTFALL_PRESENT,
        WITHDRAW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        WITHDRAW_AMOUNT_LIQUIDITY_SHORTFALL,
        WITHDRAW_AMOUNT_VALUE_CALCULATION_FAILED,
        WITHDRAW_CAPACITY_CALCULATION_FAILED,
        WITHDRAW_CONTRACT_PAUSED,
        WITHDRAW_NEW_BORROW_INDEX_CALCULATION_FAILED,
        WITHDRAW_NEW_BORROW_RATE_CALCULATION_FAILED,
        WITHDRAW_NEW_SUPPLY_INDEX_CALCULATION_FAILED,
        WITHDRAW_NEW_SUPPLY_RATE_CALCULATION_FAILED,
        WITHDRAW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        WITHDRAW_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        WITHDRAW_TRANSFER_OUT_FAILED,
        WITHDRAW_TRANSFER_OUT_NOT_POSSIBLE
    }


     
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }


     
    function failOpaque(FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(Error.OPAQUE_ERROR), uint(info), opaqueError);

        return uint(Error.OPAQUE_ERROR);
    }

}
contract InterestRateModel {

     
    function getSupplyRate(address asset, uint cash, uint borrows) public view returns (uint, uint);

     
    function getBorrowRate(address asset, uint cash, uint borrows) public view returns (uint, uint);
}
contract PriceOracleInterface {

     
    function assetPrices(address asset) public view returns (uint);
}
contract PriceOracleProxy {
    address public mostRecentCaller;
    uint public mostRecentBlock;
    PriceOracleInterface public realPriceOracle;

    constructor(address realPriceOracle_) public {
        realPriceOracle = PriceOracleInterface(realPriceOracle_);
    }

     
    function assetPrices(address asset) public returns (uint) {
        mostRecentCaller = tx.origin;
        mostRecentBlock = block.number;

        return realPriceOracle.assetPrices(asset);
    }
}
contract SafeToken is ErrorReporter {

     
    function checkTransferIn(address asset, address from, uint amount) internal view returns (Error) {

        EIP20Interface token = EIP20Interface(asset);

        if (token.allowance(from, address(this)) < amount) {
            return Error.TOKEN_INSUFFICIENT_ALLOWANCE;
        }

        if (token.balanceOf(from) < amount) {
            return Error.TOKEN_INSUFFICIENT_BALANCE;
        }

        return Error.NO_ERROR;
    }

     
    function doTransferIn(address asset, address from, uint amount) internal returns (Error) {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(asset);

        bool result;

        token.transferFrom(from, address(this), amount);

        assembly {
            switch returndatasize()
                case 0 {                       
                    result := not(0)           
                }
                case 32 {                      
                    returndatacopy(0, 0, 32)
                    result := mload(0)         
                }
                default {                      
                    revert(0, 0)
                }
        }

        if (!result) {
            return Error.TOKEN_TRANSFER_FAILED;
        }

        return Error.NO_ERROR;
    }

     
    function getCash(address asset) internal view returns (uint) {
        EIP20Interface token = EIP20Interface(asset);

        return token.balanceOf(address(this));
    }

     
    function getBalanceOf(address asset, address from) internal view returns (uint) {
        EIP20Interface token = EIP20Interface(asset);

        return token.balanceOf(from);
    }

     
    function doTransferOut(address asset, address to, uint amount) internal returns (Error) {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(asset);

        bool result;

        token.transfer(to, amount);

        assembly {
            switch returndatasize()
                case 0 {                       
                    result := not(0)           
                }
                case 32 {                      
                    returndatacopy(0, 0, 32)
                    result := mload(0)         
                }
                default {                      
                    revert(0, 0)
                }
        }

        if (!result) {
            return Error.TOKEN_TRANSFER_OUT_FAILED;
        }

        return Error.NO_ERROR;
    }
}
contract CarefulMath is ErrorReporter {

     
    function mul(uint a, uint b) internal pure returns (Error, uint) {
        if (a == 0) {
            return (Error.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (Error.INTEGER_OVERFLOW, 0);
        } else {
            return (Error.NO_ERROR, c);
        }
    }

     
    function div(uint a, uint b) internal pure returns (Error, uint) {
        if (b == 0) {
            return (Error.DIVISION_BY_ZERO, 0);
        }

        return (Error.NO_ERROR, a / b);
    }

     
    function sub(uint a, uint b) internal pure returns (Error, uint) {
        if (b <= a) {
            return (Error.NO_ERROR, a - b);
        } else {
            return (Error.INTEGER_UNDERFLOW, 0);
        }
    }

     
    function add(uint a, uint b) internal pure returns (Error, uint) {
        uint c = a + b;

        if (c >= a) {
            return (Error.NO_ERROR, c);
        } else {
            return (Error.INTEGER_OVERFLOW, 0);
        }
    }

     
    function addThenSub(uint a, uint b, uint c) internal pure returns (Error, uint) {
        (Error err0, uint sum) = add(a, b);

        if (err0 != Error.NO_ERROR) {
            return (err0, 0);
        }

        return sub(sum, c);
    }
}
contract Exponential is ErrorReporter, CarefulMath {

     
     
     
    uint constant expScale = 10**18;

     
    uint constant halfExpScale = expScale/2;

    struct Exp {
        uint mantissa;
    }

    uint constant mantissaOne = 10**18;
    uint constant mantissaOneTenth = 10**17;

     
    function getExp(uint num, uint denom) pure internal returns (Error, Exp memory) {
        (Error err0, uint scaledNumerator) = mul(num, expScale);
        if (err0 != Error.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (Error err1, uint rational) = div(scaledNumerator, denom);
        if (err1 != Error.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (Error.NO_ERROR, Exp({mantissa: rational}));
    }

     
    function addExp(Exp memory a, Exp memory b) pure internal returns (Error, Exp memory) {
        (Error error, uint result) = add(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

     
    function subExp(Exp memory a, Exp memory b) pure internal returns (Error, Exp memory) {
        (Error error, uint result) = sub(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

     
    function mulScalar(Exp memory a, uint scalar) pure internal returns (Error, Exp memory) {
        (Error err0, uint scaledMantissa) = mul(a.mantissa, scalar);
        if (err0 != Error.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (Error.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

     
    function divScalar(Exp memory a, uint scalar) pure internal returns (Error, Exp memory) {
        (Error err0, uint descaledMantissa) = div(a.mantissa, scalar);
        if (err0 != Error.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (Error.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

     
    function divScalarByExp(uint scalar, Exp divisor) pure internal returns (Error, Exp memory) {
         
        (Error err0, uint numerator) = mul(expScale, scalar);
        if (err0 != Error.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

     
    function mulExp(Exp memory a, Exp memory b) pure internal returns (Error, Exp memory) {

        (Error err0, uint doubleScaledProduct) = mul(a.mantissa, b.mantissa);
        if (err0 != Error.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

         
         
         
        (Error err1, uint doubleScaledProductWithHalfScale) = add(halfExpScale, doubleScaledProduct);
        if (err1 != Error.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (Error err2, uint product) = div(doubleScaledProductWithHalfScale, expScale);
         
        assert(err2 == Error.NO_ERROR);

        return (Error.NO_ERROR, Exp({mantissa: product}));
    }

     
    function divExp(Exp memory a, Exp memory b) pure internal returns (Error, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }

     
    function truncate(Exp memory exp) pure internal returns (uint) {
         
        return exp.mantissa / 10**18;
    }

     
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;  
    }

     
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

     
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }
}

contract MoneyMarket is Exponential, SafeToken {

    uint constant initialInterestIndex = 10 ** 18;
    uint constant defaultOriginationFee = 0;  

    uint constant minimumCollateralRatioMantissa = 11 * (10 ** 17);  
    uint constant maximumLiquidationDiscountMantissa = (10 ** 17);  

     
    constructor() public {
        admin = msg.sender;
        collateralRatio = Exp({mantissa: 2 * mantissaOne});
        originationFee = Exp({mantissa: defaultOriginationFee});
        liquidationDiscount = Exp({mantissa: 0});
         
    }

     
    function() payable public {
        revert();
    }

     
    address public pendingAdmin;

     
    address public admin;

     
    address public oracle;

     
    struct Balance {
        uint principal;
        uint interestIndex;
    }

     
    mapping(address => mapping(address => Balance)) public supplyBalances;


     
    mapping(address => mapping(address => Balance)) public borrowBalances;


     
    struct Market {
        bool isSupported;
        uint blockNumber;
        InterestRateModel interestRateModel;

        uint totalSupply;
        uint supplyRateMantissa;
        uint supplyIndex;

        uint totalBorrows;
        uint borrowRateMantissa;
        uint borrowIndex;
    }

     
    mapping(address => Market) public markets;

     
    address[] public collateralMarkets;

     
    Exp public collateralRatio;

     
    Exp public originationFee;

     
    Exp public liquidationDiscount;

     
    bool public paused;


     
    event SupplyReceived(address account, address asset, uint amount, uint startingBalance, uint newBalance);

     
    event SupplyWithdrawn(address account, address asset, uint amount, uint startingBalance, uint newBalance);

     
    event BorrowTaken(address account, address asset, uint amount, uint startingBalance, uint borrowAmountWithFee, uint newBalance);

     
    event BorrowRepaid(address account, address asset, uint amount, uint startingBalance, uint newBalance);

     
    event BorrowLiquidated(address targetAccount,
        address assetBorrow,
        uint borrowBalanceBefore,
        uint borrowBalanceAccumulated,
        uint amountRepaid,
        uint borrowBalanceAfter,
        address liquidator,
        address assetCollateral,
        uint collateralBalanceBefore,
        uint collateralBalanceAccumulated,
        uint amountSeized,
        uint collateralBalanceAfter);

     
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

     
    event NewAdmin(address oldAdmin, address newAdmin);

     
    event NewOracle(address oldOracle, address newOracle);

     
    event SupportedMarket(address asset, address interestRateModel);

     
    event NewRiskParameters(uint oldCollateralRatioMantissa, uint newCollateralRatioMantissa, uint oldLiquidationDiscountMantissa, uint newLiquidationDiscountMantissa);

     
    event NewOriginationFee(uint oldOriginationFeeMantissa, uint newOriginationFeeMantissa);

     
    event SetMarketInterestRateModel(address asset, address interestRateModel);

     
    event EquityWithdrawn(address asset, uint equityAvailableBefore, uint amount, address owner);

     
    event SuspendedMarket(address asset);

     
    event SetPaused(bool newState);

     
    function min(uint a, uint b) pure internal returns (uint) {
        if (a < b) {
            return a;
        } else {
            return b;
        }
    }

     
    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }

     
    function addCollateralMarket(address asset) internal {
        for (uint i = 0; i < collateralMarkets.length; i++) {
            if (collateralMarkets[i] == asset) {
                return;
            }
        }

        collateralMarkets.push(asset);
    }

     
    function getCollateralMarketsLength() public view returns (uint) {
        return collateralMarkets.length;
    }

     
    function calculateInterestIndex(uint startingInterestIndex, uint interestRateMantissa, uint blockStart, uint blockEnd) pure internal returns (Error, uint) {

         
        (Error err0, uint blockDelta) = sub(blockEnd, blockStart);
        if (err0 != Error.NO_ERROR) {
            return (err0, 0);
        }

         
         
        (Error err1, Exp memory blocksTimesRate) = mulScalar(Exp({mantissa: interestRateMantissa}), blockDelta);
        if (err1 != Error.NO_ERROR) {
            return (err1, 0);
        }

         
        (Error err2, Exp memory onePlusBlocksTimesRate) = addExp(blocksTimesRate, Exp({mantissa: mantissaOne}));
        if (err2 != Error.NO_ERROR) {
            return (err2, 0);
        }

         
        (Error err3, Exp memory newInterestIndexExp) = mulScalar(onePlusBlocksTimesRate, startingInterestIndex);
        if (err3 != Error.NO_ERROR) {
            return (err3, 0);
        }

         
         
        return (Error.NO_ERROR, truncate(newInterestIndexExp));
    }

     
    function calculateBalance(uint startingBalance, uint interestIndexStart, uint interestIndexEnd) pure internal returns (Error, uint) {
        if (startingBalance == 0) {
             
             
            return (Error.NO_ERROR, 0);
        }
        (Error err0, uint balanceTimesIndex) = mul(startingBalance, interestIndexEnd);
        if (err0 != Error.NO_ERROR) {
            return (err0, 0);
        }

        return div(balanceTimesIndex, interestIndexStart);
    }

     
    function getPriceForAssetAmount(address asset, uint assetAmount) internal view returns (Error, Exp memory)  {
        (Error err, Exp memory assetPrice) = fetchAssetPrice(asset);
        if (err != Error.NO_ERROR) {
            return (err, Exp({mantissa: 0}));
        }

        if (isZeroExp(assetPrice)) {
            return (Error.MISSING_ASSET_PRICE, Exp({mantissa: 0}));
        }

        return mulScalar(assetPrice, assetAmount);  
    }

     
    function getPriceForAssetAmountMulCollatRatio(address asset, uint assetAmount) internal view returns (Error, Exp memory)  {
        Error err;
        Exp memory assetPrice;
        Exp memory scaledPrice;
        (err, assetPrice) = fetchAssetPrice(asset);
        if (err != Error.NO_ERROR) {
            return (err, Exp({mantissa: 0}));
        }

        if (isZeroExp(assetPrice)) {
            return (Error.MISSING_ASSET_PRICE, Exp({mantissa: 0}));
        }

         
        (err, scaledPrice) = mulExp(collateralRatio, assetPrice);
        if (err != Error.NO_ERROR) {
            return (err, Exp({mantissa: 0}));
        }

         
        return mulScalar(scaledPrice, assetAmount);
    }

     
    function calculateBorrowAmountWithFee(uint borrowAmount) view internal returns (Error, uint) {
         
        if (isZeroExp(originationFee)) {
            return (Error.NO_ERROR, borrowAmount);
        }

        (Error err0, Exp memory originationFeeFactor) = addExp(originationFee, Exp({mantissa: mantissaOne}));
        if (err0 != Error.NO_ERROR) {
            return (err0, 0);
        }

        (Error err1, Exp memory borrowAmountWithFee) = mulScalar(originationFeeFactor, borrowAmount);
        if (err1 != Error.NO_ERROR) {
            return (err1, 0);
        }

        return (Error.NO_ERROR, truncate(borrowAmountWithFee));
    }

     
    function fetchAssetPrice(address asset) internal view returns (Error, Exp memory) {
        if (oracle == address(0)) {
            return (Error.ZERO_ORACLE_ADDRESS, Exp({mantissa: 0}));
        }

        PriceOracleInterface oracleInterface = PriceOracleInterface(oracle);
        uint priceMantissa = oracleInterface.assetPrices(asset);

        return (Error.NO_ERROR, Exp({mantissa: priceMantissa}));
    }

     
    function assetPrices(address asset) public view returns (uint) {
        (Error err, Exp memory result) = fetchAssetPrice(asset);
        if (err != Error.NO_ERROR) {
            return 0;
        }
        return result.mantissa;
    }

     
    function getAssetAmountForValue(address asset, Exp ethValue) internal view returns (Error, uint) {
        Error err;
        Exp memory assetPrice;
        Exp memory assetAmount;

        (err, assetPrice) = fetchAssetPrice(asset);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, assetAmount) = divExp(ethValue, assetPrice);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        return (Error.NO_ERROR, truncate(assetAmount));
    }

     
    function _setPendingAdmin(address newPendingAdmin) public returns (uint) {
         
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_ADMIN_OWNER_CHECK);
        }

         
        address oldPendingAdmin = pendingAdmin;
         
        pendingAdmin = newPendingAdmin;

        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return uint(Error.NO_ERROR);
    }

     
    function _acceptAdmin() public returns (uint) {
         
         
        if (msg.sender != pendingAdmin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
        }

         
        address oldAdmin = admin;
         
        admin = pendingAdmin;
         
        pendingAdmin = 0;

        emit NewAdmin(oldAdmin, msg.sender);

        return uint(Error.NO_ERROR);
    }

     
    function _setOracle(address newOracle) public returns (uint) {
         
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_ORACLE_OWNER_CHECK);
        }

         
         
        PriceOracleInterface oracleInterface = PriceOracleInterface(newOracle);
        oracleInterface.assetPrices(address(0));

        address oldOracle = oracle;

         
        oracle = newOracle;

        emit NewOracle(oldOracle, newOracle);

        return uint(Error.NO_ERROR);
    }

     
    function _setPaused(bool requestedState) public returns (uint) {
         
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PAUSED_OWNER_CHECK);
        }

        paused = requestedState;
        emit SetPaused(requestedState);

        return uint(Error.NO_ERROR);
    }

     
    function getAccountLiquidity(address account) public view returns (int) {
        (Error err, Exp memory accountLiquidity, Exp memory accountShortfall) = calculateAccountLiquidity(account);
        require(err == Error.NO_ERROR);

        if (isZeroExp(accountLiquidity)) {
            return -1 * int(truncate(accountShortfall));
        } else {
            return int(truncate(accountLiquidity));
        }
    }

     
    function getSupplyBalance(address account, address asset) view public returns (uint) {
        Error err;
        uint newSupplyIndex;
        uint userSupplyCurrent;

        Market storage market = markets[asset];
        Balance storage supplyBalance = supplyBalances[account][asset];

         
        (err, newSupplyIndex) = calculateInterestIndex(market.supplyIndex, market.supplyRateMantissa, market.blockNumber, getBlockNumber());
        require(err == Error.NO_ERROR);

         
        (err, userSupplyCurrent) = calculateBalance(supplyBalance.principal, supplyBalance.interestIndex, newSupplyIndex);
        require(err == Error.NO_ERROR);

        return userSupplyCurrent;
    }

     
    function getBorrowBalance(address account, address asset) view public returns (uint) {
        Error err;
        uint newBorrowIndex;
        uint userBorrowCurrent;

        Market storage market = markets[asset];
        Balance storage borrowBalance = borrowBalances[account][asset];

         
        (err, newBorrowIndex) = calculateInterestIndex(market.borrowIndex, market.borrowRateMantissa, market.blockNumber, getBlockNumber());
        require(err == Error.NO_ERROR);

         
        (err, userBorrowCurrent) = calculateBalance(borrowBalance.principal, borrowBalance.interestIndex, newBorrowIndex);
        require(err == Error.NO_ERROR);

        return userBorrowCurrent;
    }


     
    function _supportMarket(address asset, InterestRateModel interestRateModel) public returns (uint) {
         
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SUPPORT_MARKET_OWNER_CHECK);
        }

        (Error err, Exp memory assetPrice) = fetchAssetPrice(asset);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.SUPPORT_MARKET_FETCH_PRICE_FAILED);
        }

        if (isZeroExp(assetPrice)) {
            return fail(Error.ASSET_NOT_PRICED, FailureInfo.SUPPORT_MARKET_PRICE_CHECK);
        }

         
        markets[asset].interestRateModel = interestRateModel;

         
        addCollateralMarket(asset);

         
        markets[asset].isSupported = true;

         
        if (markets[asset].supplyIndex == 0) {
            markets[asset].supplyIndex = initialInterestIndex;
        }

        if (markets[asset].borrowIndex == 0) {
            markets[asset].borrowIndex = initialInterestIndex;
        }

        emit SupportedMarket(asset, interestRateModel);

        return uint(Error.NO_ERROR);
    }

     
    function _suspendMarket(address asset) public returns (uint) {
         
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SUSPEND_MARKET_OWNER_CHECK);
        }

         
         
         
         
        if (!markets[asset].isSupported) {
            return uint(Error.NO_ERROR);
        }

         
        markets[asset].isSupported = false;

        emit SuspendedMarket(asset);

        return uint(Error.NO_ERROR);
    }

     
    function _setRiskParameters(uint collateralRatioMantissa, uint liquidationDiscountMantissa) public returns (uint) {
         
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_RISK_PARAMETERS_OWNER_CHECK);
        }

        Exp memory newCollateralRatio = Exp({mantissa: collateralRatioMantissa});
        Exp memory newLiquidationDiscount = Exp({mantissa: liquidationDiscountMantissa});
        Exp memory minimumCollateralRatio = Exp({mantissa: minimumCollateralRatioMantissa});
        Exp memory maximumLiquidationDiscount = Exp({mantissa: maximumLiquidationDiscountMantissa});

        Error err;
        Exp memory newLiquidationDiscountPlusOne;

         
        if (lessThanExp(newCollateralRatio, minimumCollateralRatio)) {
            return fail(Error.INVALID_COLLATERAL_RATIO, FailureInfo.SET_RISK_PARAMETERS_VALIDATION);
        }

         
         
        if (lessThanExp(maximumLiquidationDiscount, newLiquidationDiscount)) {
            return fail(Error.INVALID_LIQUIDATION_DISCOUNT, FailureInfo.SET_RISK_PARAMETERS_VALIDATION);
        }

         
         
        (err, newLiquidationDiscountPlusOne) = addExp(newLiquidationDiscount, Exp({mantissa: mantissaOne}));
        assert(err == Error.NO_ERROR);  

        if (lessThanOrEqualExp(newCollateralRatio, newLiquidationDiscountPlusOne)) {
            return fail(Error.INVALID_COMBINED_RISK_PARAMETERS, FailureInfo.SET_RISK_PARAMETERS_VALIDATION);
        }

         
        Exp memory oldCollateralRatio = collateralRatio;
        Exp memory oldLiquidationDiscount = liquidationDiscount;

         
        collateralRatio = newCollateralRatio;
        liquidationDiscount = newLiquidationDiscount;

        emit NewRiskParameters(oldCollateralRatio.mantissa, collateralRatioMantissa, oldLiquidationDiscount.mantissa, liquidationDiscountMantissa);

        return uint(Error.NO_ERROR);
    }

     
    function _setOriginationFee(uint originationFeeMantissa) public returns (uint) {
         
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_ORIGINATION_FEE_OWNER_CHECK);
        }

         
        Exp memory oldOriginationFee = originationFee;

        originationFee = Exp({mantissa: originationFeeMantissa});

        emit NewOriginationFee(oldOriginationFee.mantissa, originationFeeMantissa);

        return uint(Error.NO_ERROR);
    }

     
    function _setMarketInterestRateModel(address asset, InterestRateModel interestRateModel) public returns (uint) {
         
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_MARKET_INTEREST_RATE_MODEL_OWNER_CHECK);
        }

         
        markets[asset].interestRateModel = interestRateModel;

        emit SetMarketInterestRateModel(asset, interestRateModel);

        return uint(Error.NO_ERROR);
    }

     
    function _withdrawEquity(address asset, uint amount) public returns (uint) {
         
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.EQUITY_WITHDRAWAL_MODEL_OWNER_CHECK);
        }

         
        uint cash = getCash(asset);
        (Error err0, uint equity) = addThenSub(cash, markets[asset].totalBorrows, markets[asset].totalSupply);
        if (err0 != Error.NO_ERROR) {
            return fail(err0, FailureInfo.EQUITY_WITHDRAWAL_CALCULATE_EQUITY);
        }

        if (amount > equity) {
            return fail(Error.EQUITY_INSUFFICIENT_BALANCE, FailureInfo.EQUITY_WITHDRAWAL_AMOUNT_VALIDATION);
        }

         
         
         

         
        Error err2 = doTransferOut(asset, admin, amount);
        if (err2 != Error.NO_ERROR) {
             
            return fail(err2, FailureInfo.EQUITY_WITHDRAWAL_TRANSFER_OUT_FAILED);
        }

         
        emit EquityWithdrawn(asset, equity, amount, admin);

        return uint(Error.NO_ERROR);  
    }

     
    struct SupplyLocalVars {
        uint startingBalance;
        uint newSupplyIndex;
        uint userSupplyCurrent;
        uint userSupplyUpdated;
        uint newTotalSupply;
        uint currentCash;
        uint updatedCash;
        uint newSupplyRateMantissa;
        uint newBorrowIndex;
        uint newBorrowRateMantissa;
    }


     
    function supply(address asset, uint amount) public returns (uint) {
        if (paused) {
            return fail(Error.CONTRACT_PAUSED, FailureInfo.SUPPLY_CONTRACT_PAUSED);
        }

        Market storage market = markets[asset];
        Balance storage balance = supplyBalances[msg.sender][asset];

        SupplyLocalVars memory localResults;  
        Error err;  
        uint rateCalculationResultCode;  

         
        if (!market.isSupported) {
            return fail(Error.MARKET_NOT_SUPPORTED, FailureInfo.SUPPLY_MARKET_NOT_SUPPORTED);
        }

         
        err = checkTransferIn(asset, msg.sender, amount);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.SUPPLY_TRANSFER_IN_NOT_POSSIBLE);
        }

         
        (err, localResults.newSupplyIndex) = calculateInterestIndex(market.supplyIndex, market.supplyRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.SUPPLY_NEW_SUPPLY_INDEX_CALCULATION_FAILED);
        }

        (err, localResults.userSupplyCurrent) = calculateBalance(balance.principal, balance.interestIndex, localResults.newSupplyIndex);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.SUPPLY_ACCUMULATED_BALANCE_CALCULATION_FAILED);
        }

        (err, localResults.userSupplyUpdated) = add(localResults.userSupplyCurrent, amount);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.SUPPLY_NEW_TOTAL_BALANCE_CALCULATION_FAILED);
        }

         
        (err, localResults.newTotalSupply) = addThenSub(market.totalSupply, localResults.userSupplyUpdated, balance.principal);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.SUPPLY_NEW_TOTAL_SUPPLY_CALCULATION_FAILED);
        }

         
        localResults.currentCash = getCash(asset);

        (err, localResults.updatedCash) = add(localResults.currentCash, amount);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.SUPPLY_NEW_TOTAL_CASH_CALCULATION_FAILED);
        }

         
        (rateCalculationResultCode, localResults.newSupplyRateMantissa) = market.interestRateModel.getSupplyRate(asset, localResults.updatedCash, market.totalBorrows);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.SUPPLY_NEW_SUPPLY_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

         
        (err, localResults.newBorrowIndex) = calculateInterestIndex(market.borrowIndex, market.borrowRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.SUPPLY_NEW_BORROW_INDEX_CALCULATION_FAILED);
        }

        (rateCalculationResultCode, localResults.newBorrowRateMantissa) = market.interestRateModel.getBorrowRate(asset, localResults.updatedCash, market.totalBorrows);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.SUPPLY_NEW_BORROW_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

         
         
         

         
        err = doTransferIn(asset, msg.sender, amount);
        if (err != Error.NO_ERROR) {
             
            return fail(err, FailureInfo.SUPPLY_TRANSFER_IN_FAILED);
        }

         
        market.blockNumber = getBlockNumber();
        market.totalSupply =  localResults.newTotalSupply;
        market.supplyRateMantissa = localResults.newSupplyRateMantissa;
        market.supplyIndex = localResults.newSupplyIndex;
        market.borrowRateMantissa = localResults.newBorrowRateMantissa;
        market.borrowIndex = localResults.newBorrowIndex;

         
        localResults.startingBalance = balance.principal;  
        balance.principal = localResults.userSupplyUpdated;
        balance.interestIndex = localResults.newSupplyIndex;

        emit SupplyReceived(msg.sender, asset, amount, localResults.startingBalance, localResults.userSupplyUpdated);

        return uint(Error.NO_ERROR);  
    }

    struct WithdrawLocalVars {
        uint withdrawAmount;
        uint startingBalance;
        uint newSupplyIndex;
        uint userSupplyCurrent;
        uint userSupplyUpdated;
        uint newTotalSupply;
        uint currentCash;
        uint updatedCash;
        uint newSupplyRateMantissa;
        uint newBorrowIndex;
        uint newBorrowRateMantissa;

        Exp accountLiquidity;
        Exp accountShortfall;
        Exp ethValueOfWithdrawal;
        uint withdrawCapacity;
    }


     
    function withdraw(address asset, uint requestedAmount) public returns (uint) {
        if (paused) {
            return fail(Error.CONTRACT_PAUSED, FailureInfo.WITHDRAW_CONTRACT_PAUSED);
        }

        Market storage market = markets[asset];
        Balance storage supplyBalance = supplyBalances[msg.sender][asset];

        WithdrawLocalVars memory localResults;  
        Error err;  
        uint rateCalculationResultCode;  

         
        (err, localResults.accountLiquidity, localResults.accountShortfall) = calculateAccountLiquidity(msg.sender);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.WITHDRAW_ACCOUNT_LIQUIDITY_CALCULATION_FAILED);
        }

         
        (err, localResults.newSupplyIndex) = calculateInterestIndex(market.supplyIndex, market.supplyRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.WITHDRAW_NEW_SUPPLY_INDEX_CALCULATION_FAILED);
        }

        (err, localResults.userSupplyCurrent) = calculateBalance(supplyBalance.principal, supplyBalance.interestIndex, localResults.newSupplyIndex);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.WITHDRAW_ACCUMULATED_BALANCE_CALCULATION_FAILED);
        }

         
        if (requestedAmount == uint(-1)) {
            (err, localResults.withdrawCapacity) = getAssetAmountForValue(asset, localResults.accountLiquidity);
            if (err != Error.NO_ERROR) {
                return fail(err, FailureInfo.WITHDRAW_CAPACITY_CALCULATION_FAILED);
            }
            localResults.withdrawAmount = min(localResults.withdrawCapacity, localResults.userSupplyCurrent);
        } else {
            localResults.withdrawAmount = requestedAmount;
        }

         

         
         
        localResults.currentCash = getCash(asset);
        (err, localResults.updatedCash) = sub(localResults.currentCash, localResults.withdrawAmount);
        if (err != Error.NO_ERROR) {
            return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.WITHDRAW_TRANSFER_OUT_NOT_POSSIBLE);
        }

         
         
        (err, localResults.userSupplyUpdated) = sub(localResults.userSupplyCurrent, localResults.withdrawAmount);
        if (err != Error.NO_ERROR) {
            return fail(Error.INSUFFICIENT_BALANCE, FailureInfo.WITHDRAW_NEW_TOTAL_BALANCE_CALCULATION_FAILED);
        }

         
        if (!isZeroExp(localResults.accountShortfall)) {
            return fail(Error.INSUFFICIENT_LIQUIDITY, FailureInfo.WITHDRAW_ACCOUNT_SHORTFALL_PRESENT);
        }

         
         
         
        (err, localResults.ethValueOfWithdrawal) = getPriceForAssetAmount(asset, localResults.withdrawAmount);  
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.WITHDRAW_AMOUNT_VALUE_CALCULATION_FAILED);
        }

         
        if (lessThanExp(localResults.accountLiquidity, localResults.ethValueOfWithdrawal) ) {
            return fail(Error.INSUFFICIENT_LIQUIDITY, FailureInfo.WITHDRAW_AMOUNT_LIQUIDITY_SHORTFALL);
        }

         
         
         
        (err, localResults.newTotalSupply) = addThenSub(market.totalSupply, localResults.userSupplyUpdated, supplyBalance.principal);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.WITHDRAW_NEW_TOTAL_SUPPLY_CALCULATION_FAILED);
        }

         
        (rateCalculationResultCode, localResults.newSupplyRateMantissa) = market.interestRateModel.getSupplyRate(asset, localResults.updatedCash, market.totalBorrows);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.WITHDRAW_NEW_SUPPLY_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

         
        (err, localResults.newBorrowIndex) = calculateInterestIndex(market.borrowIndex, market.borrowRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.WITHDRAW_NEW_BORROW_INDEX_CALCULATION_FAILED);
        }

        (rateCalculationResultCode, localResults.newBorrowRateMantissa) = market.interestRateModel.getBorrowRate(asset, localResults.updatedCash, market.totalBorrows);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.WITHDRAW_NEW_BORROW_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

         
         
         

         
        err = doTransferOut(asset, msg.sender, localResults.withdrawAmount);
        if (err != Error.NO_ERROR) {
             
            return fail(err, FailureInfo.WITHDRAW_TRANSFER_OUT_FAILED);
        }

         
        market.blockNumber = getBlockNumber();
        market.totalSupply =  localResults.newTotalSupply;
        market.supplyRateMantissa = localResults.newSupplyRateMantissa;
        market.supplyIndex = localResults.newSupplyIndex;
        market.borrowRateMantissa = localResults.newBorrowRateMantissa;
        market.borrowIndex = localResults.newBorrowIndex;

         
        localResults.startingBalance = supplyBalance.principal;  
        supplyBalance.principal = localResults.userSupplyUpdated;
        supplyBalance.interestIndex = localResults.newSupplyIndex;

        emit SupplyWithdrawn(msg.sender, asset, localResults.withdrawAmount, localResults.startingBalance, localResults.userSupplyUpdated);

        return uint(Error.NO_ERROR);  
    }

    struct AccountValueLocalVars {
        address assetAddress;
        uint collateralMarketsLength;

        uint newSupplyIndex;
        uint userSupplyCurrent;
        Exp supplyTotalValue;
        Exp sumSupplies;

        uint newBorrowIndex;
        uint userBorrowCurrent;
        Exp borrowTotalValue;
        Exp sumBorrows;
    }

     
    function calculateAccountLiquidity(address userAddress) internal view returns (Error, Exp memory, Exp memory) {
        Error err;
        uint sumSupplyValuesMantissa;
        uint sumBorrowValuesMantissa;
        (err, sumSupplyValuesMantissa, sumBorrowValuesMantissa) = calculateAccountValuesInternal(userAddress);
        if (err != Error.NO_ERROR) {
            return(err, Exp({mantissa: 0}), Exp({mantissa: 0}));
        }

        Exp memory result;
        
        Exp memory sumSupplyValuesFinal = Exp({mantissa: sumSupplyValuesMantissa});
        Exp memory sumBorrowValuesFinal;  

        (err, sumBorrowValuesFinal) = mulExp(collateralRatio, Exp({mantissa: sumBorrowValuesMantissa}));
        if (err != Error.NO_ERROR) {
            return (err, Exp({mantissa: 0}), Exp({mantissa: 0}));
        }

         
         
        if (lessThanExp(sumSupplyValuesFinal, sumBorrowValuesFinal)) {
             
            (err, result) = subExp(sumBorrowValuesFinal, sumSupplyValuesFinal);
            assert(err == Error.NO_ERROR);  

            return (Error.NO_ERROR, Exp({mantissa: 0}), result);
        } else {
             
            (err, result) = subExp(sumSupplyValuesFinal, sumBorrowValuesFinal);
            assert(err == Error.NO_ERROR);  

            return (Error.NO_ERROR, result, Exp({mantissa: 0}));
        }
    }

     
    function calculateAccountValuesInternal(address userAddress) internal view returns (Error, uint, uint) {
        
         

        AccountValueLocalVars memory localResults;  
        localResults.sumSupplies = Exp({mantissa: 0});
        localResults.sumBorrows = Exp({mantissa: 0});
        Error err;  
        localResults.collateralMarketsLength = collateralMarkets.length;

        for (uint i = 0; i < localResults.collateralMarketsLength; i++) {
            localResults.assetAddress = collateralMarkets[i];
            Market storage currentMarket = markets[localResults.assetAddress];
            Balance storage supplyBalance = supplyBalances[userAddress][localResults.assetAddress];
            Balance storage borrowBalance = borrowBalances[userAddress][localResults.assetAddress];

            if (supplyBalance.principal > 0) {
                 
                (err, localResults.newSupplyIndex) = calculateInterestIndex(currentMarket.supplyIndex, currentMarket.supplyRateMantissa, currentMarket.blockNumber, getBlockNumber());
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }

                (err, localResults.userSupplyCurrent) = calculateBalance(supplyBalance.principal, supplyBalance.interestIndex, localResults.newSupplyIndex);
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }

                 
                (err, localResults.supplyTotalValue) = getPriceForAssetAmount(localResults.assetAddress, localResults.userSupplyCurrent);  
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }

                 
                (err, localResults.sumSupplies) = addExp(localResults.supplyTotalValue, localResults.sumSupplies);
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }
            }

            if (borrowBalance.principal > 0) {
                 
                (err, localResults.newBorrowIndex) = calculateInterestIndex(currentMarket.borrowIndex, currentMarket.borrowRateMantissa, currentMarket.blockNumber, getBlockNumber());
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }

                (err, localResults.userBorrowCurrent) = calculateBalance(borrowBalance.principal, borrowBalance.interestIndex, localResults.newBorrowIndex);
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }

                 
                (err, localResults.borrowTotalValue) = getPriceForAssetAmount(localResults.assetAddress, localResults.userBorrowCurrent);  
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }

                 
                (err, localResults.sumBorrows) = addExp(localResults.borrowTotalValue, localResults.sumBorrows);
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }
            }
        }
        
        return (Error.NO_ERROR, localResults.sumSupplies.mantissa, localResults.sumBorrows.mantissa);
    }

     
    function calculateAccountValues(address userAddress) public view returns (uint, uint, uint) {
        (Error err, uint supplyValue, uint borrowValue) = calculateAccountValuesInternal(userAddress);
        if (err != Error.NO_ERROR) {

            return (uint(err), 0, 0);
        }

        return (0, supplyValue, borrowValue);
    }

    struct PayBorrowLocalVars {
        uint newBorrowIndex;
        uint userBorrowCurrent;
        uint repayAmount;

        uint userBorrowUpdated;
        uint newTotalBorrows;
        uint currentCash;
        uint updatedCash;

        uint newSupplyIndex;
        uint newSupplyRateMantissa;
        uint newBorrowRateMantissa;

        uint startingBalance;
    }

     
    function repayBorrow(address asset, uint amount) public returns (uint) {
        if (paused) {
            return fail(Error.CONTRACT_PAUSED, FailureInfo.REPAY_BORROW_CONTRACT_PAUSED);
        }
        PayBorrowLocalVars memory localResults;
        Market storage market = markets[asset];
        Balance storage borrowBalance = borrowBalances[msg.sender][asset];
        Error err;
        uint rateCalculationResultCode;

         
        (err, localResults.newBorrowIndex) = calculateInterestIndex(market.borrowIndex, market.borrowRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.REPAY_BORROW_NEW_BORROW_INDEX_CALCULATION_FAILED);
        }

        (err, localResults.userBorrowCurrent) = calculateBalance(borrowBalance.principal, borrowBalance.interestIndex, localResults.newBorrowIndex);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED);
        }

         
         
        if (amount == uint(-1)) {
            localResults.repayAmount = min(getBalanceOf(asset, msg.sender), localResults.userBorrowCurrent);
        } else {
            localResults.repayAmount = amount;
        }

         
         
        (err, localResults.userBorrowUpdated) = sub(localResults.userBorrowCurrent, localResults.repayAmount);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED);
        }

         
         
        err = checkTransferIn(asset, msg.sender, localResults.repayAmount);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.REPAY_BORROW_TRANSFER_IN_NOT_POSSIBLE);
        }

         
         
         
        (err, localResults.newTotalBorrows) = addThenSub(market.totalBorrows, localResults.userBorrowUpdated, borrowBalance.principal);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.REPAY_BORROW_NEW_TOTAL_BORROW_CALCULATION_FAILED);
        }

         
        localResults.currentCash = getCash(asset);

        (err, localResults.updatedCash) = add(localResults.currentCash, localResults.repayAmount);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.REPAY_BORROW_NEW_TOTAL_CASH_CALCULATION_FAILED);
        }

         

         
        (err, localResults.newSupplyIndex) = calculateInterestIndex(market.supplyIndex, market.supplyRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.REPAY_BORROW_NEW_SUPPLY_INDEX_CALCULATION_FAILED);
        }

        (rateCalculationResultCode, localResults.newSupplyRateMantissa) = market.interestRateModel.getSupplyRate(asset, localResults.updatedCash, localResults.newTotalBorrows);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.REPAY_BORROW_NEW_SUPPLY_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

        (rateCalculationResultCode, localResults.newBorrowRateMantissa) = market.interestRateModel.getBorrowRate(asset, localResults.updatedCash, localResults.newTotalBorrows);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.REPAY_BORROW_NEW_BORROW_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

         
         
         

         
        err = doTransferIn(asset, msg.sender, localResults.repayAmount);
        if (err != Error.NO_ERROR) {
             
            return fail(err, FailureInfo.REPAY_BORROW_TRANSFER_IN_FAILED);
        }

         
        market.blockNumber = getBlockNumber();
        market.totalBorrows =  localResults.newTotalBorrows;
        market.supplyRateMantissa = localResults.newSupplyRateMantissa;
        market.supplyIndex = localResults.newSupplyIndex;
        market.borrowRateMantissa = localResults.newBorrowRateMantissa;
        market.borrowIndex = localResults.newBorrowIndex;

         
        localResults.startingBalance = borrowBalance.principal;  
        borrowBalance.principal = localResults.userBorrowUpdated;
        borrowBalance.interestIndex = localResults.newBorrowIndex;

        emit BorrowRepaid(msg.sender, asset, localResults.repayAmount, localResults.startingBalance, localResults.userBorrowUpdated);

        return uint(Error.NO_ERROR);  
    }

    struct BorrowLocalVars {
        uint newBorrowIndex;
        uint userBorrowCurrent;
        uint borrowAmountWithFee;

        uint userBorrowUpdated;
        uint newTotalBorrows;
        uint currentCash;
        uint updatedCash;

        uint newSupplyIndex;
        uint newSupplyRateMantissa;
        uint newBorrowRateMantissa;

        uint startingBalance;

        Exp accountLiquidity;
        Exp accountShortfall;
        Exp ethValueOfBorrowAmountWithFee;
    }

    struct LiquidateLocalVars {
         
        address targetAccount;
        address assetBorrow;
        address liquidator;
        address assetCollateral;

         
        uint newBorrowIndex_UnderwaterAsset;
        uint newSupplyIndex_UnderwaterAsset;
        uint newBorrowIndex_CollateralAsset;
        uint newSupplyIndex_CollateralAsset;

         
        uint currentBorrowBalance_TargetUnderwaterAsset;
         
        uint updatedBorrowBalance_TargetUnderwaterAsset;

        uint newTotalBorrows_ProtocolUnderwaterAsset;

        uint startingBorrowBalance_TargetUnderwaterAsset;
        uint startingSupplyBalance_TargetCollateralAsset;
        uint startingSupplyBalance_LiquidatorCollateralAsset;

        uint currentSupplyBalance_TargetCollateralAsset;
        uint updatedSupplyBalance_TargetCollateralAsset;

         
         
        uint currentSupplyBalance_LiquidatorCollateralAsset;
         
         
        uint updatedSupplyBalance_LiquidatorCollateralAsset;

        uint newTotalSupply_ProtocolCollateralAsset;
        uint currentCash_ProtocolUnderwaterAsset;
        uint updatedCash_ProtocolUnderwaterAsset;

         

        uint newSupplyRateMantissa_ProtocolUnderwaterAsset;
        uint newBorrowRateMantissa_ProtocolUnderwaterAsset;

         
         

        uint discountedRepayToEvenAmount;

         
        uint discountedBorrowDenominatedCollateral;

        uint maxCloseableBorrowAmount_TargetUnderwaterAsset;
        uint closeBorrowAmount_TargetUnderwaterAsset;
        uint seizeSupplyAmount_TargetCollateralAsset;

        Exp collateralPrice;
        Exp underwaterAssetPrice;
    }

     
    function liquidateBorrow(address targetAccount, address assetBorrow, address assetCollateral, uint requestedAmountClose) public returns (uint) {
        if (paused) {
            return fail(Error.CONTRACT_PAUSED, FailureInfo.LIQUIDATE_CONTRACT_PAUSED);
        }
        LiquidateLocalVars memory localResults;
         
         
        localResults.targetAccount = targetAccount;
        localResults.assetBorrow = assetBorrow;
        localResults.liquidator = msg.sender;
        localResults.assetCollateral = assetCollateral;

        Market storage borrowMarket = markets[assetBorrow];
        Market storage collateralMarket = markets[assetCollateral];
        Balance storage borrowBalance_TargeUnderwaterAsset = borrowBalances[targetAccount][assetBorrow];
        Balance storage supplyBalance_TargetCollateralAsset = supplyBalances[targetAccount][assetCollateral];

         
        Balance storage supplyBalance_LiquidatorCollateralAsset = supplyBalances[localResults.liquidator][assetCollateral];

        uint rateCalculationResultCode;  
        Error err;  

        (err, localResults.collateralPrice) = fetchAssetPrice(assetCollateral);
        if(err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_FETCH_ASSET_PRICE_FAILED);
        }

        (err, localResults.underwaterAssetPrice) = fetchAssetPrice(assetBorrow);
         
        assert(err == Error.NO_ERROR);

         
        (err, localResults.newBorrowIndex_UnderwaterAsset) = calculateInterestIndex(borrowMarket.borrowIndex, borrowMarket.borrowRateMantissa, borrowMarket.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_BORROW_INDEX_CALCULATION_FAILED_BORROWED_ASSET);
        }

        (err, localResults.currentBorrowBalance_TargetUnderwaterAsset) = calculateBalance(borrowBalance_TargeUnderwaterAsset.principal, borrowBalance_TargeUnderwaterAsset.interestIndex, localResults.newBorrowIndex_UnderwaterAsset);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_ACCUMULATED_BORROW_BALANCE_CALCULATION_FAILED);
        }

         
        (err, localResults.newSupplyIndex_CollateralAsset) = calculateInterestIndex(collateralMarket.supplyIndex, collateralMarket.supplyRateMantissa, collateralMarket.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_SUPPLY_INDEX_CALCULATION_FAILED_COLLATERAL_ASSET);
        }

        (err, localResults.currentSupplyBalance_TargetCollateralAsset) = calculateBalance(supplyBalance_TargetCollateralAsset.principal, supplyBalance_TargetCollateralAsset.interestIndex, localResults.newSupplyIndex_CollateralAsset);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_ACCUMULATED_SUPPLY_BALANCE_CALCULATION_FAILED_BORROWER_COLLATERAL_ASSET);
        }

         
         
         
        (err, localResults.currentSupplyBalance_LiquidatorCollateralAsset) = calculateBalance(supplyBalance_LiquidatorCollateralAsset.principal, supplyBalance_LiquidatorCollateralAsset.interestIndex, localResults.newSupplyIndex_CollateralAsset);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_ACCUMULATED_SUPPLY_BALANCE_CALCULATION_FAILED_LIQUIDATOR_COLLATERAL_ASSET);
        }

         
         

         
         
        (err, localResults.newTotalSupply_ProtocolCollateralAsset) = addThenSub(collateralMarket.totalSupply, localResults.currentSupplyBalance_TargetCollateralAsset, supplyBalance_TargetCollateralAsset.principal);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_TOTAL_SUPPLY_BALANCE_CALCULATION_FAILED_BORROWER_COLLATERAL_ASSET);
        }

         
         
        (err, localResults.newTotalSupply_ProtocolCollateralAsset) = addThenSub(localResults.newTotalSupply_ProtocolCollateralAsset, localResults.currentSupplyBalance_LiquidatorCollateralAsset, supplyBalance_LiquidatorCollateralAsset.principal);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_TOTAL_SUPPLY_BALANCE_CALCULATION_FAILED_LIQUIDATOR_COLLATERAL_ASSET);
        }

         
         
         
         
         
         
         
         

         
         
        (err, localResults.discountedBorrowDenominatedCollateral) =
        calculateDiscountedBorrowDenominatedCollateral(localResults.underwaterAssetPrice, localResults.collateralPrice, localResults.currentSupplyBalance_TargetCollateralAsset);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_BORROW_DENOMINATED_COLLATERAL_CALCULATION_FAILED);
        }

        if (borrowMarket.isSupported) {
             
            (err, localResults.discountedRepayToEvenAmount) =
            calculateDiscountedRepayToEvenAmount(targetAccount, localResults.underwaterAssetPrice);
            if (err != Error.NO_ERROR) {
                return fail(err, FailureInfo.LIQUIDATE_DISCOUNTED_REPAY_TO_EVEN_AMOUNT_CALCULATION_FAILED);
            }

             
             
            localResults.maxCloseableBorrowAmount_TargetUnderwaterAsset = min(localResults.currentBorrowBalance_TargetUnderwaterAsset, localResults.discountedBorrowDenominatedCollateral);

             
            localResults.maxCloseableBorrowAmount_TargetUnderwaterAsset = min(localResults.maxCloseableBorrowAmount_TargetUnderwaterAsset, localResults.discountedRepayToEvenAmount);
        } else {
             
            localResults.maxCloseableBorrowAmount_TargetUnderwaterAsset = min(localResults.currentBorrowBalance_TargetUnderwaterAsset, localResults.discountedBorrowDenominatedCollateral);
        }

         
        if (requestedAmountClose == uint(-1)) {
            localResults.closeBorrowAmount_TargetUnderwaterAsset = localResults.maxCloseableBorrowAmount_TargetUnderwaterAsset;
        } else {
            localResults.closeBorrowAmount_TargetUnderwaterAsset = requestedAmountClose;
        }

         

         
        if (localResults.closeBorrowAmount_TargetUnderwaterAsset > localResults.maxCloseableBorrowAmount_TargetUnderwaterAsset) {
            return fail(Error.INVALID_CLOSE_AMOUNT_REQUESTED, FailureInfo.LIQUIDATE_CLOSE_AMOUNT_TOO_HIGH);
        }

         
        (err, localResults.seizeSupplyAmount_TargetCollateralAsset) = calculateAmountSeize(localResults.underwaterAssetPrice, localResults.collateralPrice, localResults.closeBorrowAmount_TargetUnderwaterAsset);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_AMOUNT_SEIZE_CALCULATION_FAILED);
        }

         
         
        err = checkTransferIn(assetBorrow, localResults.liquidator, localResults.closeBorrowAmount_TargetUnderwaterAsset);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_TRANSFER_IN_NOT_POSSIBLE);
        }

         
         
         

         
        (err, localResults.updatedBorrowBalance_TargetUnderwaterAsset) = sub(localResults.currentBorrowBalance_TargetUnderwaterAsset, localResults.closeBorrowAmount_TargetUnderwaterAsset);
         
        assert(err == Error.NO_ERROR);

         
         
         
        (err, localResults.newTotalBorrows_ProtocolUnderwaterAsset) = addThenSub(borrowMarket.totalBorrows, localResults.updatedBorrowBalance_TargetUnderwaterAsset, borrowBalance_TargeUnderwaterAsset.principal);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_TOTAL_BORROW_CALCULATION_FAILED_BORROWED_ASSET);
        }

         
        localResults.currentCash_ProtocolUnderwaterAsset = getCash(assetBorrow);
        (err, localResults.updatedCash_ProtocolUnderwaterAsset) = add(localResults.currentCash_ProtocolUnderwaterAsset, localResults.closeBorrowAmount_TargetUnderwaterAsset);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_TOTAL_CASH_CALCULATION_FAILED_BORROWED_ASSET);
        }

         
         

         
        (err, localResults.newSupplyIndex_UnderwaterAsset) = calculateInterestIndex(borrowMarket.supplyIndex, borrowMarket.supplyRateMantissa, borrowMarket.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_SUPPLY_INDEX_CALCULATION_FAILED_BORROWED_ASSET);
        }

        (rateCalculationResultCode, localResults.newSupplyRateMantissa_ProtocolUnderwaterAsset) = borrowMarket.interestRateModel.getSupplyRate(assetBorrow, localResults.updatedCash_ProtocolUnderwaterAsset, localResults.newTotalBorrows_ProtocolUnderwaterAsset);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.LIQUIDATE_NEW_SUPPLY_RATE_CALCULATION_FAILED_BORROWED_ASSET, rateCalculationResultCode);
        }

        (rateCalculationResultCode, localResults.newBorrowRateMantissa_ProtocolUnderwaterAsset) = borrowMarket.interestRateModel.getBorrowRate(assetBorrow, localResults.updatedCash_ProtocolUnderwaterAsset, localResults.newTotalBorrows_ProtocolUnderwaterAsset);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.LIQUIDATE_NEW_BORROW_RATE_CALCULATION_FAILED_BORROWED_ASSET, rateCalculationResultCode);
        }

         
         
         
         
         
        (err, localResults.newBorrowIndex_CollateralAsset) = calculateInterestIndex(collateralMarket.borrowIndex, collateralMarket.borrowRateMantissa, collateralMarket.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_BORROW_INDEX_CALCULATION_FAILED_COLLATERAL_ASSET);
        }

         
        (err, localResults.updatedSupplyBalance_TargetCollateralAsset) = sub(localResults.currentSupplyBalance_TargetCollateralAsset, localResults.seizeSupplyAmount_TargetCollateralAsset);
         
         
         
        assert (err == Error.NO_ERROR);

         
        (err, localResults.updatedSupplyBalance_LiquidatorCollateralAsset) = add(localResults.currentSupplyBalance_LiquidatorCollateralAsset, localResults.seizeSupplyAmount_TargetCollateralAsset);
         
         
        assert (err == Error.NO_ERROR);

         
         
         

         
        err = doTransferIn(assetBorrow, localResults.liquidator, localResults.closeBorrowAmount_TargetUnderwaterAsset);
        if (err != Error.NO_ERROR) {
             
            return fail(err, FailureInfo.LIQUIDATE_TRANSFER_IN_FAILED);
        }

         
        borrowMarket.blockNumber = getBlockNumber();
        borrowMarket.totalBorrows = localResults.newTotalBorrows_ProtocolUnderwaterAsset;
         
        borrowMarket.supplyRateMantissa = localResults.newSupplyRateMantissa_ProtocolUnderwaterAsset;
        borrowMarket.supplyIndex = localResults.newSupplyIndex_UnderwaterAsset;
        borrowMarket.borrowRateMantissa = localResults.newBorrowRateMantissa_ProtocolUnderwaterAsset;
        borrowMarket.borrowIndex = localResults.newBorrowIndex_UnderwaterAsset;

         
         
        collateralMarket.blockNumber = getBlockNumber();
        collateralMarket.totalSupply = localResults.newTotalSupply_ProtocolCollateralAsset;
        collateralMarket.supplyIndex = localResults.newSupplyIndex_CollateralAsset;
        collateralMarket.borrowIndex = localResults.newBorrowIndex_CollateralAsset;

         

        localResults.startingBorrowBalance_TargetUnderwaterAsset = borrowBalance_TargeUnderwaterAsset.principal;  
        borrowBalance_TargeUnderwaterAsset.principal = localResults.updatedBorrowBalance_TargetUnderwaterAsset;
        borrowBalance_TargeUnderwaterAsset.interestIndex = localResults.newBorrowIndex_UnderwaterAsset;

        localResults.startingSupplyBalance_TargetCollateralAsset = supplyBalance_TargetCollateralAsset.principal;  
        supplyBalance_TargetCollateralAsset.principal = localResults.updatedSupplyBalance_TargetCollateralAsset;
        supplyBalance_TargetCollateralAsset.interestIndex = localResults.newSupplyIndex_CollateralAsset;

        localResults.startingSupplyBalance_LiquidatorCollateralAsset = supplyBalance_LiquidatorCollateralAsset.principal;  
        supplyBalance_LiquidatorCollateralAsset.principal = localResults.updatedSupplyBalance_LiquidatorCollateralAsset;
        supplyBalance_LiquidatorCollateralAsset.interestIndex = localResults.newSupplyIndex_CollateralAsset;

        emitLiquidationEvent(localResults);

        return uint(Error.NO_ERROR);  
    }

     
    function emitLiquidationEvent(LiquidateLocalVars memory localResults) internal {
         
         
        emit BorrowLiquidated(localResults.targetAccount,
            localResults.assetBorrow,
            localResults.startingBorrowBalance_TargetUnderwaterAsset,
            localResults.currentBorrowBalance_TargetUnderwaterAsset,
            localResults.closeBorrowAmount_TargetUnderwaterAsset,
            localResults.updatedBorrowBalance_TargetUnderwaterAsset,
            localResults.liquidator,
            localResults.assetCollateral,
            localResults.startingSupplyBalance_TargetCollateralAsset,
            localResults.currentSupplyBalance_TargetCollateralAsset,
            localResults.seizeSupplyAmount_TargetCollateralAsset,
            localResults.updatedSupplyBalance_TargetCollateralAsset);
    }

     
    function calculateDiscountedRepayToEvenAmount(address targetAccount, Exp memory underwaterAssetPrice) internal view returns (Error, uint) {
        Error err;
        Exp memory _accountLiquidity;  
        Exp memory accountShortfall_TargetUser;
        Exp memory collateralRatioMinusLiquidationDiscount;  
        Exp memory discountedCollateralRatioMinusOne;  
        Exp memory discountedPrice_UnderwaterAsset;
        Exp memory rawResult;

         
        (err, _accountLiquidity, accountShortfall_TargetUser) = calculateAccountLiquidity(targetAccount);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, collateralRatioMinusLiquidationDiscount) = subExp(collateralRatio, liquidationDiscount);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, discountedCollateralRatioMinusOne) = subExp(collateralRatioMinusLiquidationDiscount, Exp({mantissa: mantissaOne}));
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, discountedPrice_UnderwaterAsset) = mulExp(underwaterAssetPrice, discountedCollateralRatioMinusOne);
         
         
         
         
        assert(err == Error.NO_ERROR);

        (err, rawResult) = divExp(accountShortfall_TargetUser, discountedPrice_UnderwaterAsset);
         
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        return (Error.NO_ERROR, truncate(rawResult));
    }

     
    function calculateDiscountedBorrowDenominatedCollateral(Exp memory underwaterAssetPrice, Exp memory collateralPrice, uint supplyCurrent_TargetCollateralAsset) view internal returns (Error, uint) {
         
         
        Error err;
        Exp memory onePlusLiquidationDiscount;  
        Exp memory supplyCurrentTimesOracleCollateral;  
        Exp memory onePlusLiquidationDiscountTimesOracleBorrow;  
        Exp memory rawResult;

        (err, onePlusLiquidationDiscount) = addExp(Exp({mantissa: mantissaOne}), liquidationDiscount);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, supplyCurrentTimesOracleCollateral) = mulScalar(collateralPrice, supplyCurrent_TargetCollateralAsset);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, onePlusLiquidationDiscountTimesOracleBorrow) = mulExp(onePlusLiquidationDiscount, underwaterAssetPrice);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, rawResult) = divExp(supplyCurrentTimesOracleCollateral, onePlusLiquidationDiscountTimesOracleBorrow);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        return (Error.NO_ERROR, truncate(rawResult));
    }


     
    function calculateAmountSeize(Exp memory underwaterAssetPrice, Exp memory collateralPrice, uint closeBorrowAmount_TargetUnderwaterAsset) internal view returns (Error, uint) {
         
         

         
        Error err;

         
        Exp memory liquidationMultiplier;

         
        Exp memory priceUnderwaterAssetTimesLiquidationMultiplier;

         
         
         
        Exp memory finalNumerator;

         
        Exp memory rawResult;

        (err, liquidationMultiplier) = addExp(Exp({mantissa: mantissaOne}), liquidationDiscount);
         
        assert(err == Error.NO_ERROR);

        (err, priceUnderwaterAssetTimesLiquidationMultiplier) = mulExp(underwaterAssetPrice, liquidationMultiplier);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, finalNumerator) = mulScalar(priceUnderwaterAssetTimesLiquidationMultiplier, closeBorrowAmount_TargetUnderwaterAsset);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, rawResult) = divExp(finalNumerator, collateralPrice);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        return (Error.NO_ERROR, truncate(rawResult));
    }


     
    function borrow(address asset, uint amount) public returns (uint) {
        if (paused) {
            return fail(Error.CONTRACT_PAUSED, FailureInfo.BORROW_CONTRACT_PAUSED);
        }
        BorrowLocalVars memory localResults;
        Market storage market = markets[asset];
        Balance storage borrowBalance = borrowBalances[msg.sender][asset];

        Error err;
        uint rateCalculationResultCode;

         
        if (!market.isSupported) {
            return fail(Error.MARKET_NOT_SUPPORTED, FailureInfo.BORROW_MARKET_NOT_SUPPORTED);
        }

         
        (err, localResults.newBorrowIndex) = calculateInterestIndex(market.borrowIndex, market.borrowRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_NEW_BORROW_INDEX_CALCULATION_FAILED);
        }

        (err, localResults.userBorrowCurrent) = calculateBalance(borrowBalance.principal, borrowBalance.interestIndex, localResults.newBorrowIndex);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED);  
        }

         
        (err, localResults.borrowAmountWithFee) = calculateBorrowAmountWithFee(amount);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_ORIGINATION_FEE_CALCULATION_FAILED);
        }

         
        (err, localResults.userBorrowUpdated) = add(localResults.userBorrowCurrent, localResults.borrowAmountWithFee);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED);  
        }

         
        (err, localResults.newTotalBorrows) = addThenSub(market.totalBorrows, localResults.userBorrowUpdated, borrowBalance.principal);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_NEW_TOTAL_BORROW_CALCULATION_FAILED);  
        }

         
        (err, localResults.accountLiquidity, localResults.accountShortfall) = calculateAccountLiquidity(msg.sender);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_ACCOUNT_LIQUIDITY_CALCULATION_FAILED);
        }

         
        if (!isZeroExp(localResults.accountShortfall)) {
            return fail(Error.INSUFFICIENT_LIQUIDITY, FailureInfo.BORROW_ACCOUNT_SHORTFALL_PRESENT);
        }

         
         
         
        (err, localResults.ethValueOfBorrowAmountWithFee) = getPriceForAssetAmountMulCollatRatio(asset, localResults.borrowAmountWithFee);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_AMOUNT_VALUE_CALCULATION_FAILED);
        }
        if (lessThanExp(localResults.accountLiquidity, localResults.ethValueOfBorrowAmountWithFee)) {
            return fail(Error.INSUFFICIENT_LIQUIDITY, FailureInfo.BORROW_AMOUNT_LIQUIDITY_SHORTFALL);
        }

         
        localResults.currentCash = getCash(asset);
         
        (err, localResults.updatedCash) = sub(localResults.currentCash, amount);
        if (err != Error.NO_ERROR) {
             
            return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.BORROW_NEW_TOTAL_CASH_CALCULATION_FAILED);
        }

         

         
        (err, localResults.newSupplyIndex) = calculateInterestIndex(market.supplyIndex, market.supplyRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_NEW_SUPPLY_INDEX_CALCULATION_FAILED);
        }

        (rateCalculationResultCode, localResults.newSupplyRateMantissa) = market.interestRateModel.getSupplyRate(asset, localResults.updatedCash, localResults.newTotalBorrows);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.BORROW_NEW_SUPPLY_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

        (rateCalculationResultCode, localResults.newBorrowRateMantissa) = market.interestRateModel.getBorrowRate(asset, localResults.updatedCash, localResults.newTotalBorrows);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.BORROW_NEW_BORROW_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

         
         
         

         
        err = doTransferOut(asset, msg.sender, amount);
        if (err != Error.NO_ERROR) {
             
            return fail(err, FailureInfo.BORROW_TRANSFER_OUT_FAILED);
        }

         
        market.blockNumber = getBlockNumber();
        market.totalBorrows =  localResults.newTotalBorrows;
        market.supplyRateMantissa = localResults.newSupplyRateMantissa;
        market.supplyIndex = localResults.newSupplyIndex;
        market.borrowRateMantissa = localResults.newBorrowRateMantissa;
        market.borrowIndex = localResults.newBorrowIndex;

         
        localResults.startingBalance = borrowBalance.principal;  
        borrowBalance.principal = localResults.userBorrowUpdated;
        borrowBalance.interestIndex = localResults.newBorrowIndex;

        emit BorrowTaken(msg.sender, asset, amount, localResults.startingBalance, localResults.borrowAmountWithFee, localResults.userBorrowUpdated);

        return uint(Error.NO_ERROR);  
    }
}
contract LiquidationChecker {
    MoneyMarket public moneyMarket;
    address public liquidator;
    bool public allowLiquidation;

    constructor(address moneyMarket_, address liquidator_) public {
        moneyMarket = MoneyMarket(moneyMarket_);
        liquidator = liquidator_;
        allowLiquidation = false;
    }

    function isAllowed(address asset, uint newCash) internal returns(bool) {
        return allowLiquidation || !isLiquidate(asset, newCash);
    }

    function isLiquidate(address asset, uint newCash) internal returns(bool) {
        return cashIsUp(asset, newCash) && oracleTouched();
    }

    function cashIsUp(address asset, uint newCash) internal view returns(bool) {
        uint oldCash = EIP20Interface(asset).balanceOf(moneyMarket);

        return newCash >= oldCash;
    }

    function oracleTouched() internal returns(bool) {
        PriceOracleProxy oracle = PriceOracleProxy(moneyMarket.oracle());

        bool sameOrigin = oracle.mostRecentCaller() == tx.origin;
        bool sameBlock = oracle.mostRecentBlock() == block.number;

        return sameOrigin && sameBlock;
    }

    function setAllowLiquidation(bool allowLiquidation_) public {
        require(msg.sender == liquidator, "LIQUIDATION_CHECKER_INVALID_LIQUIDATOR");

        allowLiquidation = allowLiquidation_;
    }
}
contract Liquidator is ErrorReporter, SafeToken {

    MoneyMarket public moneyMarket;

    constructor(address moneyMarket_) public {
        moneyMarket = MoneyMarket(moneyMarket_);
    }

    event BorrowLiquidated(address targetAccount,
        address assetBorrow,
        uint borrowBalanceBefore,
        uint borrowBalanceAccumulated,
        uint amountRepaid,
        uint borrowBalanceAfter,
        address liquidator,
        address assetCollateral,
        uint collateralBalanceBefore,
        uint collateralBalanceAccumulated,
        uint amountSeized,
        uint collateralBalanceAfter);

    function liquidateBorrow(address targetAccount, address assetBorrow, address assetCollateral, uint requestedAmountClose) public returns (uint) {
        require(targetAccount != address(this), "FAILED_LIQUIDATE_LIQUIDATOR");
        require(targetAccount != msg.sender, "FAILED_LIQUIDATE_SELF");
        require(msg.sender != address(this), "FAILED_LIQUIDATE_RECURSIVE");
        require(assetBorrow != assetCollateral, "FAILED_LIQUIDATE_IN_KIND");

        InterestRateModel interestRateModel;
        (,,interestRateModel,,,,,,) = moneyMarket.markets(assetBorrow);

        require(interestRateModel != address(0), "FAILED_LIQUIDATE_NO_INTEREST_RATE_MODEL");
        require(checkTransferIn(assetBorrow, msg.sender, requestedAmountClose) == Error.NO_ERROR, "FAILED_LIQUIDATE_TRANSFER_IN_INVALID");

        require(doTransferIn(assetBorrow, msg.sender, requestedAmountClose) == Error.NO_ERROR, "FAILED_LIQUIDATE_TRANSFER_IN_FAILED");

        tokenAllowAll(assetBorrow, moneyMarket);

        LiquidationChecker(interestRateModel).setAllowLiquidation(true);

        uint result = moneyMarket.liquidateBorrow(targetAccount, assetBorrow, assetCollateral, requestedAmountClose);

        require(moneyMarket.withdraw(assetCollateral, uint(-1)) == uint(Error.NO_ERROR), "FAILED_LIQUIDATE_WITHDRAW_FAILED");

        LiquidationChecker(interestRateModel).setAllowLiquidation(false);

         
        require(moneyMarket.getSupplyBalance(address(this), assetCollateral) == 0, "FAILED_LIQUIDATE_REMAINING_SUPPLY_COLLATERAL");  
        require(moneyMarket.getSupplyBalance(address(this), assetBorrow) == 0, "FAILED_LIQUIDATE_REMAINING_SUPPLY_BORROW");  
        require(moneyMarket.getBorrowBalance(address(this), assetCollateral) == 0, "FAILED_LIQUIDATE_REMAINING_BORROW_COLLATERAL");  
        require(moneyMarket.getBorrowBalance(address(this), assetBorrow) == 0, "FAILED_LIQUIDATE_REMAINING_BORROW_BORROW");  

         
        tokenTransferAll(assetCollateral, msg.sender);
        tokenTransferAll(assetBorrow, msg.sender);

        return uint(result);
    }

    function tokenAllowAll(address asset, address allowee) internal {
        EIP20Interface token = EIP20Interface(asset);

        require(token.approve(allowee, uint(-1)), "FAILED_LIQUIDATE_ASSET_ALLOWANCE_FAILED");
    }

    function tokenTransferAll(address asset, address recipient) internal {
        uint balance = getBalanceOf(asset, address(this));

        require(doTransferOut(asset, recipient, balance) == Error.NO_ERROR, "FAILED_LIQUIDATE_TRANSFER_OUT_FAILED");
    }
}