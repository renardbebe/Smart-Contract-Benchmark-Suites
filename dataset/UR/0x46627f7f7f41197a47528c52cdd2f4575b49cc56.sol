 

pragma solidity ^0.4.21;


 
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
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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



 

 
contract ERC827 is ERC20 {
  function approveAndCall( address _spender, uint256 _value, bytes _data) public payable returns (bool);
  function transferAndCall( address _to, uint256 _value, bytes _data) public payable returns (bool);
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



 
contract ERC827Token is ERC827, StandardToken {

   
  function approveAndCall(address _spender, uint256 _value, bytes _data) public payable returns (bool) {
    require(_spender != address(this));

    super.approve(_spender, _value);

     
    require(_spender.call.value(msg.value)(_data));

    return true;
  }

   
  function transferAndCall(address _to, uint256 _value, bytes _data) public payable returns (bool) {
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

   
  function increaseApprovalAndCall(address _spender, uint _addedValue, bytes _data) public payable returns (bool) {
    require(_spender != address(this));

    super.increaseApproval(_spender, _addedValue);

     
    require(_spender.call.value(msg.value)(_data));

    return true;
  }

   
  function decreaseApprovalAndCall(address _spender, uint _subtractedValue, bytes _data) public payable returns (bool) {
    require(_spender != address(this));

    super.decreaseApproval(_spender, _subtractedValue);

     
    require(_spender.call.value(msg.value)(_data));

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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}



 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}



 

contract MainframeToken is ERC827Token, Pausable, Claimable {
  string public constant name = "Mainframe Token";
  string public constant symbol = "MFT";
  uint8  public constant decimals = 18;
  address public distributor;

  modifier validDestination(address to) {
    require(to != address(this));
    _;
  }

  modifier isTradeable() {
    require(
      !paused ||
      msg.sender == owner ||
      msg.sender == distributor
    );
    _;
  }

  constructor() public {
    totalSupply_ = 10000000000 ether;  
    balances[msg.sender] = totalSupply_;
    emit Transfer(address(0x0), msg.sender, totalSupply_);
  }

   

  function transfer(address to, uint256 value) public validDestination(to) isTradeable returns (bool) {
    return super.transfer(to, value);
  }

  function transferFrom(address from, address to, uint256 value) public validDestination(to) isTradeable returns (bool) {
    return super.transferFrom(from, to, value);
  }

  function approve(address spender, uint256 value) public isTradeable returns (bool) {
    return super.approve(spender, value);
  }

  function increaseApproval(address spender, uint addedValue) public isTradeable returns (bool) {
    return super.increaseApproval(spender, addedValue);
  }

  function decreaseApproval(address spender, uint subtractedValue) public isTradeable returns (bool) {
    return super.decreaseApproval(spender, subtractedValue);
  }

   

  function transferAndCall(address to, uint256 value, bytes data) public payable isTradeable returns (bool) {
    return super.transferAndCall(to, value, data);
  }

  function transferFromAndCall(address from, address to, uint256 value, bytes data) public payable isTradeable returns (bool) {
    return super.transferFromAndCall(from, to, value, data);
  }

  function approveAndCall(address spender, uint256 value, bytes data) public payable isTradeable returns (bool) {
    return super.approveAndCall(spender, value, data);
  }

  function increaseApprovalAndCall(address spender, uint addedValue, bytes data) public payable isTradeable returns (bool) {
    return super.increaseApprovalAndCall(spender, addedValue, data);
  }

  function decreaseApprovalAndCall(address spender, uint subtractedValue, bytes data) public payable isTradeable returns (bool) {
    return super.decreaseApprovalAndCall(spender, subtractedValue, data);
  }

   

  function setDistributor(address newDistributor) external onlyOwner {
    distributor = newDistributor;
  }

   

  function emergencyERC20Drain(ERC20 token, uint256 amount) external onlyOwner {
     
    token.transfer(owner, amount);
  }
}