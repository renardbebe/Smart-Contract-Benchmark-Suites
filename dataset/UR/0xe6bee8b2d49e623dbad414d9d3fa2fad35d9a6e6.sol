 

pragma solidity ^0.4.24;

 

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = 0x05C40Def8a40771aA5fd362BCd96e1bb64Ec9044;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Airdrop is Ownable {

  ERC20 public token = ERC20(0x259059f137CB9B8F60AE27Bd199d97aBb69E539B);

  function airdrop(address[] recipient, uint256[] amount) public onlyOwner returns (uint256) {
    uint256 i = 0;
      while (i < recipient.length) {
        token.transfer(recipient[i], amount[i]);
        i += 1;
      }
    return(i);
  }
  
  function airdropSameAmount(address[] recipient, uint256 amount) public onlyOwner returns (uint256) {
    uint256 i = 0;
      while (i < recipient.length) {
        token.transfer(recipient[i], amount);
        i += 1;
      }
    return(i);
  }
}