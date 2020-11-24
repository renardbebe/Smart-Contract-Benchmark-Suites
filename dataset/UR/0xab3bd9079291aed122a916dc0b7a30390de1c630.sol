 

pragma solidity ^0.5.7;

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

contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

contract HUBRISDISTRIBUTION is Ownable {
  ERC20 public token;

  constructor(ERC20 _token) public {
    token = _token;
  }

  function transfer(address[] memory to, uint256[] memory value) public onlyOwner {
    for(uint256 i = 0; i< to.length; i++) {
        token.transfer(to[i], value[i]);
    }
  }

}