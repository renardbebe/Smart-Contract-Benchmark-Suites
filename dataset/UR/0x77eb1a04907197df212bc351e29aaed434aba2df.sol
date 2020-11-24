 

pragma solidity ^0.4.24;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }
}

 
library SafeMath {
   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
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

 
contract DragonAdvisors is Ownable{
  using SafeERC20 for ERC20Basic;
  using SafeMath for uint256;

   
  ERC20Basic public token;

   
  address public advisor;

   
  uint256 public releasedTokens;
  
  event TokenTapAdjusted(uint256 released);

  constructor() public {
    token = ERC20Basic(0x814F67fA286f7572B041D041b1D99b432c9155Ee);
    owner = address(0xA5101498679Fa973c5cF4c391BfF991249934E73);       

    advisor = address(0xd95350D60Bbc601bdfdD8904c336F4faCb9d524c);
    
    releasedTokens = 0;
  }

   
  function release(uint256 _amount) public {
    require(_amount > 0);
    require(releasedTokens >= _amount);
    releasedTokens = releasedTokens.sub(_amount);
    
    uint256 balance = token.balanceOf(this);
    require(balance >= _amount);
    

    token.safeTransfer(advisor, _amount);
  }
  
   
  function transferTokens(address _to, uint256 _amount) external {
    require(_to != address(0x00));
    require(_amount > 0);

    uint256 balance = token.balanceOf(this);
    require(balance >= _amount);

    token.safeTransfer(_to, _amount);
  }
  
  function adjustTap(uint256 _amount) external onlyOwner{
      require(_amount > 0);
      uint256 balance = token.balanceOf(this);
      require(_amount <= balance);
      releasedTokens = _amount;
      emit TokenTapAdjusted(_amount);
  }
  
  function () public payable {
      revert();
  }
}