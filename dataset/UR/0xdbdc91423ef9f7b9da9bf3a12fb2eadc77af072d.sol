 

pragma solidity ^0.4.13;


contract ERC20Basic {
  uint256 public totalSupply;
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

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract TokenBooksAirdrop is Ownable{
	using SafeMath for uint256;

	mapping (address => uint) public airdropSupplyMap;
	function TokenBooksAirdrop(){
	}


    function withdrawCoinToOwner(address tokenAddress ,uint256 _value) external
		onlyOwner
	{
		processFunding(tokenAddress,msg.sender,_value,1);
	}
	 
    function airdrop(address tokenAddress,address [] _holders,uint256 paySize) external
    	onlyOwner 
	{
		ERC20 token = ERC20(tokenAddress);
        uint256 count = _holders.length;
        assert(paySize.mul(count) <= token.balanceOf(this));
        for (uint256 i = 0; i < count; i++) {
			processFunding(tokenAddress,_holders [i],paySize,1);
			airdropSupplyMap[tokenAddress] = airdropSupplyMap[tokenAddress].add(paySize); 
        }
    }
	function processFunding(address tokenAddress,address receiver,uint256 _value,uint256 _rate) internal
	{
		ERC20 token = ERC20(tokenAddress);
		uint256 amount=_value.mul(_rate);
		require(amount<=token.balanceOf(this));
		if(!token.transfer(receiver,amount)){
			revert();
		}
	}

	
	function etherProceeds() external
		onlyOwner

	{
		if(!msg.sender.send(this.balance)) revert();
	}

}