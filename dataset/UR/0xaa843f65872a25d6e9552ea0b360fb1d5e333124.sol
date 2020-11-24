 

pragma solidity ^0.4.20;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
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
    owner = newOwner;
    OwnershipTransferred(owner, newOwner);
  }
}

contract CutdownTokenInterface {
	 
  	function balanceOf(address who) public view returns (uint256);
  	function transfer(address to, uint256 value) public returns (bool);

  	 
  	function tokenFallback(address from, uint256 amount, bytes data) public returns (bool);
}

 
contract EcoValueCoin is Ownable {
  using SafeMath for uint256;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  
  event Burn(address indexed _burner, uint256 _value);
  event TransfersEnabled();
  event TransferRightGiven(address indexed _to);
  event TransferRightCancelled(address indexed _from);
  event WithdrawnERC20Tokens(address indexed _tokenContract, address indexed _owner, uint256 _balance);
  event WithdrawnEther(address indexed _owner, uint256 _balance);

  string public constant name = "Eco Value Coin";
  string public constant symbol = "EVC";
  uint256 public constant decimals = 18;
  uint256 public constant initialSupply = 3300000000 * (10 ** decimals);
  uint256 public totalSupply;

  mapping(address => uint256) public balances;
  mapping(address => mapping (address => uint256)) internal allowed;

   
   
  mapping(address => bool) public transferGrants;
   
  bool public transferable;

   
  modifier canTransfer() {
    require(transferable || transferGrants[msg.sender]);
    _;
  }

   
  function EcoValueCoin() public {
    owner = msg.sender;
    totalSupply = initialSupply;
    balances[owner] = totalSupply;
    transferGrants[owner] = true;
  }

   
  function () payable public {
    revert();
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

   
  function transfer(address _to, uint256 _value) canTransfer public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) canTransfer public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) canTransfer public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) canTransfer public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) canTransfer public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) canTransfer public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(burner, _value);
  }

   
  function enableTransfers() onlyOwner public {
    require(!transferable);
    transferable = true;
    TransfersEnabled();
  }

   
  function grantTransferRight(address _to) onlyOwner public {
    require(!transferable);
    require(!transferGrants[_to]);
    require(_to != address(0));
    transferGrants[_to] = true;
    TransferRightGiven(_to);
  }

   
  function cancelTransferRight(address _from) onlyOwner public {
    require(!transferable);
    require(transferGrants[_from]);
    transferGrants[_from] = false;
    TransferRightCancelled(_from);
  }

   
  function withdrawERC20Tokens(address _tokenContract) onlyOwner public {
    CutdownTokenInterface token = CutdownTokenInterface(_tokenContract);
    uint256 totalBalance = token.balanceOf(address(this));
    token.transfer(owner, totalBalance);
    WithdrawnERC20Tokens(_tokenContract, owner, totalBalance);
  }

   
  function withdrawEther() public onlyOwner {
    uint256 totalBalance = this.balance;
    require(totalBalance > 0);
    owner.transfer(totalBalance);
    WithdrawnEther(owner, totalBalance);
  }
}