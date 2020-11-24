 

 

pragma solidity ^0.4.23;

contract ERC20 {

  function transferFrom(address from, address to, uint value) public returns (bool success);
}

contract ERC721 {

  function transferFrom(address from, address to, uint value) public;
}

contract Ownable {

  address owner;
  address pendingOwner;

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  modifier onlyPendingOwner {
    require(msg.sender == pendingOwner);
    _;
  }

  constructor() public {
    owner = msg.sender;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

  function claimOwnership() public onlyPendingOwner {
    owner = pendingOwner;
  }
}

contract Destructible is Ownable {

  function destroy() public onlyOwner {
    selfdestruct(msg.sender);
  }
}

contract WithClaim {

  event Claim(string data);
}

 
 
 
 
 

contract UserfeedsClaimWithoutValueTransfer is Destructible, WithClaim {

  function post(string data) public {
    emit Claim(data);
  }
}

 
 
 
 
 

contract UserfeedsClaimWithValueTransfer is Destructible, WithClaim {

  function post(address userfeed, string data) public payable {
    emit Claim(data);
    userfeed.transfer(msg.value);
  }
}

 
 
 
 
 

contract UserfeedsClaimWithTokenTransfer is Destructible, WithClaim {

  function post(address userfeed, ERC20 token, uint value, string data) public {
    emit Claim(data);
    require(token.transferFrom(msg.sender, userfeed, value));
  }
}

 
 
 

contract UserfeedsClaimWithValueMultiSendUnsafe is Destructible, WithClaim {

  function post(string data, address[] recipients) public payable {
    emit Claim(data);
    send(recipients);
  }

  function post(string data, bytes20[] recipients) public payable {
    emit Claim(data);
    send(recipients);
  }

  function send(address[] recipients) public payable {
    uint amount = msg.value / recipients.length;
    for (uint i = 0; i < recipients.length; i++) {
      recipients[i].send(amount);
    }
    msg.sender.transfer(address(this).balance);
  }

  function send(bytes20[] recipients) public payable {
    uint amount = msg.value / recipients.length;
    for (uint i = 0; i < recipients.length; i++) {
      address(recipients[i]).send(amount);
    }
    msg.sender.transfer(address(this).balance);
  }
}

 
 
 
 

contract UserfeedsClaimWithConfigurableValueMultiTransfer is Destructible, WithClaim {

  function post(string data, address[] recipients, uint[] values) public payable {
    emit Claim(data);
    transfer(recipients, values);
  }

  function transfer(address[] recipients, uint[] values) public payable {
    for (uint i = 0; i < recipients.length; i++) {
      recipients[i].transfer(values[i]);
    }
    msg.sender.transfer(address(this).balance);
  }
}

 
 
 
 

contract UserfeedsClaimWithConfigurableTokenMultiTransfer is Destructible, WithClaim {

  function post(string data, address[] recipients, ERC20 token, uint[] values) public {
    emit Claim(data);
    transfer(recipients, token, values);
  }

  function transfer(address[] recipients, ERC20 token, uint[] values) public {
    for (uint i = 0; i < recipients.length; i++) {
      require(token.transferFrom(msg.sender, recipients[i], values[i]));
    }
  }
}

 
 
 

contract UserfeedsClaimWithConfigurableTokenMultiTransferNoCheck is Destructible, WithClaim {

  function post(string data, address[] recipients, ERC721 token, uint[] values) public {
    emit Claim(data);
    transfer(recipients, token, values);
  }

  function transfer(address[] recipients, ERC721 token, uint[] values) public {
    for (uint i = 0; i < recipients.length; i++) {
      token.transferFrom(msg.sender, recipients[i], values[i]);
    }
  }
}