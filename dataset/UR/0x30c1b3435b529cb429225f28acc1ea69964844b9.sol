 

pragma solidity ^0.4.18;

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

contract BookBonus is Ownable {
	ERC20Basic GrrToken;
	
	function BookBonus(address _token) public payable {
 		GrrToken = ERC20Basic(_token);
	}

	function() public payable {}

	function award(address _destination,uint _amountETH, uint _amountToken) public onlyOwner {
		assert(_destination.send(_amountETH));
		assert(GrrToken.transfer(_destination,_amountToken));
	}

}