 

pragma solidity ^0.4.21;

contract ERC20Interface {
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
}

contract MultiTransfer {
  event Deposited(address from, uint value, bytes data);
  event Transacted(
    address msgSender,  
    address toAddress,  
    uint value  
  );

 
  function() public payable {
    if (msg.value > 0) {
      emit Deposited(msg.sender, msg.value, msg.data);
    }
  }

 
  function multiTransferETH(
      address fromAddress,
      address toAddress1,
      address toAddress2,
      uint value1,
      uint value2
  ) public payable {
    if (msg.sender != fromAddress) {
        revert();
    }

    if (msg.value != value1 + value2) {
        revert();
    }

    toAddress1.transfer(value1);
    toAddress2.transfer(value2);
    
    emit Transacted(msg.sender, toAddress1, value1);
    emit Transacted(msg.sender, toAddress2, value2);
  }
  
 
  function multiTransferToken(
      address fromAddress,
      address toAddress1,
      address toAddress2,
      uint value1,
      uint value2,
      address tokenContractAddress
  ) public payable {
    ERC20Interface instance = ERC20Interface(tokenContractAddress);
    
    if (instance.allowance(fromAddress, msg.sender) != value1 + value2) {
        revert();
    }

    instance.transferFrom(fromAddress, toAddress1, value1);
    instance.transferFrom(fromAddress, toAddress2, value2);
    
    emit Transacted(fromAddress, toAddress1, value1);
    emit Transacted(fromAddress, toAddress2, value2);
  }
  
}