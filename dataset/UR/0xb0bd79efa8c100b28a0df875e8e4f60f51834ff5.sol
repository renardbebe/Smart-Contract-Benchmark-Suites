 

pragma solidity ^0.4.24;

 

 
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 
contract HasNoEther is Ownable {

   
  constructor() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

contract PixieTokenAirdropper is Ownable, HasNoEther {

   
  ERC20Basic public token;

  event AirDroppedTokens(uint256 addressCount);
  event AirDrop(address indexed receiver, uint256 total);

   
   
   
  constructor(address _token) public payable {
    require(_token != address(0), "Must be a non-zero address");

    token = ERC20Basic(_token);
  }

  function transfer(address[] _address, uint256[] _values) onlyOwner public {
    require(_address.length == _values.length, "Address array and values array must be same length");

    for (uint i = 0; i < _address.length; i += 1) {
      _transfer(_address[i], _values[i]);
    }

    emit AirDroppedTokens(_address.length);
  }

  function transferSingle(address _address, uint256 _value) onlyOwner public {
    _transfer(_address, _value);

    emit AirDroppedTokens(1);
  }

  function _transfer(address _address, uint256 _value) internal {
    require(_address != address(0), "Address invalid");
    require(_value > 0, "Value invalid");

    token.transfer(_address, _value);

    emit AirDrop(_address, _value);
  }

  function remainingBalance() public view returns (uint256) {
    return token.balanceOf(address(this));
  }

   
  function ownerRecoverTokens(address _beneficiary) external onlyOwner {
    require(_beneficiary != address(0));
    require(_beneficiary != address(token));

    uint256 _tokensRemaining = token.balanceOf(address(this));
    if (_tokensRemaining > 0) {
      token.transfer(_beneficiary, _tokensRemaining);
    }
  }

}