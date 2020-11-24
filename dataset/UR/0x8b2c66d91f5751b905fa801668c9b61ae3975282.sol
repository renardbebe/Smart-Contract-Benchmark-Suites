 

pragma solidity ^0.4.11;

contract EthTermDeposits{
 mapping(address => uint) public deposits;
 mapping(address => uint) public depositEndTime;
	
	function EthTermDeposits(){

	}
	 
	function Deposit(uint8 numberOfWeeks) payable returns(bool){
		address owner = msg.sender;
		uint amount = msg.value;
		uint _time = block.timestamp + numberOfWeeks * 1 weeks;

		if(deposits[owner] > 0){
			_time = depositEndTime[owner] + numberOfWeeks * 1 weeks;
		}
		depositEndTime[owner] = _time;
		deposits[owner] += amount;
		return true;
	}

	 

	function Withdraw() returns(bool){
		address owner = msg.sender;
		if(depositEndTime[owner] > 0 &&
		   block.timestamp > depositEndTime[owner] &&
		   deposits[owner] > 0){
			uint amount = deposits[owner];
			deposits[owner] = 0;
			msg.sender.transfer(amount);
			return true;
		}else{
			 
			return false;
		}
	}
	function () {
		revert();
	}
}