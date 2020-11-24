 

pragma solidity 0.4.15;

contract owned {
    
    address public owner;
    
    event ContractOwnershipTransferred(address newOwner);
    
    function owned() { owner = msg.sender; }
    
    modifier onlyOwner { 
        require(msg.sender == owner); 
        _; 
    }
    
    function setContractOwner(address newOwner) external onlyOwner  {
        owner = newOwner;
        ContractOwnershipTransferred(newOwner);
    }
}

 
 
 
 
 
 
 
 
 
 
 
 
 
contract Cillionaire is owned {
    
    enum State { ENDED, PARTICIPATION, CHOOSE_WINNER, REFUND }

     
    uint public potTarget;
     
    uint public stake;
     
    uint public fee;
    
    State public state;
    address[] public participants;
    bytes32 public ownerRandomHash;
    uint public minerRandomNumber;
    uint public ownerRandomNumber;
    uint public participationEndTimestamp;
    uint public pot;
    address public winner;
    mapping (address => uint) public funds;
    uint public fees;
    uint public lastRefundedIndex;
    
    event StateChange(State newState);
    event NewParticipant(address participant, uint total, uint stakeAfterFee, uint refundNow);
    event MinerRandomNumber(uint number);
    event OwnerRandomNumber(uint number);
    event RandomNumber(uint randomNumber);
    event WinnerIndex(uint winnerIndex);
    event Winner(address _winner, uint amount);
    event Refund(address participant, uint amount);
    event Cancelled(address cancelledBy);
    event ParametersChanged(uint newPotTarget, uint newStake, uint newFee);
    
    modifier onlyState(State _state) { 
        require(state == _state); 
        _; 
    }
    
     
     
     
     
     
     
     
    modifier costs(uint _amount) {
        require(msg.value >= _amount);
        _;
        if (msg.value > _amount) {
            msg.sender.transfer(msg.value - _amount);
        }
    }
    
    function Cillionaire() {
        state = State.ENDED;
        potTarget = 0.1 ether;
        stake = 0.05 ether;
        fee = 0;
    }
    
    function setState(State _state) internal {
        state = _state;
        StateChange(state);
    }
    
     
     
     
    function start(bytes32 _ownerRandomHash) external onlyOwner onlyState(State.ENDED) {
        ownerRandomHash = _ownerRandomHash;
        minerRandomNumber = 0;
        ownerRandomNumber = 0;
        participationEndTimestamp = 0;
        winner = 0;
        pot = 0;
        lastRefundedIndex = 0;
        delete participants;
        setState(State.PARTICIPATION);
    }
    
     
     
     
     
    function participate() external payable onlyState(State.PARTICIPATION) costs(stake) {
        participants.push(msg.sender);
        uint stakeAfterFee = stake - fee;
        pot += stakeAfterFee;
        fees += fee;
        NewParticipant(msg.sender, msg.value, stakeAfterFee, msg.value - stake);
        if (pot >= potTarget) {
            participationEndTimestamp = block.timestamp;
            minerRandomNumber = block.timestamp;
            MinerRandomNumber(minerRandomNumber);
            setState(State.CHOOSE_WINNER);
        }
    }
    
     
     
     
    function chooseWinner(string _ownerRandomNumber, string _ownerRandomSecret) external onlyOwner onlyState(State.CHOOSE_WINNER) {
        require(keccak256(_ownerRandomNumber, _ownerRandomSecret) == ownerRandomHash);
        require(!startsWithDigit(_ownerRandomSecret));  
        ownerRandomNumber = parseInt(_ownerRandomNumber);
        OwnerRandomNumber(ownerRandomNumber);
        uint randomNumber = ownerRandomNumber ^ minerRandomNumber;
        RandomNumber(randomNumber);
        uint winnerIndex = randomNumber % participants.length;
        WinnerIndex(winnerIndex);
        winner = participants[winnerIndex];
        funds[winner] += pot;
        Winner(winner, pot);
        setState(State.ENDED);
    }
    
     
     
     
     
    function cancel() external {
        if (msg.sender == owner) {
            require(state == State.PARTICIPATION || state == State.CHOOSE_WINNER);
        } else {
            require((state == State.CHOOSE_WINNER) && (participationEndTimestamp != 0) && (block.timestamp > participationEndTimestamp + 1 days));
        }
        Cancelled(msg.sender);
         
        if (participants.length > 0) {
            funds[participants[0]] += stake;
            fees -= fee;
            lastRefundedIndex = 0;
            Refund(participants[0], stake);
            if (participants.length == 1) {
                setState(State.ENDED);
            } else {
                setState(State.REFUND);
            }
        } else {
             
            setState(State.ENDED);
        }
    }
    
     
     
     
     
    function refund(uint _count) onlyState(State.REFUND) {
        require(participants.length > 0);
        uint first = lastRefundedIndex + 1;
        uint last = lastRefundedIndex + _count;
        if (last > participants.length - 1) {
            last = participants.length - 1;
        }
        for (uint i = first; i <= last; i++) {
            funds[participants[i]] += stake;
            fees -= fee;
            Refund(participants[i], stake);
        }
        lastRefundedIndex = last;
        if (lastRefundedIndex >= participants.length - 1) {
            setState(State.ENDED);
        }
    }

     
     
    function withdraw() external {
        uint amount = funds[msg.sender];
        funds[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
    
     
     
    function withdrawFees() external onlyOwner onlyState(State.ENDED) {
        uint amount = fees;
        fees = 0;
        msg.sender.transfer(amount);
    }
    
     
     
    function setParams(uint _potTarget, uint _stake, uint _fee) external onlyOwner onlyState(State.ENDED) {
        require(_fee < _stake);
        potTarget = _potTarget;
        stake = _stake; 
        fee = _fee;
        ParametersChanged(potTarget, stake, fee);
    }
    
    function startsWithDigit(string str) internal returns (bool) {
        bytes memory b = bytes(str);
        return b[0] >= 48 && b[0] <= 57;  
    }
    
     
     
     
     
    function parseInt(string _a) internal returns (uint) {
        return parseInt(_a, 0);
    }

     
     
     
     
    function parseInt(string _a, uint _b) internal returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i=0; i<bresult.length; i++){
            if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
                if (decimals){
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) mint *= 10**_b;
        return mint;
    }

}