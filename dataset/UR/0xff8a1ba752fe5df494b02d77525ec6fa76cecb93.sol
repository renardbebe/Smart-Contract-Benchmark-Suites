 

pragma solidity ^0.4.15;

contract ERC20 {

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
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

  function Ownable() {
    owner = msg.sender;
  }

  function transferOwnership(address newOwner) onlyOwner {
    pendingOwner = newOwner;
  }

  function claimOwnership() onlyPendingOwner {
    owner = pendingOwner;
  }
}

contract Destructible is Ownable {

  function destroy() onlyOwner {
    selfdestruct(msg.sender);
  }
}

contract WithClaim {
    
    event Claim(string data);
}

 
 
 
 

contract UserfeedsClaimWithoutValueTransfer is Destructible, WithClaim {

  function post(string data) {
    Claim(data);
  }
}

 
 
 
 

contract UserfeedsClaimWithValueTransfer is Destructible, WithClaim {

  function post(address userfeed, string data) payable {
    userfeed.transfer(msg.value);
    Claim(data);
  }
}

 
 
 
 

contract UserfeedsClaimWithTokenTransfer is Destructible, WithClaim {

  function post(address userfeed, address token, uint value, string data) {
    var erc20 = ERC20(token);
    require(erc20.transferFrom(msg.sender, userfeed, value));
    Claim(data);
  }
}