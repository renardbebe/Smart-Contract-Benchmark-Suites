 

pragma solidity ^0.4.18;

 
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

contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);

  function name() constant returns (string _name);
  function symbol() constant returns (string _symbol);
  function decimals() constant returns (uint8 _decimals);
  function totalSupply() constant returns (uint256 _supply);

  function transfer(address to, uint value) returns (bool ok);
  function transfer(address to, uint value, bytes data) returns (bool ok);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event ERC223Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
}

contract ContractReceiver {
  function tokenFallback(address _from, uint _value, bytes _data);
}

contract ERC223Token is ERC223 {
  using SafeMath for uint;

  mapping(address => uint) balances;

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;


   
  function name() constant returns (string _name) {
      return name;
  }
   
  function symbol() constant returns (string _symbol) {
      return symbol;
  }
   
  function decimals() constant returns (uint8 _decimals) {
      return decimals;
  }
   
  function totalSupply() constant returns (uint256 _totalSupply) {
      return totalSupply;
  }

   
  function transfer(address _to, uint _value, bytes _data) returns (bool success) {
    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}

   
   
  function transfer(address _to, uint _value) returns (bool success) {

     
     
    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
}

 
  function isContract(address _addr) private returns (bool is_contract) {
      uint length;
      assembly {
             
            length := extcodesize(_addr)
        }
        if(length>0) {
            return true;
        }
        else {
            return false;
        }
    }

   
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    Transfer(msg.sender, _to, _value);
    ERC223Transfer(msg.sender, _to, _value, _data);
    return true;
  }

   
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    ContractReceiver reciever = ContractReceiver(_to);
    reciever.tokenFallback(msg.sender, _value, _data);
    Transfer(msg.sender, _to, _value);
    ERC223Transfer(msg.sender, _to, _value, _data);
    return true;
  }


  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
}

contract CoVEXTokenERC223 is ERC223Token{
    using SafeMath for uint256;

    string public name = "CoVEX Coin";
    string public symbol = "CoVEX";
    uint256 public decimals = 18;

     
    uint256 public totalSupply = 250*1000000 * (uint256(10) ** decimals);
    uint256 public totalRaised;  

    uint256 public startTimestamp;  
    uint256 public durationSeconds;  

    uint256 public maxCap;

    uint256 coinsPerETH;

    mapping(address => uint) etherBalance;

    mapping(uint => uint) public weeklyRewards;

    uint256 minPerUser = 0.1 ether;
    uint256 maxPerUser = 100 ether;

     
    address public fundsWallet;

    function CoVEXTokenERC223() {
        fundsWallet = msg.sender;
        
        startTimestamp = now;
        durationSeconds = 0;  

         
        balances[fundsWallet] = totalSupply;

        Transfer(0x0, fundsWallet, totalSupply);
    }

    function() isIcoOpen checkMinMax payable{
        totalRaised = totalRaised.add(msg.value);

        uint256 tokenAmount = calculateTokenAmount(msg.value);
        balances[fundsWallet] = balances[fundsWallet].sub(tokenAmount);
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);

        etherBalance[msg.sender] = etherBalance[msg.sender].add(msg.value);

        Transfer(fundsWallet, msg.sender, tokenAmount);

         
        fundsWallet.transfer(msg.value);
    }

    function calculateTokenAmount(uint256 weiAmount) constant returns(uint256) {
        uint256 tokenAmount = weiAmount.mul(coinsPerETH);
         
        for (uint i = 1; i <= 4; i++) {
            if (now <= startTimestamp + (i * 7 days)) {
                return tokenAmount.mul(100+weeklyRewards[i]).div(100);    
            }
        }
        return tokenAmount;
    }

     
    function adminBurn(uint256 _value) public {
      require(_value <= balances[msg.sender]);
       
       
      address burner = msg.sender;
      balances[burner] = balances[burner].sub(_value);
      totalSupply = totalSupply.sub(_value);
      Transfer(burner, address(0), _value);
    }

    function adminAddICO(uint256 _startTimestamp, uint256 _durationSeconds, 
        uint256 _coinsPerETH, uint256 _maxCap, uint _week1Rewards,
        uint _week2Rewards, uint _week3Rewards, uint _week4Rewards) isOwner{

        startTimestamp = _startTimestamp;
        durationSeconds = _durationSeconds;
        coinsPerETH = _coinsPerETH;
        maxCap = _maxCap * 1 ether;

        weeklyRewards[1] = _week1Rewards;
        weeklyRewards[2] = _week2Rewards;
        weeklyRewards[3] = _week3Rewards;
        weeklyRewards[4] = _week4Rewards;

         
        totalRaised = 0;
    }

    modifier isIcoOpen() {
        require(now >= startTimestamp);
        require(now <= (startTimestamp + durationSeconds));
        require(totalRaised <= maxCap);
        _;
    }

    modifier checkMinMax(){
      require(msg.value >= minPerUser);
      require(msg.value <= maxPerUser);
      _;
    }

    modifier isOwner(){
        require(msg.sender == fundsWallet);
        _;
    }
}