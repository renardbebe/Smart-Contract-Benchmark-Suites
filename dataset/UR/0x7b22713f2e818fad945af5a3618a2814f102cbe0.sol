 

 
pragma solidity ^0.4.11;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }
}

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
 
 

 
 

contract LRCFoundationIceboxContract {
    using SafeMath for uint;
    
    uint public constant FREEZE_PERIOD = 720 days;  

    address public lrcTokenAddress  = 0x0;
    address public owner            = 0x0;

    uint public lrcInitialBalance   = 0;
    uint public lrcWithdrawn         = 0;
    uint public lrcUnlockPerMonth   = 0;
    uint public startTime           = 0;

     

     
    event Started(uint _time);

     
    uint public withdrawId = 0;
    event Withdrawal(uint _withdrawId, uint _lrcAmount);

     
     
     
    function LRCFoundationIceboxContract(address _lrcTokenAddress, address _owner) {
        require(_lrcTokenAddress != address(0));
        require(_owner != address(0));

        lrcTokenAddress = _lrcTokenAddress;
        owner = _owner;
    }

     

     
    function start() public {
        require(msg.sender == owner);
        require(startTime == 0);

        lrcInitialBalance = Token(lrcTokenAddress).balanceOf(address(this));
        require(lrcInitialBalance > 0);

        lrcUnlockPerMonth = lrcInitialBalance.div(24);  
        startTime = now;

        Started(startTime);
    }


    function () payable {
        require(msg.sender == owner);
        require(msg.value == 0);
        require(startTime > 0);
        require(now > startTime + FREEZE_PERIOD);

        var token = Token(lrcTokenAddress);
        uint balance = token.balanceOf(address(this));
        require(balance > 0);

        uint lrcAmount = calculateLRCUnlockAmount(now, balance);
        if (lrcAmount > 0) {
            lrcWithdrawn += lrcAmount;

            Withdrawal(withdrawId++, lrcAmount);
            require(token.transfer(owner, lrcAmount));
        }
    }


     

    function calculateLRCUnlockAmount(uint _now, uint _balance) internal returns (uint lrcAmount) {
        uint unlockable = (_now - startTime - FREEZE_PERIOD)
            .div(30 days)
            .mul(lrcUnlockPerMonth) - lrcWithdrawn;

        require(unlockable > 0);

        if (unlockable > _balance) return _balance;
        else return unlockable;
    }

}