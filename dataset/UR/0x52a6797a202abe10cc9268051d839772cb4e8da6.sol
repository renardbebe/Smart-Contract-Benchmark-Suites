 

pragma solidity ^0.5.3;

contract JortecCTF {
	
	 
	 
	address winner;
	
	 
	
    modifier checkpointOne(string memory identification) {
         
        require(bytes4(keccak256(bytes(identification))) == hex"ba0bba40");
        _;
    }
    
    modifier checkpointTwo() {
         
        require(bytes1(bytes20(address(this))) == bytes1(bytes20(msg.sender)));
        
        _;
    }  
    
    modifier checkpointThree(int wackyInt) {
         
        if(wackyInt < 0){
            wackyInt = -wackyInt;
        }
        
        require(wackyInt < 0);
        
        _;
    }
	
	 
    
	constructor () public payable {
	    require(msg.value == 0.5 ether);
	}
	
	 

	function winSetup(string memory identification, int wackyInt) public checkpointOne(identification) checkpointTwo checkpointThree(wackyInt) {
		winner = msg.sender;
		
		msg.sender.transfer(address(this).balance);
	}
}