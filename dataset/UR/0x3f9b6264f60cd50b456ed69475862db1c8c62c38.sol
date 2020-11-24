 

pragma solidity 0.4.21;

 

contract RACEFORETH {
     
    uint256 public SCORE_TO_WIN = 1000 finney;
    uint256 PRIZE;
    
     
     
     
    uint256 public speed_limit = 500 finney;
    
     
    mapping (address => uint256) racerScore;
    mapping (address => uint256) racerSpeedLimit;
    
    uint256 latestTimestamp;
    address owner;
    
    function RACEFORETH () public payable {
        PRIZE = msg.value;
        owner = msg.sender;
    }
    
    function race() public payable {
        if (racerSpeedLimit[msg.sender] == 0) { racerSpeedLimit[msg.sender] = speed_limit; }
        require(msg.value <= racerSpeedLimit[msg.sender] && msg.value > 1 wei);
        
        racerScore[msg.sender] += msg.value;
        racerSpeedLimit[msg.sender] = (racerSpeedLimit[msg.sender] / 2);
        
        latestTimestamp = now;
    
         
        if (racerScore[msg.sender] >= SCORE_TO_WIN) {
            msg.sender.transfer(this.balance);
        }
    }
    
    function () public payable {
        race();
    }
    
     
    function endRace() public {
        require(msg.sender == owner);
        require(now > latestTimestamp + 3 days);
        
        msg.sender.transfer(this.balance);
    }
}