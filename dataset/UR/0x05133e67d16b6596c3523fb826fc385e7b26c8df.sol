 

pragma solidity ^0.4.24;
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}
contract Sweepstake {
    uint constant MAX_CANDIDATES = 100;

    struct Candidate {
        uint votes;
        uint balance;
        address[] entrants;
    }
    
    struct Entrant {
        uint[] candidateVotes;
        address sender;
        bool paid;
    }

    address internal owner;
    bool internal ownerCanTerminate;
    uint internal ticketValue;
    uint internal feePerTicket;
    uint internal withdrawalAfterClosureWindowInDays;

    Candidate[] internal candidates;
    mapping(address => Entrant) internal entrants;
    uint internal totalVotes;
    uint internal totalBalance;

    bool internal closed;
    uint internal closedTime;

    uint internal winningCandidateIndex;
    uint internal winningVotes;
    uint internal winningsPerVote;

    modifier onlyOwner { 
        require (msg.sender == owner, 'Must be owner');
        _; 
    }
             
    modifier onlyWhenOpen { 
        require (closed == false, 'Cannot execute whilst open');
        _; 
    }
            
    modifier onlyWhenClosed { 
        require (closed == true, 'Cannot execute whilst closed');
        _; 
    }

    modifier onlyWithValidCandidate(uint candidateIndex) { 
        require (candidateIndex >= 0, 'Index must be valid');
        require (candidateIndex < candidates.length, 'Index must be valid');
        _; 
    }
                
    constructor(
        uint _ticketValue,
        uint _feePerTicket,
        uint candidateCount,
        uint _withdrawalAfterClosureWindowInDays
    ) public {
        require (candidateCount > 0, 'Candidate count must be more than 1');
        require (candidateCount <= MAX_CANDIDATES, 'Candidate count must be less than max');

        owner = msg.sender;
        ownerCanTerminate = true;
        ticketValue = _ticketValue;
        feePerTicket = _feePerTicket;
        withdrawalAfterClosureWindowInDays = _withdrawalAfterClosureWindowInDays;

        for (uint index = 0; index < candidateCount; index++) {
            candidates.push(Candidate({
                votes: 0,
                balance: 0,
                entrants: new address[](0)
            }));
        }
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getOwnerCanTerminate() external view returns (bool) {
        return ownerCanTerminate;
    }

    function getClosed() external view returns (bool) {
        return closed;
    }

    function getClosedTime() external view returns (uint) {
        return closedTime;
    }

    function getWithdrawalAfterClosureWindowInDays() external view returns (uint) {
        return withdrawalAfterClosureWindowInDays;
    }

    function getFeePerTicket() external view returns (uint) {
        return feePerTicket;
    }

    function getTicketValue() external view returns (uint) {
        return ticketValue;
    }

    function getAllCandidateBalances() external view returns (uint[]) {
        uint candidateLength = candidates.length;
        uint[] memory balances = new uint[](candidateLength);
        
        for (uint index = 0; index < candidateLength; index++) {
            balances[index] = candidates[index].balance;
        }

        return balances;
    }

    function getAllCandidateVotes() external view returns (uint[]) {
        uint candidateLength = candidates.length;
        uint[] memory votes = new uint[](candidateLength);
        
        for (uint index = 0; index < candidateLength; index++) {
            votes[index] = candidates[index].votes;
        }

        return votes;
    }

    function getCandidateEntrants(uint candidateIndex) external view onlyWithValidCandidate(candidateIndex) returns (address[]) {
        return candidates[candidateIndex].entrants;
    }

    function getTotalVotes() external view returns (uint) {
        return totalVotes;
    }

    function getTotalBalance() external view returns (uint) {
        return totalBalance;
    }

    function getWinningCandidateIndex() external view onlyWhenClosed returns (uint) {
        return winningCandidateIndex;
    }

    function getWinningVotes() external view onlyWhenClosed returns (uint) {
        return winningVotes;
    }

    function getWinningsPerVote() external view onlyWhenClosed returns (uint) {
        return winningsPerVote;
    }

    function hasCurrentUserEntered() external view returns (bool) {
        return entrants[msg.sender].sender != 0x0;
    }

    function getCurrentEntrantVotes() external view returns (uint[]) {
        require (entrants[msg.sender].sender != 0x0, 'Current user has not entered');

        return entrants[msg.sender].candidateVotes;
    }

    function getCurrentEntrantPaidState() external view returns (bool) {
        require (entrants[msg.sender].sender != 0x0, 'Current user has not entered');

        return entrants[msg.sender].paid;
    }

    function getCurrentEntrantWinnings() external view onlyWhenClosed returns (uint) {
        require (entrants[msg.sender].sender != 0x0, 'Current user has not entered');
        require (entrants[msg.sender].candidateVotes[winningCandidateIndex] > 0, 'Current user did not vote for the winner');

        return SafeMath.mul(winningsPerVote, entrants[msg.sender].candidateVotes[winningCandidateIndex]);
    }

    function enter(uint candidateIndex) external payable onlyWhenOpen onlyWithValidCandidate(candidateIndex) {
        require (msg.value == ticketValue, 'Ticket value is incorrect');

        if (entrants[msg.sender].sender == 0x0) {
            entrants[msg.sender] = Entrant({
                candidateVotes: new uint[](candidates.length),
                sender: msg.sender,
                paid: false
            });

            candidates[candidateIndex].entrants.push(msg.sender);
        }

        entrants[msg.sender].candidateVotes[candidateIndex]++;

        totalVotes++;
        candidates[candidateIndex].votes++;
        
        uint valueAfterFee = SafeMath.sub(msg.value, feePerTicket);
        candidates[candidateIndex].balance = SafeMath.add(candidates[candidateIndex].balance, valueAfterFee);

        totalBalance = SafeMath.add(totalBalance, valueAfterFee);

        owner.transfer(feePerTicket);
    }

    function close(uint _winningCandidateIndex) external onlyOwner onlyWhenOpen onlyWithValidCandidate(_winningCandidateIndex) {
        closed = true;
        closedTime = now;

        winningCandidateIndex = _winningCandidateIndex;

        uint balance = address(this).balance;
        winningVotes = candidates[winningCandidateIndex].votes;
        if (winningVotes > 0) {    
            winningsPerVote = SafeMath.div(balance, winningVotes);
            uint totalWinnings = SafeMath.mul(winningsPerVote, winningVotes);

            if (totalWinnings < balance) {
                owner.transfer(SafeMath.sub(balance, totalWinnings));
            }
        } else {
            owner.transfer(balance);
        }
    }

    function withdraw() external onlyWhenClosed {
        require (entrants[msg.sender].sender != 0x0, 'Current user has not entered');
        require (entrants[msg.sender].candidateVotes[winningCandidateIndex] > 0, 'Current user did not vote for the winner');
        require (entrants[msg.sender].paid == false, 'User has already been paid');
        require (now < (closedTime + (withdrawalAfterClosureWindowInDays * 1 days)));
        
        entrants[msg.sender].paid = true;

        uint totalWinnings = SafeMath.mul(winningsPerVote, entrants[msg.sender].candidateVotes[winningCandidateIndex]);

        msg.sender.transfer(totalWinnings);
    }

    function preventOwnerTerminating() external onlyOwner {
        ownerCanTerminate = false;
    }

    function terminate() external onlyOwner {
        require (ownerCanTerminate == true, 'Owner cannot terminate');

        selfdestruct(owner);
    }
}