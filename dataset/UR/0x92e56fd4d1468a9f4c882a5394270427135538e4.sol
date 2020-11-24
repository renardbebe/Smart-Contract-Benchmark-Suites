 

pragma solidity ^0.4.21;

 

 
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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

 

 
contract PentacoreToken is StandardToken {
  using SafeMath for uint256;

  string public name = 'PentacoreToken';
  string public symbol = 'PENT';
  uint256 public constant million = 1000000;
  uint256 public constant tokenCap = 1000 * million;  
  bool public isPaused = true;

   
   
   
   
   
   
   
   
   
   
   
   
   
  mapping(address => bool) public whitelist;

   
   
   
   
  bool public isFreeTransferAllowed = false;

  uint256 public tokenNAVMicroUSD;  
  uint256 public weiPerUSD;  

   
  address public owner;  
  address public kycAdmin;  
  address public navAdmin;  
  address public crowdsale;  
  address public redemption;  
  address public distributedAutonomousExchange;  

  event Mint(address indexed to, uint256 amount);
  event Burn(uint256 amount);
  event AddToWhitelist(address indexed beneficiary);
  event RemoveFromWhitelist(address indexed beneficiary);

  function PentacoreToken() public {
    owner = msg.sender;
    tokenNAVMicroUSD = million;  
    isFreeTransferAllowed = false;
    isPaused = true;
    totalSupply_ = 0;  
  }

   
  modifier onlyBy(address authorized) {
    require(authorized != address(0));
    require(msg.sender == authorized);
    _;
  }

   
  function setPaused(bool _pause) public {
    require(owner != address(0));
    require(msg.sender == owner);

    isPaused = _pause;
  }

  modifier notPaused() {
    require(!isPaused);
    _;
  }

   
  function transferOwnership(address _address) external onlyBy(owner) {
    require(_address != address(0));  
    owner = _address;
  }

   
  function setKYCAdmin(address _address) external onlyBy(owner) {
    kycAdmin = _address;
  }

   
  function setNAVAdmin(address _address) external onlyBy(owner) {
    navAdmin = _address;
  }

   
  function setCrowdsaleContract(address _address) external onlyBy(owner) {
    crowdsale = _address;
  }

   
  function setRedemptionContract(address _address) external onlyBy(owner) {
    redemption = _address;
  }

   
  function setDistributedAutonomousExchange(address _address) external onlyBy(owner) {
    distributedAutonomousExchange = _address;
  }

   
  function setTokenNAVMicroUSD(uint256 _price) external onlyBy(navAdmin) {
    tokenNAVMicroUSD = _price;
  }

   
  function setWeiPerUSD(uint256 _price) external onlyBy(navAdmin) {
    weiPerUSD = _price;
  }

   
  function tokensToWei(uint256 _tokenAmount) public view returns (uint256) {
    require(tokenNAVMicroUSD != uint256(0));
    require(weiPerUSD != uint256(0));
    return _tokenAmount.mul(tokenNAVMicroUSD).mul(weiPerUSD).div(million);
  }

   
  function weiToTokens(uint256 _weiAmount) public view returns (uint256, uint256) {
    require(tokenNAVMicroUSD != uint256(0));
    require(weiPerUSD != uint256(0));
    uint256 tokens = _weiAmount.mul(million).div(weiPerUSD).div(tokenNAVMicroUSD);
    uint256 changeWei = _weiAmount.sub(tokensToWei(tokens));
    return (tokens, changeWei);
  }

   
  function setFreeTransferAllowed(bool _isFreeTransferAllowed) public {
    require(owner != address(0));
    require(msg.sender == owner);

    isFreeTransferAllowed = _isFreeTransferAllowed;
  }

   
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

   
  modifier isWhitelistedOrFreeTransferAllowed(address _beneficiary) {
    require(isFreeTransferAllowed || whitelist[_beneficiary]);
    _;
  }

   
  function addToWhitelist(address _beneficiary) public onlyBy(kycAdmin) {
    whitelist[_beneficiary] = true;
    emit AddToWhitelist(_beneficiary);
  }

   
  function addManyToWhitelist(address[] _beneficiaries) external onlyBy(kycAdmin) {
    for (uint256 i = 0; i < _beneficiaries.length; i++) addToWhitelist(_beneficiaries[i]);
  }

   
  function removeFromWhitelist(address _beneficiary) public onlyBy(kycAdmin) {
    whitelist[_beneficiary] = false;
    emit RemoveFromWhitelist(_beneficiary);
  }

   
  function removeManyFromWhitelist(address[] _beneficiaries) external onlyBy(kycAdmin) {
    for (uint256 i = 0; i < _beneficiaries.length; i++) removeFromWhitelist(_beneficiaries[i]);
  }

   
  function mint(address _to, uint256 _amount) public onlyBy(crowdsale) isWhitelisted(_to) returns (bool) {
     
    require(tokenNAVMicroUSD != uint256(0));
    require(weiPerUSD != uint256(0));
    require(totalSupply_.add(_amount) <= tokenCap);
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    return true;
  }

   
  function burn(uint256 _amount) public onlyBy(redemption) returns (bool) {
     
    require(balances[redemption].sub(_amount) >= uint256(0));
    require(totalSupply_.sub(_amount) >= uint256(0));
    balances[redemption] = balances[redemption].sub(_amount);
    totalSupply_ = totalSupply_.sub(_amount);
    emit Burn(_amount);
    return true;
  }

   
  function transfer(address _to, uint256 _value) public notPaused isWhitelistedOrFreeTransferAllowed(msg.sender) isWhitelistedOrFreeTransferAllowed(_to) returns (bool) {
    return super.transfer(_to, _value);
  }

   
  function approve(address _spender, uint256 _value) public notPaused isWhitelistedOrFreeTransferAllowed(msg.sender) returns (bool) {
    return super.approve(_spender, _value);
  }

   
  function increaseApproval(address _spender, uint _addedValue) public notPaused isWhitelistedOrFreeTransferAllowed(msg.sender) returns (bool) {
    return super.increaseApproval(_spender, _addedValue);
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public notPaused isWhitelistedOrFreeTransferAllowed(_from) isWhitelistedOrFreeTransferAllowed(_to) returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }
}