 

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

 
contract OpportyToken is StandardToken {

  string public constant name = "OpportyToken";
  string public constant symbol = "OPP";
  uint8 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));

   
  function OpportyToken() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    Transfer(0x0, msg.sender, INITIAL_SUPPLY);
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

contract OpportyWhiteListHold is Ownable {
  using SafeMath for uint256;
   
  OpportyToken public OppToken;

  struct Holder {
    bool isActive;
    uint tokens;
    uint8 holdPeriod;
    uint holdPeriodTimestamp;
    bool withdrawed;
  }

  mapping(address => Holder) public holderList;
  mapping(uint => address) private holderIndexes;

  mapping (uint => address) private assetOwners;
  mapping (address => uint) private assetOwnersIndex;
  uint public assetOwnersIndexes;

  uint private holderIndex;

  event TokensTransfered(address contributor , uint amount);
  event Hold(address sender, address contributor, uint amount, uint8 holdPeriod);
  event ChangeHold(address sender, address contributor, uint amount, uint8 holdPeriod);
  event TokenChanged(address newAddress);
  event ManualPriceChange(uint beforePrice, uint afterPrice);

  modifier onlyAssetsOwners() {
    require(assetOwnersIndex[msg.sender] > 0 || msg.sender == owner);
    _;
  }

  function getBalanceContract() view internal returns (uint) {
    return OppToken.balanceOf(this);
  }

  function setToken(address newToken) public onlyOwner {
    OppToken = OpportyToken(newToken);
    TokenChanged(newToken);
  }

  function changeHold(address holder, uint tokens, uint8 period, uint holdTimestamp, bool withdrawed ) public onlyAssetsOwners {
    if (holderList[holder].isActive == true) {
      holderList[holder].tokens = tokens;
      holderList[holder].holdPeriod = period;
      holderList[holder].holdPeriodTimestamp = holdTimestamp;
      holderList[holder].withdrawed = withdrawed;
      ChangeHold(msg.sender, holder, tokens, period);
    }
  }

  function addHolder(address holder, uint tokens, uint8 timed, uint timest) onlyAssetsOwners external {
    if (holderList[holder].isActive == false) {
      holderList[holder].isActive = true;
      holderList[holder].tokens = tokens;
      holderList[holder].holdPeriod = timed;
      holderList[holder].holdPeriodTimestamp = timest;
      holderIndexes[holderIndex] = holder;
      holderIndex++;
    } else {
      holderList[holder].tokens += tokens;
      holderList[holder].holdPeriod = timed;
      holderList[holder].holdPeriodTimestamp = timest;
    }
    Hold(msg.sender, holder, tokens, timed);
  }

  function getBalance() public constant returns (uint) {
    return OppToken.balanceOf(this);
  }

  function returnTokens(uint nTokens) public onlyOwner returns (bool) {
    require(nTokens <= getBalance());
    OppToken.transfer(msg.sender, nTokens);
    TokensTransfered(msg.sender, nTokens);
    return true;
  }

  function unlockTokens() public returns (bool) {
    require(holderList[msg.sender].isActive);
    require(!holderList[msg.sender].withdrawed);
    require(now >= holderList[msg.sender].holdPeriodTimestamp);

    OppToken.transfer(msg.sender, holderList[msg.sender].tokens);
    holderList[msg.sender].withdrawed = true;
    TokensTransfered(msg.sender, holderList[msg.sender].tokens);
    return true;
  }

  function addAssetsOwner(address _owner) public onlyOwner {
    assetOwnersIndexes++;
    assetOwners[assetOwnersIndexes] = _owner;
    assetOwnersIndex[_owner] = assetOwnersIndexes;
  }
  function removeAssetsOwner(address _owner) public onlyOwner {
    uint index = assetOwnersIndex[_owner];
    delete assetOwnersIndex[_owner];
    delete assetOwners[index];
    assetOwnersIndexes--;
  }
  function getAssetsOwners(uint _index) onlyOwner public constant returns (address) {
    return assetOwners[_index];
  }
}