 

pragma solidity 0.4.24;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract Ownable {
  address public owner;


   
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
   
   
   
   
}

 
contract BasicToken is ERC20Basic, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping(address => uint256) bonusTokens;
  mapping(address => uint256) bonusReleaseTime;
  
  mapping(address => bool) internal blacklist;
  address[] internal blacklistHistory;
  
  bool public isTokenReleased = false;
  
  address addressSaleContract;
  event BlacklistUpdated(address badUserAddress, bool registerStatus);
  event TokenReleased(address tokenOwnerAddress, bool tokenStatus);

  uint256 totalSupply_;

  modifier onlyBonusSetter() {
      require(msg.sender == owner || msg.sender == addressSaleContract);
      _;
  }

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    require(isTokenReleased);
    require(!blacklist[_to]);
    require(!blacklist[msg.sender]);
    
    if (bonusReleaseTime[msg.sender] > block.timestamp) {
        require(_value <= balances[msg.sender].sub(bonusTokens[msg.sender]));
    }
    
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    require(msg.sender == owner || !blacklist[_owner]);
    require(!blacklist[msg.sender]);
    return balances[_owner];
  }

   
  function registerToBlacklist(address _badUserAddress) onlyOwner public {
      if (blacklist[_badUserAddress] != true) {
	  	  blacklist[_badUserAddress] = true;
          blacklistHistory.push(_badUserAddress);
	  }
      emit BlacklistUpdated(_badUserAddress, blacklist[_badUserAddress]);   
  }
  
   
  function unregisterFromBlacklist(address _badUserAddress) onlyOwner public {
      if (blacklist[_badUserAddress] == true) {
	  	  blacklist[_badUserAddress] = false;
	  }
      emit BlacklistUpdated(_badUserAddress, blacklist[_badUserAddress]);
  }

   
  function checkBlacklist (address _address) onlyOwner public view returns (bool) {
      return blacklist[_address];
  }

  function getblacklistHistory() onlyOwner public view returns (address[]) {
      return blacklistHistory;
  }
  
   
  function releaseToken() onlyOwner public {
      if (isTokenReleased == false) {
		isTokenReleased = true;
	  }
      emit TokenReleased(msg.sender, isTokenReleased);
  }
  
   
  function withholdToken() onlyOwner public {
      if (isTokenReleased == true) {
		isTokenReleased = false;
      }
	  emit TokenReleased(msg.sender, isTokenReleased);
  }
  
     
  function setBonusTokenInDays(address _tokenHolder, uint256 _bonusTokens, uint256 _holdingPeriodInDays) onlyBonusSetter public {
      bonusTokens[_tokenHolder] = _bonusTokens;
      bonusReleaseTime[_tokenHolder] = SafeMath.add(block.timestamp, _holdingPeriodInDays * 1 days);
  }

     
  function setBonusToken(address _tokenHolder, uint256 _bonusTokens, uint256 _bonusReleaseTime) onlyBonusSetter public {
      bonusTokens[_tokenHolder] = _bonusTokens;
      bonusReleaseTime[_tokenHolder] = _bonusReleaseTime;
  }
  
     
  function setBonusTokens(address[] _tokenHolders, uint256[] _bonusTokens, uint256 _bonusReleaseTime) onlyBonusSetter public {
      for (uint i = 0; i < _tokenHolders.length; i++) {
        bonusTokens[_tokenHolders[i]] = _bonusTokens[i];
        bonusReleaseTime[_tokenHolders[i]] = _bonusReleaseTime;
      }
  }

  function setBonusTokensInDays(address[] _tokenHolders, uint256[] _bonusTokens, uint256 _holdingPeriodInDays) onlyBonusSetter public {
      for (uint i = 0; i < _tokenHolders.length; i++) {
        bonusTokens[_tokenHolders[i]] = _bonusTokens[i];
        bonusReleaseTime[_tokenHolders[i]] = SafeMath.add(block.timestamp, _holdingPeriodInDays * 1 days);
      }
  }

   
  function setBonusSetter(address _addressSaleContract) onlyOwner public {
      addressSaleContract = _addressSaleContract;
  }
  
  function getBonusSetter() public view returns (address) {
      require(msg.sender == addressSaleContract || msg.sender == owner);
      return addressSaleContract;
  }
  
   
  function checkBonusTokenAmount (address _bonusHolderAddress) public view returns (uint256) {
      return bonusTokens[_bonusHolderAddress];
  }
  
   
  function checkBonusTokenHoldingPeriodRemained (address _bonusHolderAddress) public view returns (uint256) {
      uint256 returnValue = 0;
      if (bonusReleaseTime[_bonusHolderAddress] > now) {
          returnValue = bonusReleaseTime[_bonusHolderAddress].sub(now);
      }
      return returnValue;
  }
}

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) onlyOwner public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) onlyOwner internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
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
}

 
contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) internal allowed;
  
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(!blacklist[_from]);
    require(!blacklist[_to]);
	require(!blacklist[msg.sender]);
    require(isTokenReleased);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    require(isTokenReleased);
    require(!blacklist[_spender]);
	require(!blacklist[msg.sender]);

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    require(!blacklist[_owner]);
    require(!blacklist[_spender]);
	require(!blacklist[msg.sender]);

    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    require(!blacklist[_spender]);
	require(!blacklist[msg.sender]);

    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    require(!blacklist[_spender]);    
	require(!blacklist[msg.sender]);

    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

 
contract TrustVerseToken is BurnableToken, StandardToken {
  string public constant name = "TrustVerse";  
  string public constant symbol = "TRV";  
  uint8 public constant decimals = 18;  
  uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));
  mapping (address => mapping (address => uint256)) internal EffectiveDateOfAllowance;  

   
  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }

   
  function transferToMultiAddress(address[] _to, uint256[] _value) public {
    require(_to.length == _value.length);

    uint256 transferTokenAmount = 0;
    uint256 i = 0;
    for (i = 0; i < _to.length; i++) {
        transferTokenAmount = transferTokenAmount.add(_value[i]);
    }
    require(transferTokenAmount <= balances[msg.sender]);

    for (i = 0; i < _to.length; i++) {
        transfer(_to[i], _value[i]);
    }
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(EffectiveDateOfAllowance[_from][msg.sender] <= block.timestamp); 
    return super.transferFrom(_from, _to, _value);
  }

   
  function approveWithEffectiveDate(address _spender, uint256 _value, uint256 _effectiveDate) public returns (bool) {
    require(isTokenReleased);
    require(!blacklist[_spender]);
	require(!blacklist[msg.sender]);
    
    EffectiveDateOfAllowance[msg.sender][_spender] = _effectiveDate;
    return approve(_spender, _value);
  }

   
  function approveWithEffectiveDateInDays(address _spender, uint256 _value, uint256 _effectiveDateInDays) public returns (bool) {
    require(isTokenReleased);
    require(!blacklist[_spender]);
	require(!blacklist[msg.sender]);
    
    EffectiveDateOfAllowance[msg.sender][_spender] = SafeMath.add(block.timestamp, _effectiveDateInDays * 1 days);
    return approve(_spender, _value);
  }  

   
  function allowanceEffectiveDate(address _owner, address _spender) public view returns (uint256) {
    require(!blacklist[_owner]);
    require(!blacklist[_spender]);
	require(!blacklist[msg.sender]);

    return EffectiveDateOfAllowance[_owner][_spender];
  }
}