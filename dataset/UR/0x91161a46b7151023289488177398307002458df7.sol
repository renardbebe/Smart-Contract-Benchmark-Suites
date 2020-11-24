 

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

contract BTNY is StandardToken, Ownable {
  string public constant name = "Bitenny";
  string public constant symbol = "BTNY";
  uint32 public constant decimals = 18;
  
  address public team = address(0);
  address public saleContract = address(0);
  uint256 public unlockDate = 1541030400;  
  mapping(address => bool) transferWhitelist;

  modifier unlocked() {
    if (now < unlockDate && !transferWhitelist[msg.sender])
    revert();
    _;
  }

  event SaleContractActivation(address saleContract, uint256 tokensForSale);

  event Burn(address tokensOwner, uint256 burnedTokensAmount);

  constructor(address _owner, address _team) public {
    require(_owner != address(0));
    require(_team != address(0));
    team = _team;
    uint256 ownerBudget = uint256(9600000000).mul(1 ether);
    uint256 teamTokens = uint256(2400000000).mul(1 ether);
    owner = _owner;
    transferWhitelist[owner] = true;
    totalSupply_ = totalSupply_.add(ownerBudget);
    balances[owner] = balances[owner].add(ownerBudget);
    emit Transfer(address(this), owner, ownerBudget);
    totalSupply_ = totalSupply_.add(teamTokens);
    balances[team] = balances[team].add(teamTokens);
    emit Transfer(address(this), team, teamTokens);
  }

  function addToTransferWhiteList(address _address) public onlyOwner returns (bool) {
    transferWhitelist[_address] = true;
    return true;
  }

  function transfer(address _to, uint256 _value) public unlocked returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public unlocked returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public unlocked returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public unlocked returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function activateSaleContract(address _contract) public {
    require(_contract != address(0));
    require(saleContract == address(0));
    saleContract = _contract;
    transferWhitelist[saleContract] = true;
    uint256 tokensToSaleContract = uint256(12000000000).mul(1 ether);
    totalSupply_ = totalSupply_.add(tokensToSaleContract);
    balances[saleContract] = balances[saleContract].add(tokensToSaleContract);
    emit Transfer(address(this), saleContract, tokensToSaleContract);
    emit SaleContractActivation(saleContract, tokensToSaleContract);
  }

  function burnTokensForSale() public returns (bool) {
    require(saleContract != address(0));
    require(msg.sender == saleContract);
    uint256 tokens = balances[saleContract];
    require(tokens > 0);
    require(tokens <= totalSupply_);
    balances[saleContract] = 0;
    totalSupply_ = totalSupply_.sub(tokens);
    emit Burn(saleContract, tokens);
    return true;
  }
}