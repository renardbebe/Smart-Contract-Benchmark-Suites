 

pragma solidity ^0.4.19;

interface ERC20 {
  function transfer(address to, uint256 value) public returns (bool);
}

 
contract Airdrop {
  address _owner;

  modifier ownerOnly {
    if (_owner == msg.sender) _;
  }

  function Airdrop() public {
    _owner = msg.sender;
  }

  function transferOwnership(address newOwner) public ownerOnly {
    _owner = newOwner;
  }

   
  function drop(address tokenContractAddress, address[] recipients, uint256[] amounts) public ownerOnly {
    require(tokenContractAddress != 0x0);
    require(recipients.length == amounts.length);
    require(recipients.length <= 300);

    ERC20 tokenContract = ERC20(tokenContractAddress);

    for (uint8 i = 0; i < recipients.length; i++) {
      tokenContract.transfer(recipients[i], amounts[i]);
    }
  }
}