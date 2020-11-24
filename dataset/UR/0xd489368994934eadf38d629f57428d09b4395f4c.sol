 
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
    if (msg.value != value1 + value2) {
        revert();
    }
      
    ERC20Interface instance = ERC20Interface(tokenContractAddress);

    instance.approve(fromAddress, value1 + value2);  

    instance.transferFrom(fromAddress, toAddress1, value1);
    instance.transferFrom(fromAddress, toAddress2, value2);
    
    emit Transacted(fromAddress, toAddress1, value1);
    emit Transacted(fromAddress, toAddress2, value2);
  }
  
}
