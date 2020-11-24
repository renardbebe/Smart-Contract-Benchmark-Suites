 

pragma solidity 0.4.25;

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract StockShares is Ownable {
    event Transfer(address indexed fromAddress, uint256 value);
    event Withdraw(address indexed toAddress, uint256 value);
    
    function () payable public {
        require(msg.value > 0);
        require(msg.sender != address(0));
        emit Transfer(msg.sender, msg.value);
    }
    
    function withdraw (address toAddress, uint256 amount) onlyOwner public  {
        require(amount > 0);
        require(address(this).balance >= amount);
        require(toAddress != address(0));
        toAddress.transfer(amount);
        emit Withdraw(toAddress, amount);
    }
    
}