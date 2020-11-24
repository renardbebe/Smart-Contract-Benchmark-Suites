 

pragma solidity ^0.5.1;

 
contract IBMapping {
	mapping(string => address) private ContractAddress;						 
	mapping (address => bool) owners;										 

	 
	constructor () public {
		owners[msg.sender] = true;
	}
	
     
	function checkAddress(string memory name) public view returns (address contractAddress) {
		return ContractAddress[name];
	}
	
     
	function addContractAddress(string memory name, address contractAddress) public {
		require(checkOwners(msg.sender) == true);
		ContractAddress[name] = contractAddress;
	}
	
	 
	function addSuperMan(address superMan) public {
	    require(checkOwners(msg.sender) == true);
	    owners[superMan] = true;
	}
	
	 
	function deleteSuperMan(address superMan) public {
	    require(checkOwners(msg.sender) == true);
	    owners[superMan] = false;
	}
	
	 
	function checkOwners(address man) public view returns (bool){
	    return owners[man];
	}
}