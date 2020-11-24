 

pragma solidity ^0.4.11;
contract MinerShare {
	 
	address public owner = 0x0;
	 
	uint public totalWithdrew = 0;
	 
	uint public userNumber = 0;
	 
	event LogAddUser(address newUser);
	 
	event LogRmUser(address rmUser);
	 
	event LogWithdrew(address sender, uint amount);
	 
	mapping(address => uint) public usersAddress;
	 
	mapping(address => uint) public usersWithdrew;

	modifier onlyOwner() {
		require(owner == msg.sender);
		_;
	}

	modifier onlyMember() {
		require(usersAddress[msg.sender] != 0);
		_;
	}

	 
	function MinerShare() {
		owner = msg.sender;
	}

	 
	function AddUser(address newUser) onlyOwner{
		if (usersAddress[newUser] == 0) {
			usersAddress[newUser] = 1;
			userNumber += 1;
			LogAddUser(newUser);
		}
	}

	 
	function RemoveUser(address rmUser) onlyOwner {
		if (usersAddress[rmUser] == 1) {
			usersAddress[rmUser] = 0;
			userNumber -= 1;
			LogRmUser(rmUser);
		}
	}

	 
	function Withdrew() onlyMember {
		 
		uint totalMined = this.balance + totalWithdrew;
		 
		uint avaliableWithdrew = totalMined/userNumber - usersWithdrew[msg.sender];
		 
		usersWithdrew[msg.sender] += avaliableWithdrew;
		 
		totalWithdrew += avaliableWithdrew;
		 
		if (avaliableWithdrew > 0) {
			 
			msg.sender.transfer(avaliableWithdrew);
			LogWithdrew(msg.sender, avaliableWithdrew);
		} else
			throw;
	}

	 
	function () payable {}
}