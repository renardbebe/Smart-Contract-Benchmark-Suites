 

pragma solidity ^0.5.6;

 
contract ERC20Basic {
  uint256 public totalSupply = 99e26;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract VIPToken is ERC20Basic {
  bytes32 public name = "VIP";
  bytes32 public symbol = "VIP";
  uint256 public decimals = 18;
  address private owner = address(0);
  bool private active = false;

  mapping(address => uint256) private balances;

  event OwnershipTransferred(address indexed orgOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
    balances[owner] = totalSupply;
    active = true;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(active);
    require(_to != address(0));
    require(_to != msg.sender);
    require(_value <= balances[msg.sender]);

    uint256 bal = balances[_to] + _value;
    require(bal >= balances[_to]);

    balances[msg.sender] = balances[msg.sender] - _value;
    balances[_to] = bal;

    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 bal) {
    require(active);
    return balances[_owner];
  }

   
  function deactivate() public onlyOwner {
    active = false;
  }

   
  function activate() public onlyOwner {
    active = true;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function kill() public onlyOwner {
    require(!active);
    selfdestruct(msg.sender);
  }
}