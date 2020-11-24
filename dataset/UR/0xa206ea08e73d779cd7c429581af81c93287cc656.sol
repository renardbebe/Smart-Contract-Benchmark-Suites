 

pragma solidity ^0.4.20;

contract hurra {
     
    mapping (address => uint256) public licensesOf;   

    address owner;										 

     
    constructor  (uint256 maxLicenses ) public {
		
        licensesOf[msg.sender] = maxLicenses;               
        owner = msg.sender;                                  
    }

     
	 
    function transfer(address _to, uint256 _value) public returns (bool success) {
		require(msg.sender == owner);                         
        require(licensesOf[msg.sender] >= _value);            
        require(licensesOf[_to] + _value >= licensesOf[_to]);  
        licensesOf[msg.sender] -= _value;                     
        licensesOf[_to] += _value;                            
        return true;
    }
	
     
	 
    function burn(address _from, uint256 _value) public returns (bool success) {
 		require(msg.sender == owner);                         
        require(licensesOf[_from] >= _value);            
        require(licensesOf[msg.sender] + _value >= licensesOf[_from]);  
        licensesOf[msg.sender] += _value;                     
        licensesOf[_from] -= _value;                            
        return true;
    }
	
	function deleteThisContract() public {
		require(msg.sender == owner);                         
		selfdestruct(msg.sender);								 
																 
	}
	
	
	
}