 

pragma solidity ^0.4.21;

contract VernamWhiteListDeposit {
	address[] public participants;
	
	address public benecifiary;
	
	mapping (address => bool) public isWhiteList;
	uint256 public constant depositAmount = 10000000000000000 wei;    
	
	uint256 public constant maxWiteList = 9960;					 
	
	uint256 public deadLine;
	uint256 public constant whiteListPeriod = 9 days; 			
	
	constructor() public {
		benecifiary = 0x769ef9759B840690a98244D3D1B0384499A69E4F;
		deadLine = block.timestamp + whiteListPeriod;
	}
	
	event WhiteListSuccess(address indexed _whiteListParticipant, uint256 _amount);
	function() public payable {
		require(participants.length <= maxWiteList);                
		require(block.timestamp <= deadLine);					    
		require(msg.value >= depositAmount);					
		require(!isWhiteList[msg.sender]);							 
		
		benecifiary.transfer(msg.value);							 
		isWhiteList[msg.sender] = true;								 
		participants.push(msg.sender);								 
		emit WhiteListSuccess(msg.sender, msg.value);				 
	}
	
	function getParticipant() public view returns (address[]) {
		return participants;
	}
	
	function getCounter() public view returns(uint256 _counter) {
		return participants.length;
	}
}