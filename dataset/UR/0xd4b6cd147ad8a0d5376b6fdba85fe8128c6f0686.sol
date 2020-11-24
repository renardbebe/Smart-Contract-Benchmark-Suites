 

 

pragma solidity 0.5.7;
pragma experimental ABIEncoderV2;

 

 
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

 

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

 

 
library Require {

     

    uint256 constant ASCII_ZERO = 48;  
    uint256 constant ASCII_RELATIVE_ZERO = 87;  
    uint256 constant ASCII_LOWER_EX = 120;  
    bytes2 constant COLON = 0x3a20;  
    bytes2 constant COMMA = 0x2c20;  
    bytes2 constant LPAREN = 0x203c;  
    byte constant RPAREN = 0x3e;  
    uint256 constant FOUR_BIT_MASK = 0xf;

     

    function that(
        bool must,
        bytes32 file,
        bytes32 reason
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringify(file),
                        COLON,
                        stringify(reason)
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringify(file),
                        COLON,
                        stringify(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA,
        uint256 payloadB
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringify(file),
                        COLON,
                        stringify(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringify(file),
                        COLON,
                        stringify(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringify(file),
                        COLON,
                        stringify(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringify(file),
                        COLON,
                        stringify(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        COMMA,
                        stringify(payloadC),
                        RPAREN
                    )
                )
            );
        }
    }

     

    function stringify(
        bytes32 input
    )
        private
        pure
        returns (bytes memory)
    {
         
        bytes memory result = abi.encodePacked(input);

         
        for (uint256 i = 32; i > 0; ) {
             
             
            i--;

             
            if (result[i] != 0) {
                uint256 length = i + 1;

                 
                assembly {
                    mstore(result, length)  
                }

                return result;
            }
        }

         
        return new bytes(0);
    }

    function stringify(
        uint256 input
    )
        private
        pure
        returns (bytes memory)
    {
        if (input == 0) {
            return "0";
        }

         
        uint256 j = input;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }

         
        bytes memory bstr = new bytes(length);

         
        j = input;
        for (uint256 i = length; i > 0; ) {
             
             
            i--;

             
            bstr[i] = byte(uint8(ASCII_ZERO + (j % 10)));

             
            j /= 10;
        }

        return bstr;
    }

    function stringify(
        address input
    )
        private
        pure
        returns (bytes memory)
    {
        uint256 z = uint256(input);

         
        bytes memory result = new bytes(42);

         
        result[0] = byte(uint8(ASCII_ZERO));
        result[1] = byte(uint8(ASCII_LOWER_EX));

         
        for (uint256 i = 0; i < 20; i++) {
             
            uint256 shift = i * 2;

             
            result[41 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;

             
            result[40 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function char(
        uint256 input
    )
        private
        pure
        returns (byte)
    {
         
        if (input < 10) {
            return byte(uint8(input + ASCII_ZERO));
        }

         
        return byte(uint8(input + ASCII_RELATIVE_ZERO));
    }
}

 

 
library Math {
    using SafeMath for uint256;

     

    bytes32 constant FILE = "Math";

     

     
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }

     
    function getPartialRoundUp(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (uint256)
    {
        if (target == 0 || numerator == 0) {
             
            return SafeMath.div(0, denominator);
        }
        return target.mul(numerator).sub(1).div(denominator).add(1);
    }

    function to128(
        uint256 number
    )
        internal
        pure
        returns (uint128)
    {
        uint128 result = uint128(number);
        Require.that(
            result == number,
            FILE,
            "Unsafe cast to uint128"
        );
        return result;
    }

    function to96(
        uint256 number
    )
        internal
        pure
        returns (uint96)
    {
        uint96 result = uint96(number);
        Require.that(
            result == number,
            FILE,
            "Unsafe cast to uint96"
        );
        return result;
    }

    function to32(
        uint256 number
    )
        internal
        pure
        returns (uint32)
    {
        uint32 result = uint32(number);
        Require.that(
            result == number,
            FILE,
            "Unsafe cast to uint32"
        );
        return result;
    }

    function min(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a > b ? a : b;
    }
}

 

 
library Types {
    using Math for uint256;

     

    enum AssetDenomination {
        Wei,  
        Par   
    }

    enum AssetReference {
        Delta,  
        Target  
    }

    struct AssetAmount {
        bool sign;  
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

     

     
    struct TotalPar {
        uint128 borrow;
        uint128 supply;
    }

     
    struct Par {
        bool sign;  
        uint128 value;
    }

    function zeroPar()
        internal
        pure
        returns (Par memory)
    {
        return Par({
            sign: false,
            value: 0
        });
    }

    function sub(
        Par memory a,
        Par memory b
    )
        internal
        pure
        returns (Par memory)
    {
        return add(a, negative(b));
    }

    function add(
        Par memory a,
        Par memory b
    )
        internal
        pure
        returns (Par memory)
    {
        Par memory result;
        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = SafeMath.add(a.value, b.value).to128();
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = SafeMath.sub(a.value, b.value).to128();
            } else {
                result.sign = b.sign;
                result.value = SafeMath.sub(b.value, a.value).to128();
            }
        }
        return result;
    }

    function equals(
        Par memory a,
        Par memory b
    )
        internal
        pure
        returns (bool)
    {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(
        Par memory a
    )
        internal
        pure
        returns (Par memory)
    {
        return Par({
            sign: !a.sign,
            value: a.value
        });
    }

    function isNegative(
        Par memory a
    )
        internal
        pure
        returns (bool)
    {
        return !a.sign && a.value > 0;
    }

    function isPositive(
        Par memory a
    )
        internal
        pure
        returns (bool)
    {
        return a.sign && a.value > 0;
    }

    function isZero(
        Par memory a
    )
        internal
        pure
        returns (bool)
    {
        return a.value == 0;
    }

     

     
    struct Wei {
        bool sign;  
        uint256 value;
    }

    function zeroWei()
        internal
        pure
        returns (Wei memory)
    {
        return Wei({
            sign: false,
            value: 0
        });
    }

    function sub(
        Wei memory a,
        Wei memory b
    )
        internal
        pure
        returns (Wei memory)
    {
        return add(a, negative(b));
    }

    function add(
        Wei memory a,
        Wei memory b
    )
        internal
        pure
        returns (Wei memory)
    {
        Wei memory result;
        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = SafeMath.add(a.value, b.value);
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = SafeMath.sub(a.value, b.value);
            } else {
                result.sign = b.sign;
                result.value = SafeMath.sub(b.value, a.value);
            }
        }
        return result;
    }

    function equals(
        Wei memory a,
        Wei memory b
    )
        internal
        pure
        returns (bool)
    {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(
        Wei memory a
    )
        internal
        pure
        returns (Wei memory)
    {
        return Wei({
            sign: !a.sign,
            value: a.value
        });
    }

    function isNegative(
        Wei memory a
    )
        internal
        pure
        returns (bool)
    {
        return !a.sign && a.value > 0;
    }

    function isPositive(
        Wei memory a
    )
        internal
        pure
        returns (bool)
    {
        return a.sign && a.value > 0;
    }

    function isZero(
        Wei memory a
    )
        internal
        pure
        returns (bool)
    {
        return a.value == 0;
    }
}

 

 
library Account {
     

     
    enum Status {
        Normal,
        Liquid,
        Vapor
    }

     

     
    struct Info {
        address owner;   
        uint256 number;  
    }

     
    struct Storage {
        mapping (uint256 => Types.Par) balances;  
        Status status;
    }
}

 

 
library Monetary {

     
    struct Price {
        uint256 value;
    }

     
    struct Value {
        uint256 value;
    }
}

 

 
library Decimal {
    using SafeMath for uint256;

     

    uint256 constant BASE = 10**18;

     

    struct D256 {
        uint256 value;
    }

     

    function one()
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    function onePlus(
        D256 memory d
    )
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: d.value.add(BASE) });
    }

    function mul(
        uint256 target,
        D256 memory d
    )
        internal
        pure
        returns (uint256)
    {
        return Math.getPartial(target, d.value, BASE);
    }

    function div(
        uint256 target,
        D256 memory d
    )
        internal
        pure
        returns (uint256)
    {
        return Math.getPartial(target, BASE, d.value);
    }
}

 

 
library Time {

     

    function currentTime()
        internal
        view
        returns (uint32)
    {
        return Math.to32(block.timestamp);
    }
}

 

 
library Interest {
    using Math for uint256;
    using SafeMath for uint256;

     

    bytes32 constant FILE = "Interest";
    uint64 constant BASE = 10**18;

     

    struct Rate {
        uint256 value;
    }

    struct Index {
        uint96 borrow;
        uint96 supply;
        uint32 lastUpdate;
    }

     

     
    function calculateNewIndex(
        Index memory index,
        Rate memory rate,
        Types.TotalPar memory totalPar,
        Decimal.D256 memory earningsRate
    )
        internal
        view
        returns (Index memory)
    {
        (
            Types.Wei memory supplyWei,
            Types.Wei memory borrowWei
        ) = totalParToWei(totalPar, index);

         
        uint32 currentTime = Time.currentTime();
        uint256 borrowInterest = rate.value.mul(uint256(currentTime).sub(index.lastUpdate));

         
        uint256 supplyInterest;
        if (Types.isZero(supplyWei)) {
            supplyInterest = 0;
        } else {
            supplyInterest = Decimal.mul(borrowInterest, earningsRate);
            if (borrowWei.value < supplyWei.value) {
                supplyInterest = Math.getPartial(supplyInterest, borrowWei.value, supplyWei.value);
            }
        }
        assert(supplyInterest <= borrowInterest);

        return Index({
            borrow: Math.getPartial(index.borrow, borrowInterest, BASE).add(index.borrow).to96(),
            supply: Math.getPartial(index.supply, supplyInterest, BASE).add(index.supply).to96(),
            lastUpdate: currentTime
        });
    }

    function newIndex()
        internal
        view
        returns (Index memory)
    {
        return Index({
            borrow: BASE,
            supply: BASE,
            lastUpdate: Time.currentTime()
        });
    }

     
    function parToWei(
        Types.Par memory input,
        Index memory index
    )
        internal
        pure
        returns (Types.Wei memory)
    {
        uint256 inputValue = uint256(input.value);
        if (input.sign) {
            return Types.Wei({
                sign: true,
                value: inputValue.getPartial(index.supply, BASE)
            });
        } else {
            return Types.Wei({
                sign: false,
                value: inputValue.getPartialRoundUp(index.borrow, BASE)
            });
        }
    }

     
    function weiToPar(
        Types.Wei memory input,
        Index memory index
    )
        internal
        pure
        returns (Types.Par memory)
    {
        if (input.sign) {
            return Types.Par({
                sign: true,
                value: input.value.getPartial(BASE, index.supply).to128()
            });
        } else {
            return Types.Par({
                sign: false,
                value: input.value.getPartialRoundUp(BASE, index.borrow).to128()
            });
        }
    }

     
    function totalParToWei(
        Types.TotalPar memory totalPar,
        Index memory index
    )
        internal
        pure
        returns (Types.Wei memory, Types.Wei memory)
    {
        Types.Par memory supplyPar = Types.Par({
            sign: true,
            value: totalPar.supply
        });
        Types.Par memory borrowPar = Types.Par({
            sign: false,
            value: totalPar.borrow
        });
        Types.Wei memory supplyWei = parToWei(supplyPar, index);
        Types.Wei memory borrowWei = parToWei(borrowPar, index);
        return (supplyWei, borrowWei);
    }
}

 

 
interface IInterestSetter {

     

     
    function getInterestRate(
        address token,
        uint256 borrowWei,
        uint256 supplyWei
    )
        external
        view
        returns (Interest.Rate memory);
}

 

 
contract IPriceOracle {

     

    uint256 public constant ONE_DOLLAR = 10 ** 36;

     

     
    function getPrice(
        address token
    )
        public
        view
        returns (Monetary.Price memory);
}

 

 
library Storage {

     

     
    struct Market {
         
        address token;

         
        Types.TotalPar totalPar;

         
        Interest.Index index;

         
        IPriceOracle priceOracle;

         
        IInterestSetter interestSetter;

         
        Decimal.D256 marginPremium;

         
        Decimal.D256 spreadPremium;

         
        bool isClosing;
    }

     
    struct RiskParams {
         
        Decimal.D256 marginRatio;

         
        Decimal.D256 liquidationSpread;

         
        Decimal.D256 earningsRate;

         
         
        Monetary.Value minBorrowedValue;
    }

     
    struct RiskLimits {
        uint64 marginRatioMax;
        uint64 liquidationSpreadMax;
        uint64 earningsRateMax;
        uint64 marginPremiumMax;
        uint64 spreadPremiumMax;
        uint128 minBorrowedValueMax;
    }

     
    struct State {
         
        uint256 numMarkets;

         
        mapping (uint256 => Market) markets;

         
        mapping (address => mapping (uint256 => Account.Storage)) accounts;

         
        mapping (address => mapping (address => bool)) operators;

         
        mapping (address => bool) globalOperators;

         
        RiskParams riskParams;

         
        RiskLimits riskLimits;
    }
}

 

 
contract State
{
    Storage.State g_state;
}

 

 
contract Getters is
    State
{
     

     
    function getMarginRatio()
        public
        view
        returns (Decimal.D256 memory);

     
    function getLiquidationSpread()
        public
        view
        returns (Decimal.D256 memory);

     
    function getEarningsRate()
        public
        view
        returns (Decimal.D256 memory);

     
    function getMinBorrowedValue()
        public
        view
        returns (Monetary.Value memory);

     
    function getRiskParams()
        public
        view
        returns (Storage.RiskParams memory);

     
    function getRiskLimits()
        public
        view
        returns (Storage.RiskLimits memory);

     

     
    function getNumMarkets()
        public
        view
        returns (uint256);

     
    function getMarketTokenAddress(
        uint256 marketId
    )
        public
        view
        returns (address);

     
    function getMarketTotalPar(
        uint256 marketId
    )
        public
        view
        returns (Types.TotalPar memory);

     
    function getMarketCachedIndex(
        uint256 marketId
    )
        public
        view
        returns (Interest.Index memory);

     
    function getMarketCurrentIndex(
        uint256 marketId
    )
        public
        view
        returns (Interest.Index memory);

     
    function getMarketPriceOracle(
        uint256 marketId
    )
        public
        view
        returns (IPriceOracle);

     
    function getMarketInterestSetter(
        uint256 marketId
    )
        public
        view
        returns (IInterestSetter);

     
    function getMarketMarginPremium(
        uint256 marketId
    )
        public
        view
        returns (Decimal.D256 memory);

     
    function getMarketSpreadPremium(
        uint256 marketId
    )
        public
        view
        returns (Decimal.D256 memory);

     
    function getMarketIsClosing(
        uint256 marketId
    )
        public
        view
        returns (bool);

     
    function getMarketPrice(
        uint256 marketId
    )
        public
        view
        returns (Monetary.Price memory);

     
    function getMarketInterestRate(
        uint256 marketId
    )
        public
        view
        returns (Interest.Rate memory);

     
    function getLiquidationSpreadForPair(
        uint256 heldMarketId,
        uint256 owedMarketId
    )
        public
        view
        returns (Decimal.D256 memory);

     
    function getMarket(
        uint256 marketId
    )
        public
        view
        returns (Storage.Market memory);

     
    function getMarketWithInfo(
        uint256 marketId
    )
        public
        view
        returns (
            Storage.Market memory,
            Interest.Index memory,
            Monetary.Price memory,
            Interest.Rate memory
        );

     
    function getNumExcessTokens(
        uint256 marketId
    )
        public
        view
        returns (Types.Wei memory);

     

     
    function getAccountPar(
        Account.Info memory account,
        uint256 marketId
    )
        public
        view
        returns (Types.Par memory);

     
    function getAccountWei(
        Account.Info memory account,
        uint256 marketId
    )
        public
        view
        returns (Types.Wei memory);

     
    function getAccountStatus(
        Account.Info memory account
    )
        public
        view
        returns (Account.Status);

     
    function getAccountValues(
        Account.Info memory account
    )
        public
        view
        returns (Monetary.Value memory, Monetary.Value memory);

     
    function getAdjustedAccountValues(
        Account.Info memory account
    )
        public
        view
        returns (Monetary.Value memory, Monetary.Value memory);

     
    function getAccountBalances(
        Account.Info memory account
    )
        public
        view
        returns (
            address[] memory,
            Types.Par[] memory,
            Types.Wei[] memory
        );

     

     
    function getIsLocalOperator(
        address owner,
        address operator
    )
        public
        view
        returns (bool);

     
    function getIsGlobalOperator(
        address operator
    )
        public
        view
        returns (bool);
}

 

 
library Actions {

     

    enum ActionType {
        Deposit,    
        Withdraw,   
        Transfer,   
        Buy,        
        Sell,       
        Trade,      
        Liquidate,  
        Vaporize,   
        Call        
    }

     

     
    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        Types.AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }
}

 

 
contract Operation is
    State,
    ReentrancyGuard
{
     

     
    function operate(
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    )
        public;
}

 

 
contract SoloMargin is
    State,
    Getters,
    Operation
{
}

 

 
contract OnlySolo {

     

    bytes32 constant FILE = "OnlySolo";

     

    SoloMargin public SOLO_MARGIN;

     

    constructor (
        address soloMargin
    )
        public
    {
        SOLO_MARGIN = SoloMargin(soloMargin);
    }

     

    modifier onlySolo(address from) {
        Require.that(
            from == address(SOLO_MARGIN),
            FILE,
            "Only Solo can call function",
            from
        );
        _;
    }
}

 

 
contract LiquidatorProxyV1ForSoloMargin is
    OnlySolo,
    ReentrancyGuard
{
    using Math for uint256;
    using SafeMath for uint256;
    using Types for Types.Par;
    using Types for Types.Wei;

     

    bytes32 constant FILE = "LiquidatorProxyV1ForSoloMargin";

     

    struct Constants {
        Account.Info fromAccount;
        Account.Info liquidAccount;
        Decimal.D256 minLiquidatorRatio;
        MarketInfo[] markets;
    }

    struct MarketInfo {
        Monetary.Price price;
        Interest.Index index;
    }

    struct Cache {
         
        uint256 toLiquidate;
        Types.Wei heldWei;
        Types.Wei owedWei;
        uint256 supplyValue;
        uint256 borrowValue;

         
        Decimal.D256 spread;
        uint256 heldMarket;
        uint256 owedMarket;
        uint256 heldPrice;
        uint256 owedPrice;
        uint256 owedPriceAdj;
    }

     

    constructor (
        address soloMargin
    )
        public
        OnlySolo(soloMargin)
    {}  

     

     
    function liquidate(
        Account.Info memory fromAccount,
        Account.Info memory liquidAccount,
        Decimal.D256 memory minLiquidatorRatio,
        uint256 minValueLiquidated,
        uint256[] memory owedPreferences,
        uint256[] memory heldPreferences
    )
        public
        nonReentrant
    {
         
        Constants memory constants = Constants({
            fromAccount: fromAccount,
            liquidAccount: liquidAccount,
            minLiquidatorRatio: minLiquidatorRatio,
            markets: getMarketsInfo()
        });

         
        checkRequirements(constants);

         
        uint256 totalValueLiquidated = 0;

         
        for (uint256 owedIndex = 0; owedIndex < owedPreferences.length; owedIndex++) {
            uint256 owedMarket = owedPreferences[owedIndex];

             
            for (uint256 heldIndex = 0; heldIndex < heldPreferences.length; heldIndex++) {
                uint256 heldMarket = heldPreferences[heldIndex];

                 
                if (heldMarket == owedMarket) {
                    continue;
                }

                 
                if (!SOLO_MARGIN.getAccountPar(liquidAccount, owedMarket).isNegative()) {
                    break;
                }

                 
                if (!SOLO_MARGIN.getAccountPar(liquidAccount, heldMarket).isPositive()) {
                    continue;
                }

                 
                Cache memory cache = initializeCache(
                    constants,
                    heldMarket,
                    owedMarket
                );

                 
                calculateSafeLiquidationAmount(cache);

                 
                calculateMaxLiquidationAmount(constants, cache);

                 
                if (cache.toLiquidate == 0) {
                    continue;
                }

                 
                SOLO_MARGIN.operate(
                    constructAccountsArray(constants),
                    constructActionsArray(cache)
                );

                 
                totalValueLiquidated =
                    totalValueLiquidated.add(cache.toLiquidate.mul(cache.owedPrice));
            }
        }

         
        Require.that(
            totalValueLiquidated >= minValueLiquidated,
            FILE,
            "Not enough liquidatable value",
            totalValueLiquidated,
            minValueLiquidated
        );
    }

     

     
    function calculateSafeLiquidationAmount(
        Cache memory cache
    )
        private
        pure
    {
        bool negOwed = !cache.owedWei.isPositive();
        bool posHeld = !cache.heldWei.isNegative();

         
        if (negOwed && posHeld) {
            return;
        }

         
         
        bool owedGoesToZeroLast;
        if (negOwed) {
            owedGoesToZeroLast = false;
        } else if (posHeld) {
            owedGoesToZeroLast = true;
        } else {
             
            owedGoesToZeroLast =
                cache.owedWei.value.mul(cache.owedPriceAdj) >
                cache.heldWei.value.mul(cache.heldPrice);
        }

        if (owedGoesToZeroLast) {
             
            Types.Wei memory heldWeiDelta = Types.Wei({
                sign: cache.owedWei.sign,
                value: cache.owedWei.value.getPartial(cache.owedPriceAdj, cache.heldPrice)
            });
            setCacheWeiValues(
                cache,
                cache.heldWei.add(heldWeiDelta),
                Types.zeroWei()
            );
        } else {
             
            Types.Wei memory owedWeiDelta = Types.Wei({
                sign: cache.heldWei.sign,
                value: cache.heldWei.value.getPartial(cache.heldPrice, cache.owedPriceAdj)
            });
            setCacheWeiValues(
                cache,
                Types.zeroWei(),
                cache.owedWei.add(owedWeiDelta)
            );
        }
    }

     
    function calculateMaxLiquidationAmount(
        Constants memory constants,
        Cache memory cache
    )
        private
        pure
    {
        assert(!cache.heldWei.isNegative());
        assert(!cache.owedWei.isPositive());

         
        bool liquidatorAboveCollateralization = isCollateralized(
            cache.supplyValue,
            cache.borrowValue,
            constants.minLiquidatorRatio
        );
        if (!liquidatorAboveCollateralization) {
            cache.toLiquidate = 0;
            return;
        }

         
        uint256 requiredOverhead = Decimal.mul(cache.borrowValue, constants.minLiquidatorRatio);
        uint256 requiredSupplyValue = cache.borrowValue.add(requiredOverhead);
        uint256 remainingValueBuffer = cache.supplyValue.sub(requiredSupplyValue);

         
        Decimal.D256 memory spreadMarginDiff = Decimal.D256({
            value: constants.minLiquidatorRatio.value.sub(cache.spread.value)
        });

         
        uint256 owedValueToTakeOn = Decimal.div(remainingValueBuffer, spreadMarginDiff);

         
        uint256 owedWeiToLiquidate = owedValueToTakeOn.div(cache.owedPrice);

         
        cache.toLiquidate = cache.toLiquidate.add(owedWeiToLiquidate);
    }

     

     
    function checkRequirements(
        Constants memory constants
    )
        private
        view
    {
         
        Require.that(
            constants.fromAccount.owner == msg.sender
            || SOLO_MARGIN.getIsLocalOperator(constants.fromAccount.owner, msg.sender),
            FILE,
            "Sender not operator",
            constants.fromAccount.owner
        );

         
        (
            Monetary.Value memory liquidSupplyValue,
            Monetary.Value memory liquidBorrowValue
        ) = getCurrentAccountValues(constants, constants.liquidAccount);
        Require.that(
            liquidSupplyValue.value != 0,
            FILE,
            "Liquid account no supply"
        );
        Require.that(
            SOLO_MARGIN.getAccountStatus(constants.liquidAccount) == Account.Status.Liquid
            || !isCollateralized(
                liquidSupplyValue.value,
                liquidBorrowValue.value,
                SOLO_MARGIN.getMarginRatio()
            ),
            FILE,
            "Liquid account not liquidatable",
            liquidSupplyValue.value,
            liquidBorrowValue.value
        );
    }

     
    function setCacheWeiValues(
        Cache memory cache,
        Types.Wei memory newHeldWei,
        Types.Wei memory newOwedWei
    )
        private
        pure
    {
         
        uint256 oldHeldValue = cache.heldWei.value.mul(cache.heldPrice);
        if (cache.heldWei.sign) {
            cache.supplyValue = cache.supplyValue.sub(oldHeldValue);
        } else {
            cache.borrowValue = cache.borrowValue.sub(oldHeldValue);
        }

         
        uint256 newHeldValue = newHeldWei.value.mul(cache.heldPrice);
        if (newHeldWei.sign) {
            cache.supplyValue = cache.supplyValue.add(newHeldValue);
        } else {
            cache.borrowValue = cache.borrowValue.add(newHeldValue);
        }

         
        uint256 oldOwedValue = cache.owedWei.value.mul(cache.owedPrice);
        if (cache.owedWei.sign) {
            cache.supplyValue = cache.supplyValue.sub(oldOwedValue);
        } else {
            cache.borrowValue = cache.borrowValue.sub(oldOwedValue);
        }

         
        uint256 newOwedValue = newOwedWei.value.mul(cache.owedPrice);
        if (newOwedWei.sign) {
            cache.supplyValue = cache.supplyValue.add(newOwedValue);
        } else {
            cache.borrowValue = cache.borrowValue.add(newOwedValue);
        }

         
        Types.Wei memory delta = cache.owedWei.sub(newOwedWei);
        assert(!delta.isNegative());
        cache.toLiquidate = cache.toLiquidate.add(delta.value);
        cache.heldWei = newHeldWei;
        cache.owedWei = newOwedWei;
    }

     
    function isCollateralized(
        uint256 supplyValue,
        uint256 borrowValue,
        Decimal.D256 memory ratio
    )
        private
        pure
        returns(bool)
    {
        uint256 requiredMargin = Decimal.mul(borrowValue, ratio);
        return supplyValue >= borrowValue.add(requiredMargin);
    }

     

     
    function getCurrentAccountValues(
        Constants memory constants,
        Account.Info memory account
    )
        private
        view
        returns (
            Monetary.Value memory,
            Monetary.Value memory
        )
    {
        Monetary.Value memory supplyValue;
        Monetary.Value memory borrowValue;

        for (uint256 m = 0; m < constants.markets.length; m++) {
            Types.Par memory par = SOLO_MARGIN.getAccountPar(account, m);
            if (par.isZero()) {
                continue;
            }
            Types.Wei memory userWei = Interest.parToWei(par, constants.markets[m].index);
            uint256 assetValue = userWei.value.mul(constants.markets[m].price.value);
            if (userWei.sign) {
                supplyValue.value = supplyValue.value.add(assetValue);
            } else {
                borrowValue.value = borrowValue.value.add(assetValue);
            }
        }

        return (supplyValue, borrowValue);
    }

     
    function getMarketsInfo()
        private
        view
        returns (MarketInfo[] memory)
    {
        uint256 numMarkets = SOLO_MARGIN.getNumMarkets();
        MarketInfo[] memory markets = new MarketInfo[](numMarkets);
        for (uint256 m = 0; m < numMarkets; m++) {
            markets[m] = MarketInfo({
                price: SOLO_MARGIN.getMarketPrice(m),
                index: SOLO_MARGIN.getMarketCurrentIndex(m)
            });
        }
        return markets;
    }

     
    function initializeCache(
        Constants memory constants,
        uint256 heldMarket,
        uint256 owedMarket
    )
        private
        view
        returns (Cache memory)
    {
        (
            Monetary.Value memory supplyValue,
            Monetary.Value memory borrowValue
        ) = getCurrentAccountValues(constants, constants.fromAccount);

        uint256 heldPrice = constants.markets[heldMarket].price.value;
        uint256 owedPrice = constants.markets[owedMarket].price.value;
        Decimal.D256 memory spread =
            SOLO_MARGIN.getLiquidationSpreadForPair(heldMarket, owedMarket);

        return Cache({
            heldWei: Interest.parToWei(
                SOLO_MARGIN.getAccountPar(constants.fromAccount, heldMarket),
                constants.markets[heldMarket].index
            ),
            owedWei: Interest.parToWei(
                SOLO_MARGIN.getAccountPar(constants.fromAccount, owedMarket),
                constants.markets[owedMarket].index
            ),
            toLiquidate: 0,
            supplyValue: supplyValue.value,
            borrowValue: borrowValue.value,
            heldMarket: heldMarket,
            owedMarket: owedMarket,
            spread: spread,
            heldPrice: heldPrice,
            owedPrice: owedPrice,
            owedPriceAdj: Decimal.mul(owedPrice, Decimal.onePlus(spread))
        });
    }

     

    function constructAccountsArray(
        Constants memory constants
    )
        private
        pure
        returns (Account.Info[] memory)
    {
        Account.Info[] memory accounts = new Account.Info[](2);
        accounts[0] = constants.fromAccount;
        accounts[1] = constants.liquidAccount;
        return accounts;
    }

    function constructActionsArray(
        Cache memory cache
    )
        private
        pure
        returns (Actions.ActionArgs[] memory)
    {
        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](1);
        actions[0] = Actions.ActionArgs({
            actionType: Actions.ActionType.Liquidate,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: true,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: cache.toLiquidate
            }),
            primaryMarketId: cache.owedMarket,
            secondaryMarketId: cache.heldMarket,
            otherAddress: address(0),
            otherAccountId: 1,
            data: new bytes(0)
        });
        return actions;
    }
}