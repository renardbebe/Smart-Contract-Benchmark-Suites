 

pragma solidity ^0.4.16;
 
 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
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
contract BMICoin is StandardToken, Ownable {
  string public constant name = "BMI Coin";
  string public constant symbol = "BMI";
  uint256 public constant decimals = 18;
  uint256 public constant UNIT = 10 ** decimals;
  address public companyWallet;
  address public backendWallet;
  uint256 public maxSupply = 3000000 * UNIT;
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  modifier onlyBackend() {
    require(msg.sender == backendWallet);
    _;
  }
  function BMICoin(address _companyWallet, address _backendWallet) public {
    companyWallet = _companyWallet;
    backendWallet = _backendWallet;
    balances[companyWallet] = 1500000 * UNIT;
    totalSupply_ = totalSupply_.add(1500000 * UNIT);
    Transfer(address(0x0), _companyWallet, 1500000 * UNIT);
  }
   
  function setBackendWallet(address _backendWallet) public onlyOwner {
    require(backendWallet != address(0));
    backendWallet = _backendWallet;
  }
  function() public payable {
    revert();
  }
   
  function mint(address receiver, uint256 tokens) public onlyBackend {
    require(totalSupply_ + tokens <= maxSupply);
    balances[receiver] += tokens;
    totalSupply_ += tokens;
    Transfer(address(0x0), receiver, tokens);
  }
  function sendBonus(address receiver, uint256 bonus) public onlyBackend {
    Transfer(companyWallet, receiver, bonus);
    balances[companyWallet] = balances[companyWallet].sub(bonus);
    balances[receiver] = balances[receiver].add(bonus);
  }
}