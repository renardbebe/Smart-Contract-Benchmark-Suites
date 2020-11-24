 

 
pragma solidity 0.5.7;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }
}

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) view public returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) view public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
 
 
 
contract Ownable {
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
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

     
     
     
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0x0), "ZERO_ADDRESS");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Claimable is Ownable {
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
        require(newOwner != address(0x0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }

     
    function claimOwnership()
        public
        onlyPendingOwner
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0x0);
    }
}

 
 
 

 
 

contract NewLRCFoundationIceboxContract is Claimable {
    using SafeMath for uint;

    uint public constant FREEZE_PERIOD = 720 days;  

    address public lrcTokenAddress;

    uint public lrcInitialBalance   = 0;
    uint public lrcWithdrawn         = 0;
    uint public lrcUnlockPerMonth   = 0;
    uint public startTime           = 0;

     

     
    event Started(uint _time);

     
    uint public withdrawId = 0;
    event Withdrawal(uint _withdrawId, uint _lrcAmount);

     
     
    constructor(address _lrcTokenAddress) public {
        require(_lrcTokenAddress != address(0));
        lrcTokenAddress = _lrcTokenAddress;
    }

     

     
    function start(uint _startTime) public onlyOwner {
        require(startTime == 0);

        lrcInitialBalance = Token(lrcTokenAddress).balanceOf(address(this));
        require(lrcInitialBalance > 0);

        lrcUnlockPerMonth = lrcInitialBalance.div(24);  
        startTime = _startTime;

        emit Started(startTime);
    }

    function withdraw() public onlyOwner {
        require(now > startTime + FREEZE_PERIOD);
        Token token = Token(lrcTokenAddress);
        uint balance = token.balanceOf(address(this));
        require(balance > 0);

        uint lrcAmount = calculateLRCUnlockAmount(now, balance);
        if (lrcAmount > 0) {
            lrcWithdrawn += lrcAmount;

            emit Withdrawal(withdrawId++, lrcAmount);
            require(token.transfer(owner, lrcAmount));
        }
    }

     

    function calculateLRCUnlockAmount(uint _now, uint _balance) internal view returns (uint lrcAmount) {
        uint unlockable = (_now - startTime - FREEZE_PERIOD)
            .div(30 days)
            .mul(lrcUnlockPerMonth) - lrcWithdrawn;

        require(unlockable > 0);

        if (unlockable > _balance) return _balance;
        else return unlockable;
    }

}