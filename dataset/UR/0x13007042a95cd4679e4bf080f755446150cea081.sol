 

pragma solidity ^0.4.25;

contract subsetSum {
     

     
    struct Number {
        bool exists;
        bool isUsed;
    }
    struct Leader {
        address id;
        uint256 difference;
        uint256[] negativeSet;
        uint256[] positiveSet;
    }

     
    uint256[] numbers;
    mapping (uint256 => Number) numberCheck;
    mapping (address => bool) authorisedEntrants;
    uint256 expiryTime;
    address admin;
    Leader leader;

     
    constructor (uint256[] memory setElements, uint256 expiry) public {
        require(setElements.length>0 && expiry > now, 'Invalid parameters');
        numbers = setElements;
        for (uint256 i = 0; i<setElements.length; i++) {
            numberCheck[setElements[i]].exists=true;
        }
        expiryTime = expiry;
        admin = msg.sender;
    }

     
    event RunnerUpSubmission(address indexed submitter, uint256 submitterSolutionDifference);
    event NewRecord(address indexed newRecordHolder, uint256 newRecordDifference);

     
    modifier adminOnly {
        require(msg.sender==admin, 'This requires admin privileges');
        _;
    }

     
    modifier restrictedAccess {
        require(now<expiryTime && authorisedEntrants[msg.sender], 'Unauthorised entrant');
        _;
    }

     
     
     
     
    modifier winnerOnly {
        require(now>expiryTime && (msg.sender==leader.id || ((address(0)==leader.id || now>expiryTime+2629746) && msg.sender==admin)), "You don't have permission to withdraw the prize");
        _;
    }

     
    function getNumbers() public view returns(uint256[] numberSet) {
        return numbers;
    }

     
    function getRecord() public view returns (address winningAddress, uint256 difference, uint256[] negativeSet, uint256[] positiveSet) {
        return (leader.id, leader.difference, leader.negativeSet, leader.positiveSet);
    }

     
    function getPrizePot() public view returns (uint256 prizeFundAmount) {
        return address(this).balance;
    }

     
    function getExpiryDate() public view returns (uint256 expiryTimestamp) {
        return expiryTime;
    }
    
     
    function getData() public view returns(uint256[] numberSet, address winningAddress, uint256 prizeFundAmount, uint256 expiryTimestamp) {
        return (numbers, leader.id, address(this).balance, expiryTime);
    }

     
    function () public payable {    }

     
    function getAuthor() public pure returns (string authorName) {
      return "Written by Ciarán Ó hAoláin, Maynooth University 2018";
    }

     
    function authoriseEntrants(address[] addressesToAuthorise) public adminOnly {
        for (uint256 i = 0; i<addressesToAuthorise.length; i++) authorisedEntrants[addressesToAuthorise[i]]=true;
    }

     
    function submitAnswer(uint256[] negativeSetSubmission, uint256[] positiveSetSubmission) public restrictedAccess returns (string response) {
        require(negativeSetSubmission.length+positiveSetSubmission.length>0, 'Invalid submission.');
        uint256 sumNegative = 0;
        uint256 sumPositive = 0;
         
        for (uint256 i = 0; i<negativeSetSubmission.length; i++) {
            require(numberCheck[negativeSetSubmission[i]].exists && !numberCheck[negativeSetSubmission[i]].isUsed, 'Invalid submission.');
            sumNegative+=negativeSetSubmission[i];
            numberCheck[negativeSetSubmission[i]].isUsed = true;
        }
        for (i = 0; i<positiveSetSubmission.length; i++) {
            require(numberCheck[positiveSetSubmission[i]].exists && !numberCheck[positiveSetSubmission[i]].isUsed, 'Invalid submission.');
            sumPositive+=positiveSetSubmission[i];
            numberCheck[positiveSetSubmission[i]].isUsed = true;
        }
         
        for (i = 0; i<negativeSetSubmission.length; i++) numberCheck[negativeSetSubmission[i]].isUsed = false;
        for (i = 0; i<positiveSetSubmission.length; i++) numberCheck[positiveSetSubmission[i]].isUsed = false;
         
        uint256 difference = _diff(sumNegative, sumPositive);
        if (leader.id==address(0) || difference<leader.difference) {
            leader.id = msg.sender;
            leader.difference=difference;
            leader.negativeSet=negativeSetSubmission;
            leader.positiveSet=positiveSetSubmission;
            emit NewRecord(msg.sender, difference);
            return "Congratulations, you are now on the top of the leaderboard.";
        } else {
            emit RunnerUpSubmission(msg.sender, difference);
            return "Sorry, you haven't beaten the record.";
        }
    }

     
    function withdrawPrize(address prizeRecipient) public winnerOnly {
        prizeRecipient.transfer(address(this).balance);
    }

     
    function _diff(uint256 a, uint256 b) private pure returns (uint256 difference) {
        if (a>b) return a-b;
        else return b-a;
    }

}