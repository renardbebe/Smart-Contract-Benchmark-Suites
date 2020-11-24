 

pragma solidity ^0.4.11;

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract SimpleWallet is Ownable {

    function () public payable {
    }

    function weiBalance() public constant returns(uint256) {
        return this.balance;
    }

    function claim(address destination) public onlyOwner {
        destination.transfer(this.balance);
    }

}