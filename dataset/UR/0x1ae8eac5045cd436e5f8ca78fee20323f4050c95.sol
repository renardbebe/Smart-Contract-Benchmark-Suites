 

pragma solidity 0.4.25;

contract AlarmClock {

    event _newAlarmClock(address _contract, uint startBlock, uint blockWindow, uint reward, uint gas, bytes _callData);
    
    address public owner;
     
    uint public totalTimers;
    uint public waitingTimers;
    
    struct ClockStruct {
        address _contract;
        uint startBlock;
        uint blockWindow;
        uint reward;
        uint gas;
        bytes callData;
    }
    
     
     
     
    
     
    
    ClockStruct[] public clockList;
  
    constructor () public payable {
        owner = msg.sender;
         
        totalTimers = 0;
        waitingTimers = 0;
    }  
  
    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }  
  
     
    function setNewOwner(address _newOwner) public ownerOnly {
        owner = _newOwner;
    }   
  
      
  
     
    function registerAlarmClock(address _contract, uint startBlock, uint blockWindow, uint gas, bytes  _callData) external payable {
        
        require(gas >= 200000);
        require(msg.value > gas);
        require(block.number < startBlock);
        
        clockList.push(ClockStruct(_contract, startBlock, blockWindow, msg.value - gas, gas, _callData));
         
         
         
         
        
        totalTimers++;
        waitingTimers++;
        
        emit _newAlarmClock(_contract, startBlock, blockWindow, msg.value - gas, gas, _callData);
    }  
  
	 
    function trigerAlarmClock(uint id) external payable {
        
        uint _reward;
        
        require(clockList[id].reward > 0);
        require(block.number >= clockList[id].startBlock);
        require(block.number < (clockList[id].startBlock + clockList[id].blockWindow));
        
        require(clockList[id]._contract.call.value(0).gas(clockList[id].gas)(clockList[id].callData));
        
        waitingTimers--; 
        _reward = clockList[id].reward;
        clockList[id].reward = 0;
        
        msg.sender.transfer(_reward);
        
    }  
  
     
    function() external payable {
         
    }   
    
    function _destroyContract() external ownerOnly {
        selfdestruct(msg.sender);
    }    
  
}