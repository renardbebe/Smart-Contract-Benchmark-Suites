 

 

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



contract Distribute is Ownable{

	

	token tokenReward = token(0xdd007278B667F6bef52fD0a4c23604aA1f96039a);



	function register(address[] _addrs) onlyOwner{

		for(uint i = 0; i < _addrs.length; ++i){

			tokenReward.transfer(_addrs[i],5*10**8);

		}

	}



	function withdraw(uint _amount) onlyOwner {

		tokenReward.transfer(owner,_amount);

	}

}