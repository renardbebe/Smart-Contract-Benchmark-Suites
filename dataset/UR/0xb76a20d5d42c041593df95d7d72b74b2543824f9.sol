 

pragma solidity ^0.4.24;


contract ERC20 {
  function transfer(address _recipient, uint256 _value) public returns (bool success);
  function balanceOf(address _owner) external view returns (uint256);
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

contract MultiSend is Ownable {
  function transferMultiple(address _tokenAddress, address[] recipients, uint256[] values) public onlyOwner returns (uint256) {
    ERC20 token = ERC20(_tokenAddress);
    for (uint256 i = 0; i < recipients.length; i++) {
      token.transfer(recipients[i], values[i]);
    }
    return i;
  }

  function emergencyERC20Drain(address _tokenAddress, address recipient) external onlyOwner returns (bool) {
    require(recipient != address(0));
    ERC20 token = ERC20(_tokenAddress);
    require(token.balanceOf(this) > 0);
    return token.transfer(recipient, token.balanceOf(this));
  }
}