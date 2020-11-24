 

pragma solidity ^0.4.17;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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


 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
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

 
contract DKEHedge is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;
   
  uint256 public start;
   
  uint256 public mt;
   
  uint256[] public released = new uint256[](39);

   
  constructor(
    address _beneficiary,
    uint256 _mt
  )
    public
  {
    require(_beneficiary != address(0));
     
    require(_mt >= 100000000);

    beneficiary = _beneficiary;
    mt = _mt;
    start = block.timestamp;
  }

   
  function release(uint16 price) public onlyOwner {
    uint256 idx = getCycleIndex();
     
    require(idx >= 1 && idx <= 39);

     
    uint256 dke = mt.mul(1300).div(39).div(price);
    released[idx.sub(1)] = dke;

    emit Released(dke);
  }

   
  function revoke(uint16 price, ERC20Basic token) public onlyOwner {
    uint256 income = getIncome(price);
    uint256 balance = token.balanceOf(this);
    if (balance <= income) {
      token.safeTransfer(beneficiary, balance);
    } else {
      token.safeTransfer(beneficiary, income);
      token.safeTransfer(owner, balance.sub(income));
    }

    emit Revoked();
  }

   
  function getCycleIndex() public view returns (uint256) {
     
    return block.timestamp.sub(start).div(1800);
  }

   
  function getReleased() public view returns (uint256[]) {
    return released;
  }

   
  function getIncome(uint16 price) public view returns (uint256) {
    uint256 idx = getCycleIndex();
    require(idx >= 39);

    uint256 origin = mt.mul(13).div(100);

    uint256 total = 0;

    for(uint8 i = 0; i < released.length; i++) {
      uint256 item = released[i];
      total = total.add(item);
    }

    uint256 current = total.mul(price).div(10000);
    if (current <= origin) {
      current = origin;
    } else {
      current = current.add(current.sub(origin).mul(5).div(100));
    }

    return current.mul(10000).div(price);
  }
}