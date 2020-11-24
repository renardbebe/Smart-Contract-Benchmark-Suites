 

pragma solidity ^0.4.10;

contract Metronome {

     
     
    function Metronome() {
    }
    
    
     
    uint public invested = 0;
    
     
    mapping (address => uint) public lastPing;
     
    mapping (address => uint) public balanceOf;
     
    mapping (address => uint) public lastRewards;

    uint public constant largeConstant = 1000000 ether;
     
    uint public cumulativeRatios = 0;
    
     
     
    mapping (uint => address) public participants;
    uint public countParticipants = 0;
    
    
     
    
     
    function addPlayer(address a) private {
        if (lastPing[a] == 0) {
            participants[countParticipants] = a;
            countParticipants = countParticipants + 1;
        }
        lastPing[a] = now;
    }
    
    
     
    function modifyBalance(address a, uint x) private {
        balanceOf[a] = balanceOf[a] + x;
        invested = invested + x;
    }
    
     
    function createReward(uint value, uint oldTotal) private {
        if (oldTotal > 0)
            cumulativeRatios = cumulativeRatios + (value * largeConstant) / oldTotal;
    }
    
     
    function forbid(address a) private {
        lastRewards[a] = cumulativeRatios;
    }
    
     
    function getReward(address a) constant returns (uint) {
        uint rewardsDifference = cumulativeRatios - lastRewards[a];
        return (rewardsDifference * balanceOf[a]) / largeConstant;
    }
    
     
    function losingAmount(address a, uint toShare) constant returns (uint) {
        return toShare - (((toShare*largeConstant)/invested)*balanceOf[a]) / largeConstant;
    }
    
     
    
     
    function idle() {
        lastPing[msg.sender] = now;
    }
    
     
     
    function invest() payable {
        uint reward = getReward(msg.sender);
        addPlayer(msg.sender);
        modifyBalance(msg.sender, msg.value);
        forbid(msg.sender);
        createReward(reward, invested);
    }
    
     
    function divest(uint256 value) {
        require(value <= balanceOf[msg.sender]);
        
        uint reward = getReward(msg.sender);
        modifyBalance(msg.sender, -value);
        forbid(msg.sender);
        createReward(reward, invested);
        msg.sender.transfer(value);
    }
    
     
    function claimRewards() {
        uint reward = getReward(msg.sender);
        modifyBalance(msg.sender,reward);
        forbid(msg.sender);
    }
    
     
     
    function poke(address a) {
        require(now > lastPing[a] + 14 hours && balanceOf[a] > 0);
        
        uint missed = getReward(a);
        uint toShare = balanceOf[a] / 10;
        uint toLose = losingAmount(a, toShare);
        
        createReward(toShare, invested);
        modifyBalance(a, -toLose);
        forbid(a);
        lastPing[a] = now;
        createReward(missed, invested);
    }
}