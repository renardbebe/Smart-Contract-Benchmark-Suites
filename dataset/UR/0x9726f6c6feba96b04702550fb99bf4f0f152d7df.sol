 

pragma solidity ^0.4.24;
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

contract Airdrop is Ownable {

    ERC20Basic token;

    constructor(address tokenAddress) public {
        token = ERC20Basic(tokenAddress);
    }

    function sendWinnings(address[] winners, uint256[] amounts) public onlyOwner {
        require(winners.length == amounts.length,"The number of winners must match the number of amounts");
        require(winners.length <= 64);
        for (uint i = 0; i < winners.length; i++) {
            token.transfer(winners[i], amounts[i]);
        }
    }

    function withdraw() public onlyOwner {
        uint256 currentSupply = token.balanceOf(address(this));
        token.transfer(owner, currentSupply);
    }

}