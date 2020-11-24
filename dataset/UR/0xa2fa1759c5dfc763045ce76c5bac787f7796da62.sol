 

pragma solidity ^0.4.24;

 

contract XKnockoutWhale2 {
    
  using SafeMath for uint256;

  struct EntityStruct {
    bool active;
    bool vip;
    uint listPointer;
    uint256 date;
    uint256 update;
    uint256 exit;
    uint256 profit;
  }
  
  mapping(address => EntityStruct) public entityStructs;
  address[] public entityList;
  address[] public vipList;
  address dev;
  uint256 base = 3000000000000000000;  
  uint256 public startedAt = now;  
  uint256 public timeRemaining = 24 hours;  
  uint256 public devreward;  
  uint public round = 1;  
  uint public shift = 0;  
  uint public joined = 0;  
  uint public exited = 0;  
  bool public timetoRegular = true;  
  
  constructor() public {
     dev = msg.sender;
  }
  
  function() public payable {
    if(!checkRemaining()) { 
        if(msg.value == base) {
            addToList();
        } else if(msg.value == base.div(10)) {
            up();
        } else {
            revert("Send 3 ETH to join the list or 0.3 ETH to up");
        }   
    }
  }
  
  function addToList() internal {
      if(entityStructs[msg.sender].active) revert("You are already in the list");
      
      newEntity(msg.sender, true);
      joined++;
	  startedAt = now;
      entityStructs[msg.sender].date = now;
      entityStructs[msg.sender].profit = 0;
      entityStructs[msg.sender].update = 0;
      entityStructs[msg.sender].exit = 0;
      entityStructs[msg.sender].active = true;
      entityStructs[msg.sender].vip = false;
      
       
    
      if(timetoRegular) {   
         
        entityStructs[entityList[shift]].profit += base;
        if(entityStructs[entityList[shift]].profit == 2*base) {
            exitREG();
        }
      } else {
         
        uint lastVIP = lastVIPkey();
        entityStructs[vipList[lastVIP]].profit += base;
          if(entityStructs[vipList[lastVIP]].profit == 2*base) {
              exitVIP(vipList[lastVIP]);
          }     
      }
  }
  
  function up() internal {
      if(joined.sub(exited) < 3) revert("You are too alone to up");
      if(!entityStructs[msg.sender].active) revert("You are not in the list");
      if(entityStructs[msg.sender].vip && (now.sub(entityStructs[msg.sender].update)) < 600) revert ("Up allowed once per 10 min");
      
      if(!entityStructs[msg.sender].vip) {
          
           
           
            uint rowToDelete = entityStructs[msg.sender].listPointer;
            address keyToMove = entityList[entityList.length-1];
            entityList[rowToDelete] = keyToMove;
            entityStructs[keyToMove].listPointer = rowToDelete;
            entityList.length--;
           
            
           entityStructs[msg.sender].update = now;
           entityStructs[msg.sender].vip = true;
           newVip(msg.sender, true);
           
           devreward += msg.value;  
           
      } else if (entityStructs[msg.sender].vip) {
          
           
          entityStructs[msg.sender].update = now;
          delete vipList[entityStructs[msg.sender].listPointer];
          newVip(msg.sender, true);
          devreward += msg.value;  
      }
  }

  function newEntity(address entityAddress, bool entityData) internal returns(bool success) {
    entityStructs[entityAddress].active = entityData;
    entityStructs[entityAddress].listPointer = entityList.push(entityAddress) - 1;
    return true;
  }

  function exitREG() internal returns(bool success) {
    entityStructs[entityList[shift]].active = false;
    entityStructs[entityList[shift]].exit = now;
    entityList[shift].transfer( entityStructs[entityList[shift]].profit.mul(90).div(100) );
    devreward += entityStructs[entityList[shift]].profit.mul(10).div(100);
    exited++;
    delete entityList[shift];
    shift++;
     
    if(lastVIPkey() != 9999) {
     timetoRegular = false;
    }
    return true;
  }

  function newVip(address entityAddress, bool entityData) internal returns(bool success) {
    entityStructs[entityAddress].vip = entityData;
    entityStructs[entityAddress].listPointer = vipList.push(entityAddress) - 1;
    return true;
  }

  function exitVIP(address entityAddress) internal returns(bool success) {
    uint lastVIP = lastVIPkey();
    entityStructs[vipList[lastVIP]].active = false;
    entityStructs[vipList[lastVIP]].exit = now;
    vipList[lastVIP].transfer( entityStructs[vipList[lastVIP]].profit.mul(90).div(100) );
    devreward += entityStructs[vipList[lastVIP]].profit.mul(10).div(100);
     
    uint rowToDelete = entityStructs[entityAddress].listPointer;
    address keyToMove = vipList[vipList.length-1];
    vipList[rowToDelete] = keyToMove;
    entityStructs[keyToMove].listPointer = rowToDelete;
    vipList.length--;
    exited++;
     
    timetoRegular = true;
    return true;
  }
  
    function lastREGkey() public constant returns(uint) {
        if(entityList.length == 0) return 9999;
        if(shift == entityList.length) return 9999;  
        
        uint limit = entityList.length-1;
        for(uint l=limit; l >= 0; l--) {
            if(entityList[l] != address(0)) {
                return l;
            } 
        }
        return 9999;
    }
  
  function lastVIPkey() public constant returns(uint) {
        if(vipList.length == 0) return 9999;
        uint limit = vipList.length-1;
        for(uint j=limit; j >= 0; j--) {
            if(vipList[j] != address(0)) {
                return j;
            } 
        }
        return 9999;
    }
  
  function checkRemaining() public returns (bool) {
       
      if(now >= timeRemaining.add(startedAt)) {
         
        if(lastVIPkey() != 9999) {
            uint limit = vipList.length-1;
            for(uint l=limit; l >= 0; l--) {
                if(vipList[l] != address(0)) {
                    entityStructs[vipList[l]].active = false;
                    entityStructs[vipList[l]].vip = false;
                    entityStructs[vipList[l]].date = 0;
                }
                if(l == 0) break;
            }
        }
         
        if(lastREGkey() != 9999) {
            for(uint r = shift; r <= entityList.length-1; r++) {
                entityStructs[entityList[r]].active = false;
                entityStructs[entityList[r]].date = 0;
            }
        }
         
        rewardDev();
         
        if(address(this).balance.sub(devreward) > 0) {
            if(lastVIPkey() != 9999) {
                vipList[lastVIPkey()].transfer(address(this).balance);
            }
        }
         
        vipList.length=0;
        entityList.length=0;
        shift = 0;
        startedAt = now;
        timeRemaining = 24 hours;
        timetoRegular = true;
        exited = joined = 0;
        round++;
        return true;
      }
      
       
      uint range = joined.sub(exited).div(100);
      if(range != 0) {
        timeRemaining = timeRemaining.div(range.mul(2));  
      } 
      return false;
  }    
  
  function rewardDev() public {
       
      dev.transfer(devreward);
      devreward = 0;
  }  
  
  function queueVIP() public view returns (address[]) {
       
      return vipList;
  }
  
  function queueREG() public view returns (address[]) {
       
      return entityList;
  }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    
}