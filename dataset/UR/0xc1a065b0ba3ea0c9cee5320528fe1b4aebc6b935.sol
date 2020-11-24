 

pragma solidity ^0.4.18;




contract DocumentRegistry {




	mapping(string => uint256) registry;




	function register(string hash) public {
		
		 
		require(registry[hash] == 0);
		
		 
		registry[hash] = block.timestamp;
	}




	function check(string hash) public constant returns (uint256) {
		return registry[hash];
	}
}