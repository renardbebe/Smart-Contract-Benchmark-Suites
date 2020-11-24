 

pragma solidity 0.4.21;

 
 
 
 
 
 
 
 
 
 
 

 
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

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    owner = _newOwner;
    emit OwnershipTransferred(owner, _newOwner);
  }
}

 
contract CutdownToken {
  	function balanceOf(address _who) public view returns (uint256);
  	function transfer(address _to, uint256 _value) public returns (bool);
  	function allowance(address _owner, address _spender) public view returns (uint256);
}

 
contract ApproveAndCallFallback {
    function receiveApproval(address _from, uint256 _amount, address _tokenContract, bytes _data) public returns (bool);
}

 
contract DigitizeCoin is Ownable {
  using SafeMath for uint256;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  
  event Burn(address indexed _burner, uint256 _value);
  event TransfersEnabled();
  event TransferRightGiven(address indexed _to);
  event TransferRightCancelled(address indexed _from);
  event WithdrawnERC20Tokens(address indexed _tokenContract, address indexed _owner, uint256 _balance);
  event WithdrawnEther(address indexed _owner, uint256 _balance);
  event ApproveAndCall(address indexed _from, address indexed _to, uint256 _value, bytes _data);

  string public constant name = "Digitize Coin";
  string public constant symbol = "DTZ";
  uint256 public constant decimals = 18;
  uint256 public constant initialSupply = 200000000 * (10 ** decimals);
  uint256 public totalSupply;

  mapping(address => uint256) public balances;
  mapping(address => mapping (address => uint256)) internal allowed;

   
   
  mapping(address => bool) public transferGrants;
   
  bool public transferable;

   
  modifier canTransfer() {
    require(transferable || transferGrants[msg.sender]);
    _;
  }

   
  function DigitizeCoin() public {
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
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) canTransfer public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) canTransfer public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) canTransfer public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) canTransfer public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function approveAndCall(address _recipient, uint _value, bytes _data) canTransfer public returns (bool) {
    allowed[msg.sender][_recipient] = _value;
    emit ApproveAndCall(msg.sender, _recipient, _value, _data);
    ApproveAndCallFallback(_recipient).receiveApproval(msg.sender, _value, address(this), _data);
    return true;
  }

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(burner, _value);
  }

   
  function enableTransfers() onlyOwner public {
    require(!transferable);
    transferable = true;
    emit TransfersEnabled();
  }

   
  function grantTransferRight(address _to) onlyOwner public {
    require(!transferable);
    require(!transferGrants[_to]);
    require(_to != address(0));
    transferGrants[_to] = true;
    emit TransferRightGiven(_to);
  }

   
  function cancelTransferRight(address _from) onlyOwner public {
    require(!transferable);
    require(transferGrants[_from]);
    transferGrants[_from] = false;
    emit TransferRightCancelled(_from);
  }

   
  function withdrawERC20Tokens(CutdownToken _token) onlyOwner public {
    uint256 totalBalance = _token.balanceOf(address(this));
    require(totalBalance > 0);
    _token.transfer(owner, totalBalance);
    emit WithdrawnERC20Tokens(address(_token), owner, totalBalance);
  }

   
  function withdrawEther() onlyOwner public {
    uint256 totalBalance = address(this).balance;
    require(totalBalance > 0);
    owner.transfer(totalBalance);
    emit WithdrawnEther(owner, totalBalance);
  }
}