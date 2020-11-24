 

pragma solidity ^0.4.15;

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


 

library Math {
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

 
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

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

  

 contract ContractReceiver {

    function tokenFallback(address _from, uint _value, bytes _data);

}
 

 
 
 
 
 
 
 


 
contract TokenController {
     
     
     
    function proxyPayment(address _owner) payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount)
        returns(bool);
}

contract Controlled {
     
     
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() { controller = msg.sender;}

     
     
    function changeController(address _newController) onlyController {
        controller = _newController;
    }
}

 
 
contract SpectreSubscriberToken is StandardToken, Pausable, TokenController {
  using SafeMath for uint;

  string public constant name = "SPECTRE SUBSCRIBER TOKEN";
  string public constant symbol = "SXS";
  uint256 public constant decimals = 18;

  uint256 constant public TOKENS_AVAILABLE             = 240000000 * 10**decimals;
  uint256 constant public BONUS_SLAB                   = 100000000 * 10**decimals;
  uint256 constant public MIN_CAP                      = 5000000 * 10**decimals;
  uint256 constant public MIN_FUND_AMOUNT              = 1 ether;
  uint256 constant public TOKEN_PRICE                  = 0.0005 ether;
  uint256 constant public WHITELIST_PERIOD             = 3 days;

  address public specWallet;
  address public specDWallet;
  address public specUWallet;

  bool public refundable = false;
  bool public configured = false;
  bool public tokenAddressesSet = false;
   
  uint256 public presaleStart;
  uint256 public presaleEnd;
   
  uint256 public saleStart;
  uint256 public saleEnd;
   
  uint256 public discountSaleEnd;

   
  mapping(address => uint256) public whitelist;
  uint256 constant D160 = 0x0010000000000000000000000000000000000000000;

   
  mapping(address => uint256) public bonus;

  event Refund(address indexed _to, uint256 _value);
  event ContractFunded(address indexed _from, uint256 _value, uint256 _total);
  event Refundable();
  event WhiteListSet(address indexed _subscriber, uint256 _value);
  event OwnerTransfer(address indexed _from, address indexed _to, uint256 _value);

  modifier isRefundable() {
    require(refundable);
    _;
  }

  modifier isNotRefundable() {
    require(!refundable);
    _;
  }

  modifier isTransferable() {
    require(tokenAddressesSet);
    require(getNow() > saleEnd);
    require(totalSupply >= MIN_CAP);
    _;
  }

  modifier onlyWalletOrOwner() {
    require(msg.sender == owner || msg.sender == specWallet);
    _;
  }

   
   
   
   
  function SpectreSubscriberToken(address _specWallet) {
    require(_specWallet != address(0));
    specWallet = _specWallet;
    pause();
  }

   
   
  function() payable whenNotPaused public {
    require(msg.value >= MIN_FUND_AMOUNT);
    if(getNow() >= presaleStart && getNow() <= presaleEnd) {
      purchasePresale();
    } else if (getNow() >= saleStart && getNow() <= saleEnd) {
      purchase();
    } else {
      revert();
    }
  }

   
  function purchasePresale() internal {
     
    if (getNow() < (presaleStart + WHITELIST_PERIOD)) {
      require(whitelist[msg.sender] > 0);
       
      uint256 minAllowed = whitelist[msg.sender].mul(95).div(100);
      uint256 maxAllowed = whitelist[msg.sender].mul(120).div(100);
      require(msg.value >= minAllowed && msg.value <= maxAllowed);
       
      whitelist[msg.sender] = 0;
    }

    uint256 numTokens = msg.value.mul(10**decimals).div(TOKEN_PRICE);
    uint256 bonusTokens = 0;

    if(totalSupply < BONUS_SLAB) {
       
      uint256 remainingBonusSlabTokens = SafeMath.sub(BONUS_SLAB, totalSupply);
      uint256 bonusSlabTokens = Math.min256(remainingBonusSlabTokens, numTokens);
      uint256 nonBonusSlabTokens = SafeMath.sub(numTokens, bonusSlabTokens);
      bonusTokens = bonusSlabTokens.mul(33).div(100);
      bonusTokens = bonusTokens.add(nonBonusSlabTokens.mul(22).div(100));
    } else {
       
      bonusTokens = numTokens.mul(22).div(100);
    }
     
    numTokens = numTokens.add(bonusTokens);
    bonus[msg.sender] = bonus[msg.sender].add(bonusTokens);

     
    specWallet.transfer(msg.value);

    totalSupply = totalSupply.add(numTokens);
    require(totalSupply <= TOKENS_AVAILABLE);

    balances[msg.sender] = balances[msg.sender].add(numTokens);
     
    Transfer(0, msg.sender, numTokens);

  }

   
  function purchase() internal {

    uint256 numTokens = msg.value.mul(10**decimals).div(TOKEN_PRICE);
    uint256 bonusTokens = 0;

    if(getNow() <= discountSaleEnd) {
       
      bonusTokens = numTokens.mul(11).div(100);
    }

    numTokens = numTokens.add(bonusTokens);
    bonus[msg.sender] = bonus[msg.sender].add(bonusTokens);

     
    specWallet.transfer(msg.value);

    totalSupply = totalSupply.add(numTokens);

    require(totalSupply <= TOKENS_AVAILABLE);
    balances[msg.sender] = balances[msg.sender].add(numTokens);
     
    Transfer(0, msg.sender, numTokens);
  }

   
  function numberOfTokensLeft() constant returns (uint256) {
    return TOKENS_AVAILABLE.sub(totalSupply);
  }

   
  function unpause() onlyOwner whenPaused public {
    require(configured);
    paused = false;
    Unpause();
  }

   
   
   
  function setTokenAddresses(address _specUWallet, address _specDWallet) onlyOwner public {
    require(!tokenAddressesSet);
    require(_specDWallet != address(0));
    require(_specUWallet != address(0));
    require(isContract(_specDWallet));
    require(isContract(_specUWallet));
    specUWallet = _specUWallet;
    specDWallet = _specDWallet;
    tokenAddressesSet = true;
    if (configured) {
      unpause();
    }
  }

   
   
   
   
   
   
   
  function configure(uint256 _presaleStart, uint256 _presaleEnd, uint256 _saleStart, uint256 _saleEnd, uint256 _discountSaleEnd) onlyOwner public {
    require(!configured);
    require(_presaleStart > getNow());
    require(_presaleEnd > _presaleStart);
    require(_saleStart > _presaleEnd);
    require(_saleEnd > _saleStart);
    require(_discountSaleEnd > _saleStart && _discountSaleEnd <= _saleEnd);
    presaleStart = _presaleStart;
    presaleEnd = _presaleEnd;
    saleStart = _saleStart;
    saleEnd = _saleEnd;
    discountSaleEnd = _discountSaleEnd;
    configured = true;
    if (tokenAddressesSet) {
      unpause();
    }
  }

   
   
  function refund() isRefundable public {
    require(balances[msg.sender] > 0);

    uint256 tokenValue = balances[msg.sender].sub(bonus[msg.sender]);
    balances[msg.sender] = 0;
    tokenValue = tokenValue.mul(TOKEN_PRICE).div(10**decimals);

     
    msg.sender.transfer(tokenValue);
    Refund(msg.sender, tokenValue);
  }

  function withdrawEther() public isNotRefundable onlyOwner {
     
    msg.sender.transfer(this.balance);
  }

   
   
  function fundContract() public payable onlyWalletOrOwner {
     
    ContractFunded(msg.sender, msg.value, this.balance);
  }

  function setRefundable() onlyOwner {
    require(this.balance > 0);
    require(getNow() > saleEnd);
    require(totalSupply < MIN_CAP);
    Refundable();
    refundable = true;
  }

   
   
  function transfer(address _to, uint256 _value) isTransferable returns (bool success) {
     
     
    require(_to == specDWallet || _to == specUWallet);
    require(isContract(_to));
    bytes memory empty;
    return transferToContract(msg.sender, _to, _value, empty);
  }

   
  function isContract(address _addr) private returns (bool is_contract) {
    uint256 length;
    assembly {
       
      length := extcodesize(_addr)
    }
    return (length>0);
  }

   
  function transferToContract(address _from, address _to, uint256 _value, bytes _data) internal returns (bool success) {
    require(balanceOf(_from) >= _value);
    balances[_from] = balanceOf(_from).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(_from, _value, _data);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public isTransferable returns (bool) {
    require(_to == specDWallet || _to == specUWallet);
    require(isContract(_to));
     
    if (msg.sender == owner && getNow() > saleEnd + 28 days) {
      OwnerTransfer(_from, _to, _value);
    } else {
      uint256 _allowance = allowed[_from][msg.sender];
      allowed[_from][msg.sender] = _allowance.sub(_value);
    }

     
    bytes memory empty;
    return transferToContract(_from, _to, _value, empty);

  }

   
  function setWhiteList(address _subscriber, uint256 _amount) public onlyOwner {
    require(_subscriber != address(0));
    require(_amount != 0);
    whitelist[_subscriber] = _amount;
    WhiteListSet(_subscriber, _amount);
  }

   
   
   
  function multiSetWhiteList(uint256[] data) public onlyOwner {
    for (uint256 i = 0; i < data.length; i++) {
      address addr = address(data[i] & (D160 - 1));
      uint256 amount = data[i] / D160;
      setWhiteList(addr, amount);
    }
  }

   
   
   

   
   
   

  function proxyPayment(address _owner) payable returns(bool) {
      return false;
  }

   
   
   
   
   
   
  function onTransfer(address _from, address _to, uint _amount) returns(bool) {
      return true;
  }

   
   
   
   
   
   
  function onApprove(address _owner, address _spender, uint _amount)
      returns(bool)
  {
      return true;
  }

  function getNow() constant internal returns (uint256) {
    return now;
  }

}