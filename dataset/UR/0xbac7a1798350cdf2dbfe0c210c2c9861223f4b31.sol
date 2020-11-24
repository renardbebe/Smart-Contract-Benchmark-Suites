 

pragma solidity ^0.4.23;

 
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

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

contract MNC is StandardToken, Ownable {
  string public constant name = "Moneynet Coin";
  string public constant symbol = "MNC";
  uint32 public constant decimals = 18;

   
  uint256 public saleTokens = uint256(6e9).mul(1 ether);
  uint256 public ecosystemTokens = uint256(204e8).mul(1 ether);
  uint256 public teamTokens = uint256(4e9).mul(1 ether);
  uint256 public investorsTokens = uint256(24e8).mul(1 ether);
  uint256 public advisorsTokens = uint256(2e9).mul(1 ether);
  uint256 public bonusTokens = uint256(16e8).mul(1 ether);
  uint256 public reserveTokens = uint256(36e8).mul(1 ether);

   
  address public saleContract;

   
  mapping(address => uint256) public lockedTokens_3;
  mapping(address => uint256) public lockedTokens_6;
  mapping(address => uint256) public lockedTokens_12;
  uint256 lockTime = now;

  constructor(address _newOwner) public {
    require(_newOwner != address(0));
    uint256 tokens = ecosystemTokens;
    owner = _newOwner;
    balances[owner] = balances[owner].add(tokens);
    totalSupply_ = totalSupply_.add(tokens);
    emit Transfer(address(0), owner, tokens);
  }


   
  function activateSaleContract(address _contract) public onlyOwner returns (bool) {
    require(_contract != address(0));
    require(saleTokens > 0);
    uint256 tokens = saleTokens;
    saleTokens = 0;
    saleContract = _contract;
    totalSupply_ = totalSupply_.add(tokens);
    balances[_contract] = balances[_contract].add(tokens);
    emit Transfer(address(0), _contract, tokens);
    return true;
  }

   
  function sendReserveTokens() public onlyOwner returns (bool) {
    require(saleContract != address(0));
    require(reserveTokens > 0);
    uint256 tokens = reserveTokens;
    reserveTokens = 0;
    totalSupply_ = totalSupply_.add(tokens);
    balances[saleContract] = balances[saleContract].add(tokens);
    emit Transfer(address(0), saleContract, tokens);
    return true;
  }

   
  function accrueTeamTokens(address _address, uint256 _amount) public onlyOwner returns (bool) {
    require(_amount > 0);
    require(_amount <= teamTokens);
    require(_address != address(0));
    teamTokens = teamTokens.sub(_amount);
    lockedTokens_12[_address] = lockedTokens_12[_address].add(_amount);
    return true;
  }

   
  function accrueInvestorsTokens(address _address, uint256 _amount) public onlyOwner returns (bool) {
    require(_amount > 0);
    require(_amount <= investorsTokens);
    require(_address != address(0));
    investorsTokens = investorsTokens.sub(_amount);
    lockedTokens_6[_address] = lockedTokens_6[_address].add(_amount);
    return true;
  }

   
  function accrueAdvisorsTokens(address _address, uint256 _amount) public onlyOwner returns (bool) {
    require(_amount > 0);
    require(_amount <= advisorsTokens);
    require(_address != address(0));
    advisorsTokens = advisorsTokens.sub(_amount);
    lockedTokens_6[_address] = lockedTokens_6[_address].add(_amount);
    return true;
  }

   
  function accrueBonusTokens(address _address, uint256 _amount) public onlyOwner returns (bool) {
    require(_amount > 0);
    require(_amount <= bonusTokens);
    require(_address != address(0));
    bonusTokens = bonusTokens.sub(_amount);
    lockedTokens_3[_address] = lockedTokens_3[_address].add(_amount);
    return true;
  }

  function releaseTokens() public returns (bool) {
    uint256 tokens = 0;
    if (lockedTokens_3[msg.sender] > 0 && now.sub(lockTime) > 91 days) {
      tokens = tokens.add(lockedTokens_3[msg.sender]);
      lockedTokens_3[msg.sender] = 0;
    }
    if (lockedTokens_6[msg.sender] > 0 && now.sub(lockTime) > 182 days) {
      tokens = tokens.add(lockedTokens_6[msg.sender]);
      lockedTokens_6[msg.sender] = 0;
    }
    if (lockedTokens_12[msg.sender] > 0 && now.sub(lockTime) > 365 days) {
      tokens = tokens.add(lockedTokens_12[msg.sender]);
      lockedTokens_12[msg.sender] = 0;
    }
    require (tokens > 0);
    totalSupply_ = totalSupply_.add(tokens);
    balances[msg.sender] = balances[msg.sender].add(tokens);
    emit Transfer(address(0), msg.sender, tokens);
  }
}