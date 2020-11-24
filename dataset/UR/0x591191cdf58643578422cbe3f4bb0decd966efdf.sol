 

pragma solidity 0.4.18;


 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


 
contract TokenPool is Ownable {

    using SafeMath for uint256;

     
    struct Pool {
        uint256 availableAmount;
        uint256 lockTimestamp;
    }

     
    MintableToken public token;

     
    mapping (string => Pool) private pools;

    modifier onlyNotZero(uint256 amount) {
        require(amount != 0);
        _;
    }

    modifier onlySufficientAmount(string poolId, uint256 amount) {
        require(amount <= pools[poolId].availableAmount);
        _;
    }

    modifier onlyUnlockedPool(string poolId) {
         
        require(block.timestamp > pools[poolId].lockTimestamp);
         
        _;
    }

    modifier onlyUniquePool(string poolId) {
        require(pools[poolId].availableAmount == 0);
        _;
    }

    modifier onlyValid(address _address) {
        require(_address != address(0));
        _;
    }

    function TokenPool(MintableToken _token)
        public
        onlyValid(_token)
    {
        token = _token;
    }

     
    event PoolRegistered(string poolId, uint256 amount);

     
    event PoolLocked(string poolId, uint256 lockTimestamp);

     
    event PoolTransferred(string poolId, address to, uint256 amount);

     
    function registerPool(string poolId, uint256 availableAmount, uint256 lockTimestamp)
        public
        onlyOwner
        onlyNotZero(availableAmount)
        onlyUniquePool(poolId)
    {
        pools[poolId] = Pool({
            availableAmount: availableAmount,
            lockTimestamp: lockTimestamp
        });

        token.mint(this, availableAmount);

        PoolRegistered(poolId, availableAmount);

        if (lockTimestamp > 0) {
            PoolLocked(poolId, lockTimestamp);
        }
    }

     
    function transfer(string poolId, address to, uint256 amount)
        public
        onlyOwner
        onlyValid(to)
        onlyNotZero(amount)
        onlySufficientAmount(poolId, amount)
        onlyUnlockedPool(poolId)
    {
        pools[poolId].availableAmount = pools[poolId].availableAmount.sub(amount);
        require(token.transfer(to, amount));

        PoolTransferred(poolId, to, amount);
    }

     
    function getAvailableAmount(string poolId)
        public
        view
        returns (uint256)
    {
        return pools[poolId].availableAmount;
    }

     
    function getLockTimestamp(string poolId)
        public
        view
        returns (uint256)
    {
        return pools[poolId].lockTimestamp;
    }
}


 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract MintableToken is ERC20Basic {
    function mint(address to, uint256 amount) public;
}