 

pragma solidity ^0.5.0;

	 
	
contract TriviaChain {

	 
	address payable public owner;
	
	 
	uint256 public startdate = 1560737700;	
	
	 
	uint256 public enddate = 1560737758;


	 
	int constant question_id = 18;

	 
	bytes correctAnswerHash = bytes('0x1670F2E42FEFA5044D59A65349E47C566009488FC57D7B4376DD5787B59E3C57');  

	
	 
	constructor() public {owner = msg.sender; }

	 
	modifier onlyOwner {
	require (msg.sender == owner);
	_;
	}

	
	 
	
	function() external payable { }
	
	 
	function checkAnswer(string memory answer) private view returns (bool) {
	
	bytes32 answerHash = sha256(abi.encodePacked(answer));
	
	 
	
	if(keccak256(abi.encode(answerHash)) == keccak256(abi.encode(correctAnswerHash)))  {
	return true;
	}
	
	return false;
	
	}
	
	 
	
	function sendEtherToWinner(address payable recipient, uint amount) public payable onlyOwner() {
		recipient.transfer(amount);
	}
	
	 
	function get_startdate() public view  returns (uint256) {
        return startdate;
    }
	
	 
	function get_enddate() public view  returns (uint256) {
        return enddate;
    }
	
	 
	
	function get_Id() public pure  returns (int) {
        return question_id;
    }
	
	function get_answer_hash() public view  returns (string memory) {
        return string(correctAnswerHash);
    }
	
	function getSha256(string memory input) public pure returns (bytes32) {

        bytes32 hash = sha256(abi.encodePacked(input));

        return (hash);
    }
	
}