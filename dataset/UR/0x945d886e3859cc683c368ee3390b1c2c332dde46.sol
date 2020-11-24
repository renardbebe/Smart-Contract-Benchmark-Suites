 

pragma solidity ^0.4.21;

contract MultiTransfer {
  event Transacted(
    address msgSender,  
    address toAddress,  
    uint value  
  );

 
  function multiTransfer(
      address _from, address[] _to, uint[] _amount
  ) public payable {

    require(msg.sender == _from);
    
    require(_to.length == _amount.length);

    uint256 ui;
    uint256 amountSum = 0;

    for (ui = 0; ui < _to.length; ui++) {
        require(_to[ui] != address(0));

        amountSum = amountSum + _amount[ui];
    }

    require(amountSum == msg.value);

    for (ui = 0; ui < _to.length; ui++) {
        _to[ui].transfer(_amount[ui]);        
    
        emit Transacted(msg.sender, _to[ui], _amount[ui]);
    }

    return;
  }
}