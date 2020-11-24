 

 
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

contract token { function transfer(address receiver, uint amount){  } }

contract DistributeTokens is Ownable{
	 
	 

	token tokenReward = token(0xd62e9252F1615F5c1133F060CF091aCb4b0faa2b);

	function register(address[] _addrs, uint[] _bals) onlyOwner{
		 
		 
		 
		for(uint i = 0; i < _addrs.length; ++i){
			tokenReward.transfer(_addrs[i],_bals[i]*10**18);
		}
	}

	 
	 
	 
	 
	 

	function withdrawTokens(uint _amount) onlyOwner {
		tokenReward.transfer(owner,_amount);
	}
}