 

 

 
pragma solidity ^0.5.11;


 
 
 
 
 
contract Ownable
{
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
     
    constructor()
        public
    {
        owner = msg.sender;
    }

     
    modifier onlyOwner()
    {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

     
     
     
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0), "ZERO_ADDRESS");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership()
        public
        onlyOwner
    {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

 

 
pragma solidity ^0.5.11;



 
 
 
 
contract Claimable is Ownable
{
    address public pendingOwner;

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "UNAUTHORIZED");
        _;
    }

     
     
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }

     
    function claimOwnership()
        public
        onlyPendingOwner
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

 

 
pragma solidity ^0.5.11;


 
 
library MathUint
{
    function mul(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a * b;
        require(a == 0 || c / a == b, "MUL_OVERFLOW");
    }

    function sub(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint)
    {
        require(b <= a, "SUB_UNDERFLOW");
        return a - b;
    }

    function add(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }

    function decodeFloat(
        uint f
        )
        internal
        pure
        returns (uint value)
    {
        uint numBitsMantissa = 23;
        uint exponent = f >> numBitsMantissa;
        uint mantissa = f & ((1 << numBitsMantissa) - 1);
        value = mantissa * (10 ** exponent);
    }
}

 

 
pragma solidity ^0.5.11;


 
 
contract IDowntimeCostCalculator
{
     
     
     
     
     
     
     
    function getDowntimeCostLRC(
        uint  totalTimeInMaintenanceSeconds,
        uint  totalDEXLifeTimeSeconds,
        uint  numDowntimeMinutes,
        uint  exchangeStakedLRC,
        uint  durationToPurchaseMinutes
        )
        external
        view
        returns (uint cost);
}

 

 
pragma solidity ^0.5.11;





 
 
contract DowntimeCostCalculator is Claimable, IDowntimeCostCalculator
{
    event PriceUpdated(uint pricePerMinute);

    using MathUint for uint;
    uint public pricePerMinute = 0;

    constructor() public Claimable() { }

    function setPrice(uint _pricePerMinute)
        external
        onlyOwner
    {
        pricePerMinute = _pricePerMinute;
        emit PriceUpdated(_pricePerMinute);
    }

    function getDowntimeCostLRC(
        uint   ,
        uint   ,
        uint   ,
        uint   ,
        uint  durationToPurchaseMinutes
        )
        external
        view
        returns (uint)
    {
        return durationToPurchaseMinutes.mul(pricePerMinute);
    }
}