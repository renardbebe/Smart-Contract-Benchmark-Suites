 

pragma solidity ^0.4.24;

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
   
  function sqrt(uint256 x)
    internal
    pure
    returns (uint256 y)
  {
    uint256 z = ((add(x,1)) / 2);
    y = x;
    while (z < y)
    {
        y = z;
        z = ((add((x / z),z)) / 2);
    }
  }

   
  function sq(uint256 x)
    internal
    pure
    returns (uint256)
  {
    return (mul(x,x));
  }

   
  function pwr(uint256 x, uint256 y)
    internal
    pure
    returns (uint256)
  {
    if (x==0)
        return (0);
    else if (y==0)
        return (1);
    else
    {
        uint256 z = x;
        for (uint256 i=1; i < y; i++)
            z = mul(z,x);
        return (z);
    }
  }
}

 

 
 
 
contract FundCenter {
    using SafeMath for *;

    string constant public name = "FundCenter";
    string constant public symbol = "FundCenter";
    
    event BalanceRecharge(address indexed sender, uint256 amount, uint64 evented_at);  
    event BalanceWithdraw(address indexed sender, uint256 amount, bytes txHash, uint64 evented_at);  

    uint lowestRecharge = 0.1 ether;  
    uint lowestWithdraw = 0.1 ether;  
    bool enable = true;
    address public CEO;
    address public COO;
    address public gameAddress; 

    mapping(address => uint) public recharges;  
    mapping(address => uint) public withdraws;  

    modifier onlyCEO {
        require(CEO == msg.sender, "Only CEO can operate.");
        _;
    }

    modifier onlyCOO {
        require(COO == msg.sender, "Only COO can operate.");
        _;
    }
    
    modifier onlyEnable {
        require(enable == true, "The service is closed.");
        _;
    }

    constructor (address _COO) public {
        CEO = msg.sender;
        COO = _COO;
    }

    function recharge() public payable onlyEnable {
        require(msg.value >= lowestRecharge, "The minimum recharge amount does not meet the requirements.");
        recharges[msg.sender] = recharges[msg.sender].add(msg.value);  
        emit BalanceRecharge(msg.sender, msg.value, uint64(now));
    }
    
    function() public payable onlyEnable {
        require(msg.sender == gameAddress, "only receive eth from game address"); 
    }
    
    function setGameAddress(address _gameAddress) public onlyCOO {
        gameAddress = _gameAddress; 
    }

    function withdrawBalanceFromServer(address _to, uint _amount, bytes _txHash) public onlyCOO onlyEnable {
        require(address(this).balance >= _amount, "Insufficient balance.");
        _to.transfer(_amount);
        withdraws[_to] = withdraws[_to].add(_amount);  
        emit BalanceWithdraw(_to, _amount, _txHash, uint64(now));
    }


    function withdrawBalanceFromAdmin(uint _amount) public onlyCOO {
        require(address(this).balance >= _amount, "Insufficient balance.");
        CEO.transfer(_amount);
    }

    function setLowestClaim(uint _lowestRecharge, uint _lowestWithdraw) public onlyCOO {
        lowestRecharge = _lowestRecharge;
        lowestWithdraw = _lowestWithdraw;
    }

    function setEnable(bool _enable) public onlyCOO {
        enable = _enable;
    }

    function transferCEO(address _CEOAddress) public onlyCEO {
        CEO = _CEOAddress;
    }

    function setCOO(address _COOAddress) public onlyCEO {
        COO = _COOAddress;
    }
}