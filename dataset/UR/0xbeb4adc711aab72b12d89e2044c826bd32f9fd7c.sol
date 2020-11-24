 

pragma solidity 0.4.15;

 
 
contract ERC20 {

   

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

   

  function transfer(address _to, uint256 _value) public returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  function balanceOf(address _owner) public constant returns (uint256);
  function allowance(address _owner, address _spender) public constant returns (uint256);

   

  uint256 public totalSupply;
}

 
 
 
contract Ownable {

   

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   

   
  function Ownable() {
    owner = msg.sender;
  }

   
   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   

  address public owner;
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

 
 
contract StandardToken is ERC20 {
  using SafeMath for uint256;

   

   
   
   
   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowances[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
   
   
   
   
   
   
   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowances[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
   
   
  function balanceOf(address _owner) public constant returns (uint256) {
    return balances[_owner];
  }

   
   
   
   
  function allowance(address _owner, address _spender) public constant returns (uint256) {
    return allowances[_owner][_spender];
  }

   

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowances;
}

 
contract PapyrusPrototypeToken is StandardToken, Ownable {

   

  event Mint(address indexed to, uint256 amount, uint256 priceUsd);
  event MintFinished();
  event TransferableChanged(bool transferable);

   

   
  function() { revert(); }

   
  function transfer(address _to, uint _value) canTransfer public returns (bool) {
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint _value) canTransfer public returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

   
   
   
   
   
  function mint(address _to, uint256 _amount, uint256 _priceUsd) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    if (_priceUsd != 0) {
      uint256 amountUsd = _amount.mul(_priceUsd).div(10**18);
      totalCollected = totalCollected.add(amountUsd);
    }
    Mint(_to, _amount, _priceUsd);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

   
   
  function setTransferable(bool _transferable) onlyOwner public returns (bool) {
    require(transferable != _transferable);
    transferable = _transferable;
    TransferableChanged(transferable);
    return true;
  }

   

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier canTransfer() {
    require(transferable || msg.sender == owner);
    _;
  }

   

   
  string public name = "Papyrus Prototype Token";
  string public symbol = "PRP";
  string public version = "H0.1";
  uint8 public decimals = 18;

   
  bool public transferable = false;

   
  bool public mintingFinished = false;

   
  uint public totalCollected;
}