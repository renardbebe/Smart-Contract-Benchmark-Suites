 

pragma solidity ^0.4.24;

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
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

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract TokenHolder is Ownable {
    using SafeMath for uint;

    event Released(uint amount);

     
    uint public start;
     
    uint public vestingInterval;
     
    uint public released;
     
    uint public value;
     
    ERC20Basic public token;

    constructor(uint _start, uint _vestingInterval, uint _value, ERC20Basic _token) public {
        start = _start;
        vestingInterval = _vestingInterval;
        value = _value;
        token = _token;
    }

     
    function release() onlyOwner public {
        uint toRelease = calculateVestedAmount().sub(released);
        uint left = token.balanceOf(this);
        if (left < toRelease) {
            toRelease = left;
        }
        require(toRelease > 0, "nothing to release");
        released = released.add(toRelease);
        require(token.transfer(msg.sender, toRelease));
        emit Released(toRelease);
    }

    function calculateVestedAmount() view internal returns (uint) {
        return now.sub(start).div(vestingInterval).mul(value);
    }
}