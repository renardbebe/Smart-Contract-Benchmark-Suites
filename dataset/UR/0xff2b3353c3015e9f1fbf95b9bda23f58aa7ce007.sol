 

pragma solidity ^0.4.23;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract MultiOwnable {
  address public manager;  
  address[] public owners;
  mapping(address => bool) public ownerByAddress;

  event SetOwners(address[] owners);

  modifier onlyOwner() {
    require(ownerByAddress[msg.sender] == true);
    _;
  }

   
  constructor() public {
    manager = msg.sender;
  }

   
  function setOwners(address[] _owners) public {
    require(msg.sender == manager);
    _setOwners(_owners);
  }

  function _setOwners(address[] _owners) internal {
    for(uint256 i = 0; i < owners.length; i++) {
      ownerByAddress[owners[i]] = false;
    }

    for(uint256 j = 0; j < _owners.length; j++) {
      ownerByAddress[_owners[j]] = true;
    }
    owners = _owners;
    emit SetOwners(_owners);
  }

  function getOwners() public view returns (address[]) {
    return owners;
  }
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

 
contract ERC827 is ERC20 {
  function approveAndCall(
    address _spender,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool);

  function transferAndCall(
    address _to,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool);

  function transferFromAndCall(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool);
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

 
contract ERC827Token is ERC827, StandardToken {

   
  function approveAndCall(
    address _spender,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool)
  {
    require(_spender != address(this));

    super.approve(_spender, _value);

     
    require(_spender.call.value(msg.value)(_data));

    return true;
  }

   
  function transferAndCall(
    address _to,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool)
  {
    require(_to != address(this));

    super.transfer(_to, _value);

     
    require(_to.call.value(msg.value)(_data));
    return true;
  }

   
  function transferFromAndCall(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  )
    public payable returns (bool)
  {
    require(_to != address(this));

    super.transferFrom(_from, _to, _value);

     
    require(_to.call.value(msg.value)(_data));
    return true;
  }

   
  function increaseApprovalAndCall(
    address _spender,
    uint _addedValue,
    bytes _data
  )
    public
    payable
    returns (bool)
  {
    require(_spender != address(this));

    super.increaseApproval(_spender, _addedValue);

     
    require(_spender.call.value(msg.value)(_data));

    return true;
  }

   
  function decreaseApprovalAndCall(
    address _spender,
    uint _subtractedValue,
    bytes _data
  )
    public
    payable
    returns (bool)
  {
    require(_spender != address(this));

    super.decreaseApproval(_spender, _subtractedValue);

     
    require(_spender.call.value(msg.value)(_data));

    return true;
  }

}

contract BitScreenerToken is ERC827Token, MultiOwnable {
  string public name = 'BitScreenerToken';
  string public symbol = 'BITX';
  uint8 public decimals = 18;
  uint256 public totalSupply;
  address public owner;

  bool public allowTransfers = false;
  bool public issuanceFinished = false;

  event AllowTransfersChanged(bool _newState);
  event Issue(address indexed _to, uint256 _value);
  event Burn(address indexed _from, uint256 _value);
  event IssuanceFinished();

  modifier transfersAllowed() {
    require(allowTransfers);
    _;
  }

  modifier canIssue() {
    require(!issuanceFinished);
    _;
  }

  constructor(address[] _owners) public {
    _setOwners(_owners);
  }

   
  function setAllowTransfers(bool _allowTransfers) external onlyOwner {
    allowTransfers = _allowTransfers;
    emit AllowTransfersChanged(_allowTransfers);
  }

  function transfer(address _to, uint256 _value) public transfersAllowed returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function transferAndCall(address _to, uint256 _value, bytes _data) public payable transfersAllowed returns (bool) {
    return super.transferAndCall(_to, _value, _data);
  }

  function transferFromAndCall(address _from, address _to, uint256 _value, bytes _data) public payable transfersAllowed returns (bool) {
    return super.transferFromAndCall(_from, _to, _value, _data);
  }

   
  function issue(address _to, uint256 _value) external onlyOwner canIssue returns (bool) {
    totalSupply = totalSupply.add(_value);
    balances[_to] = balances[_to].add(_value);
    emit Issue(_to, _value);
    emit Transfer(address(0), _to, _value);
    return true;
  }

   
  function finishIssuance() public onlyOwner returns (bool) {
    issuanceFinished = true;
    emit IssuanceFinished();
    return true;
  }

   
  function burn(uint256 _value) external {
    require(balances[msg.sender] >= _value);
    totalSupply = totalSupply.sub(_value);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    emit Transfer(msg.sender, address(0), _value);
    emit Burn(msg.sender, _value);
  }
}