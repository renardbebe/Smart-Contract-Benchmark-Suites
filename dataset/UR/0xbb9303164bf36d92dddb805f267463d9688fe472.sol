 

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

contract TokenSale is ContractReceiver {
  using SafeMath for uint256;

  bool    public active = false;
  address public tokenAddress;
  uint256 public hardCap;
  uint256 public sold;

   
  uint256 private priceDiv = 2000000000;
  address private stn;
  address private owner;
  address private treasury;

  struct Ref {
    uint256 amount;
    uint256 rewardDiv;
    uint256 etherAmount;
  }

  mapping(address => Ref) private referrals;

  event Activated(uint256 time);
  event Finished(uint256 time);
  event Purchase(address indexed purchaser, uint256 amount);
  event Referral(address indexed referrer, uint256 amount);

  function TokenSale(address token, address presaleToken, address ethRecepient, uint256 cap) public {
    tokenAddress  = token;
    stn           = presaleToken;
    owner         = msg.sender;
    treasury      = ethRecepient;
    hardCap       = cap;
  }

  function tokenFallback(address _from, uint _value, bytes  ) public {
    if (active && msg.sender == stn) {
      stnExchange(_from, _value);
    } else {
      if (msg.sender != tokenAddress) { revert(); }
      if (active) { revert(); }
      if (_value != hardCap) { revert(); }

      active = true;
      Activated(now);
    }
  }

  function stnExchange(address buyer, uint256 value) private {
    uint256 purchasedAmount = value.mul(50000);
    if (purchasedAmount == 0) { revert(); }  
    if (purchasedAmount > hardCap - sold) { revert(); }  

    sold += purchasedAmount;

    ERC223 token = ERC223(tokenAddress);
    token.transfer(buyer, purchasedAmount);
    Purchase(buyer, purchasedAmount);
  }

  function refAmount(address user) constant public returns (uint256 amount) {
    return referrals[user].amount;
  }

  function refPercentage(address user) constant public returns (uint256 percentage) {
    uint256 rewardDiv = referrals[user].rewardDiv;
    if (rewardDiv == 0)   { return 1; }
    if (rewardDiv == 100) { return 1; }
    if (rewardDiv == 50)  { return 2; }
    if (rewardDiv == 20)  { return 5; }
    if (rewardDiv == 10)  { return 10; }
  }

  function () external payable {
    processPurchase(0x0);
  }

  function processPurchase(address referrer) payable public {
    if (!active) { revert(); }
    if (msg.value == 0) { revert(); }

    uint256 purchasedAmount = msg.value.div(priceDiv);
    if (purchasedAmount == 0) { revert(); }  
    if (purchasedAmount > hardCap - sold) { revert(); }  

    sold += purchasedAmount;
    treasury.transfer(msg.value);

    ERC223 token = ERC223(tokenAddress);
    token.transfer(msg.sender, purchasedAmount);
    Purchase(msg.sender, purchasedAmount);
    processReferral(referrer, purchasedAmount, msg.value);
  }

  function processReferral(address referrer, uint256 tokenAmount, uint256 etherAmount) private returns (bool success) {
    if (referrer == 0x0) { return true; }
    Ref memory ref = referrals[referrer];
    if (ref.rewardDiv == 0) { ref.rewardDiv = 100; }  
    uint256 referralAmount = tokenAmount.div(ref.rewardDiv);
    if (referralAmount == 0) { return true; }
     
    if (referralAmount > hardCap - sold) { referralAmount = hardCap - sold; }
    ref.amount = ref.amount.add(referralAmount);
    ref.etherAmount = ref.etherAmount.add(etherAmount);

     
    if (ref.etherAmount > 5 ether)   { ref.rewardDiv = 50; }  
    if (ref.etherAmount > 10 ether)  { ref.rewardDiv = 20; }  
    if (ref.etherAmount > 100 ether) { ref.rewardDiv = 10; }  
     

    sold += referralAmount;
    referrals[referrer] = ref;  
    ERC223 token = ERC223(tokenAddress);
    token.transfer(referrer, referralAmount);
    Referral(referrer, referralAmount);
    return true;
  }

  function endSale() public {
     
    if (msg.sender != owner) { revert(); }
     
    if (!active) { revert(); }
    _end();
  }

  function _end() private {
     
    if (sold < hardCap) {
      ERC223 token = ERC223(tokenAddress);
      token.transfer(treasury, hardCap.sub(sold));
    }
    active = false;
    Finished(now);
  }
}