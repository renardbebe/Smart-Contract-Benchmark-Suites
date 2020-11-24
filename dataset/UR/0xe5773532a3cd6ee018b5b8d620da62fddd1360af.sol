 

 

pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

library Decimal {
    using SafeMath for uint256;

    uint256 constant BASE = 10**18;

    function one()
        internal
        pure
        returns (uint256)
    {
        return BASE;
    }

    function onePlus(
        uint256 d
    )
        internal
        pure
        returns (uint256)
    {
        return d.add(BASE);
    }

    function mulFloor(
        uint256 target,
        uint256 d
    )
        internal
        pure
        returns (uint256)
    {
        return target.mul(d) / BASE;
    }

    function mulCeil(
        uint256 target,
        uint256 d
    )
        internal
        pure
        returns (uint256)
    {
        return target.mul(d).divCeil(BASE);
    }

    function divFloor(
        uint256 target,
        uint256 d
    )
        internal
        pure
        returns (uint256)
    {
        return target.mul(BASE).div(d);
    }

    function divCeil(
        uint256 target,
        uint256 d
    )
        internal
        pure
        returns (uint256)
    {
        return target.mul(BASE).divCeil(d);
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor()
        internal
    {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner()
        public
        view
        returns(address)
    {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "NOT_OWNER");
        _;
    }

     
    function isOwner()
        public
        view
        returns(bool)
    {
        return msg.sender == _owner;
    }

     
    function renounceOwnership()
        public
        onlyOwner
    {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(
        address newOwner
    )
        public
        onlyOwner
    {
        require(newOwner != address(0), "INVALID_OWNER");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {

     
    function mul(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

     
    function div(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

     
    function sub(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function sub(
        int256 a,
        uint256 b
    )
        internal
        pure
        returns (int256)
    {
        require(b <= 2**255-1, "INT256_SUB_ERROR");
        int256 c = a - int256(b);
        require(c <= a, "INT256_SUB_ERROR");
        return c;
    }

     
    function add(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function add(
        int256 a,
        uint256 b
    )
        internal
        pure
        returns (int256)
    {
        require(b <= 2**255 - 1, "INT256_ADD_ERROR");
        int256 c = a + int256(b);
        require(c >= a, "INT256_ADD_ERROR");
        return c;
    }

     
    function mod(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        require(b != 0, "MOD_ERROR");
        return a % b;
    }

     
    function isRoundingError(
        uint256 numerator,
        uint256 denominator,
        uint256 multiple
    )
        internal
        pure
        returns (bool)
    {
         
        return mul(mod(mul(numerator, multiple), denominator), 1000) >= mul(numerator, multiple);
    }

     
    function getPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 multiple
    )
        internal
        pure
        returns (uint256)
    {
        require(!isRoundingError(numerator, denominator, multiple), "ROUNDING_ERROR");
         
        return div(mul(numerator, multiple), denominator);
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
}

contract FeedPriceOracle is Ownable {
    using SafeMath for uint256;

    address[] public assets;
    uint256 public price;
    uint256 public lastBlockNumber;
    uint256 public validBlockNumber;
    uint256 public maxChangeRate;
    uint256 public minPrice;
    uint256 public maxPrice;

    event PriceFeed(
        uint256 price,
        uint256 blockNumber
    );

    constructor (
        address[] memory _assets,
        uint256 _validBlockNumber,
        uint256 _maxChangeRate,
        uint256 _minPrice,
        uint256 _maxPrice
    )
        public
    {
        assets = _assets;

        setParams(
            _validBlockNumber,
            _maxChangeRate,
            _minPrice,
            _maxPrice
        );
    }

    function setParams(
        uint256 _validBlockNumber,
        uint256 _maxChangeRate,
        uint256 _minPrice,
        uint256 _maxPrice
    )
        public
        onlyOwner
    {
        require(_minPrice <= _maxPrice, "MIN_PRICE_MUST_LESS_OR_EQUAL_THAN_MAX_PRICE");
        validBlockNumber = _validBlockNumber;
        maxChangeRate = _maxChangeRate;
        minPrice = _minPrice;
        maxPrice = _maxPrice;
    }

    function feed(
        uint256 newPrice
    )
        external
        onlyOwner
    {
        require(newPrice > 0, "PRICE_MUST_GREATER_THAN_0");
        require(lastBlockNumber < block.number, "BLOCKNUMBER_WRONG");
        require(newPrice <= maxPrice, "PRICE_EXCEED_MAX_LIMIT");
        require(newPrice >= minPrice, "PRICE_EXCEED_MIN_LIMIT");

        if (price > 0) {
            uint256 changeRate = Decimal.divFloor(newPrice, price);
            if (changeRate > Decimal.one()) {
                changeRate = changeRate.sub(Decimal.one());
            } else {
                changeRate = Decimal.one().sub(changeRate);
            }
            require(changeRate <= maxChangeRate, "PRICE_CHANGE_RATE_EXCEED");
        }

        price = newPrice;
        lastBlockNumber = block.number;

        emit PriceFeed(price, lastBlockNumber);
    }

    function isValidAsset(
        address asset
    )
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < assets.length; i++ ) {
            if (assets[i] == asset) {
                return true;
            }
        }
        return false;
    }

    function getPrice(
        address _asset
    )
        external
        view
        returns (uint256)
    {
        require(isValidAsset(_asset), "ASSET_NOT_MATCH");
        require(block.number.sub(lastBlockNumber) <= validBlockNumber, "PRICE_EXPIRED");
        return price;
    }

}