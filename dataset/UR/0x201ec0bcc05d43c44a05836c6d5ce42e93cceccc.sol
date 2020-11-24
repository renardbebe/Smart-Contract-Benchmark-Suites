 

pragma solidity ^0.4.18;

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


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


interface iContract {
    function transferOwnership(address _newOwner) external;
    function owner() external view returns (address);
}

contract OwnerContract is Ownable {
    iContract public ownedContract;
    address origOwner;

     
    function setContract(address _contract) public onlyOwner {
        require(_contract != address(0));
        ownedContract = iContract(_contract);
        origOwner = ownedContract.owner();
    }

     
    function transferOwnershipBack() public onlyOwner {
        ownedContract.transferOwnership(origOwner);
        ownedContract = iContract(address(0));
        origOwner = address(0);
    }
}

interface itoken {
     
    function freezeAccount(address _target, bool _freeze) external;
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function balanceOf(address _owner) external view returns (uint256 balance);
     
    function allowance(address _owner, address _spender) external view returns (uint256);
    function frozenAccount(address _account) external view returns (bool);
}

contract ReleaseToken is OwnerContract {
    using SafeMath for uint256;

     
    struct TimeRec {
        uint256 amount;
        uint256 remain;
        uint256 endTime;
        uint256 releasePeriodEndTime;
    }

    itoken public owned;

    address[] public frozenAccounts;
    mapping (address => TimeRec[]) frozenTimes;
     
    mapping (address => uint256) preReleaseAmounts;

    event ReleaseFunds(address _target, uint256 _amount);

     
    function setContract(address _contract) onlyOwner public {
        super.setContract(_contract);
        owned = itoken(_contract);
    }

     
    function removeAccount(uint _ind) internal returns (bool) {
        require(_ind >= 0);
        require(_ind < frozenAccounts.length);
        
        uint256 i = _ind;
        while (i < frozenAccounts.length.sub(1)) {
            frozenAccounts[i] = frozenAccounts[i.add(1)];
            i = i.add(1);
        }

        frozenAccounts.length = frozenAccounts.length.sub(1);
        return true;
    }

     
    function removeLockedTime(address _target, uint _ind) internal returns (bool) {
        require(_ind >= 0);
        require(_target != address(0));

        TimeRec[] storage lockedTimes = frozenTimes[_target];
        require(_ind < lockedTimes.length);
       
        uint256 i = _ind;
        while (i < lockedTimes.length.sub(1)) {
            lockedTimes[i] = lockedTimes[i.add(1)];
            i = i.add(1);
        }

        lockedTimes.length = lockedTimes.length.sub(1);
        return true;
    }

     
    function getRemainLockedOf(address _account) public view returns (uint256) {
        require(_account != address(0));

        uint256 totalRemain = 0;
        uint256 len = frozenAccounts.length;
        uint256 i = 0;
        while (i < len) {
            address frozenAddr = frozenAccounts[i];
            if (frozenAddr == _account) {
                uint256 timeRecLen = frozenTimes[frozenAddr].length;
                uint256 j = 0;
                while (j < timeRecLen) {
                    TimeRec storage timePair = frozenTimes[frozenAddr][j];
                    totalRemain = totalRemain.add(timePair.remain);

                    j = j.add(1);
                }
            }

            i = i.add(1);
        }

        return totalRemain;
    }

     
    function needRelease() public view returns (bool) {
        uint256 len = frozenAccounts.length;
        uint256 i = 0;
        while (i < len) {
            address frozenAddr = frozenAccounts[i];
            uint256 timeRecLen = frozenTimes[frozenAddr].length;
            uint256 j = 0;
            while (j < timeRecLen) {
                TimeRec storage timePair = frozenTimes[frozenAddr][j];
                if (now >= timePair.endTime) {
                    return true;
                }

                j = j.add(1);
            }

            i = i.add(1);
        }

        return false;
    }

     
    function freeze(address _target, uint256 _value, uint256 _frozenEndTime, uint256 _releasePeriod) onlyOwner public returns (bool) {
         
        require(_target != address(0));
        require(_value > 0);
        require(_frozenEndTime > 0 && _releasePeriod >= 0);

        uint256 len = frozenAccounts.length;
        
        for (uint256 i = 0; i < len; i = i.add(1)) {
            if (frozenAccounts[i] == _target) {
                break;
            }            
        }

        if (i >= len) {
            frozenAccounts.push(_target);  
        } 
        
         
        frozenTimes[_target].push(TimeRec(_value, _value, _frozenEndTime, _frozenEndTime.add(_releasePeriod)));
        owned.freezeAccount(_target, true);
        
        return true;
    }

     
    function transferAndFreeze(address _target, uint256 _value, uint256 _frozenEndTime, uint256 _releasePeriod) onlyOwner public returns (bool) {
         
        require(_target != address(0));
        require(_value > 0);
        require(_frozenEndTime > 0 && _releasePeriod >= 0);

         
        assert(owned.allowance(msg.sender, this) > 0);

         
        if (!freeze(_target, _value, _frozenEndTime, _releasePeriod)) {
            return false;
        }

        return (owned.transferFrom(msg.sender, _target, _value));
    }

     
    function releaseAllOnceLock() onlyOwner public returns (bool) {
         

        uint256 len = frozenAccounts.length;
        uint256 i = 0;
        while (i < len) {
            address target = frozenAccounts[i];
            if (frozenTimes[target].length == 1 && frozenTimes[target][0].endTime == frozenTimes[target][0].releasePeriodEndTime && frozenTimes[target][0].endTime > 0 && now >= frozenTimes[target][0].endTime) {
                uint256 releasedAmount = frozenTimes[target][0].amount;
                    
                 
                if (!removeLockedTime(target, 0)) {
                    return false;
                }

                 
                bool res = removeAccount(i);
                if (!res) {
                    return false;
                }
                
                owned.freezeAccount(target, false);
                 
                 
                ReleaseFunds(target, releasedAmount);
                len = len.sub(1);
                 
                 
            } else { 
                 
                i = i.add(1);
            }
        }
        
        return true;
         
    }

     
    function releaseAccount(address _target) onlyOwner public returns (bool) {
         
        require(_target != address(0));

        uint256 len = frozenAccounts.length;
        uint256 i = 0;
        while (i < len) {
            address destAddr = frozenAccounts[i];
            if (destAddr == _target) {
                if (frozenTimes[destAddr].length == 1 && frozenTimes[destAddr][0].endTime == frozenTimes[destAddr][0].releasePeriodEndTime && frozenTimes[destAddr][0].endTime > 0 && now >= frozenTimes[destAddr][0].endTime) { 
                    uint256 releasedAmount = frozenTimes[destAddr][0].amount;
                    
                     
                    if (!removeLockedTime(destAddr, 0)) {
                        return false;
                    }

                     
                    bool res = removeAccount(i);
                    if (!res) {
                        return false;
                    }

                    owned.freezeAccount(destAddr, false);
                     
                     
                    ReleaseFunds(destAddr, releasedAmount);
                     
                     

                }

                 
                return true; 
            }

            i = i.add(1);
        }
        
        return false;
    }    

     
    function releaseWithStage(address _target, address _dest) onlyOwner public returns (bool) {
         
        require(_target != address(0));
        require(_dest != address(0));
         
        
         
        assert(owned.allowance(_target, this) > 0);

        uint256 len = frozenAccounts.length;
        uint256 i = 0;
        while (i < len) {
             
            address frozenAddr = frozenAccounts[i];
            if (frozenAddr == _target) {
                uint256 timeRecLen = frozenTimes[frozenAddr].length;

                bool released = false;
                uint256 nowTime = now;
                for (uint256 j = 0; j < timeRecLen; released = false) {
                     
                    TimeRec storage timePair = frozenTimes[frozenAddr][j];
                    if (nowTime > timePair.endTime && timePair.endTime > 0 && timePair.releasePeriodEndTime > timePair.endTime) {                        
                        uint256 lastReleased = timePair.amount.sub(timePair.remain);
                        uint256 value = (timePair.amount * nowTime.sub(timePair.endTime) / timePair.releasePeriodEndTime.sub(timePair.endTime)).sub(lastReleased);
                        if (value > timePair.remain) {
                            value = timePair.remain;
                        } 
                        
                         
                        timePair.remain = timePair.remain.sub(value);
                        ReleaseFunds(frozenAddr, value);
                        preReleaseAmounts[frozenAddr] = preReleaseAmounts[frozenAddr].add(value);
                        if (timePair.remain < 1e8) {
                            if (!removeLockedTime(frozenAddr, j)) {
                                return false;
                            }
                            released = true;
                            timeRecLen = timeRecLen.sub(1);
                        }
                         
                    } else if (nowTime >= timePair.endTime && timePair.endTime > 0 && timePair.releasePeriodEndTime == timePair.endTime) {
                         
                        timePair.remain = 0;
                        ReleaseFunds(frozenAddr, timePair.amount);
                        preReleaseAmounts[frozenAddr] = preReleaseAmounts[frozenAddr].add(timePair.amount);
                        if (!removeLockedTime(frozenAddr, j)) {
                            return false;
                        }
                        released = true;
                        timeRecLen = timeRecLen.sub(1);

                        
                    } 

                    if (!released) {
                        j = j.add(1);
                    }
                }

                 
                if (preReleaseAmounts[frozenAddr] > 0) {
                    owned.freezeAccount(frozenAddr, false);
                    if (!owned.transferFrom(_target, _dest, preReleaseAmounts[frozenAddr])) {
                        return false;
                    }

                     
                    preReleaseAmounts[frozenAddr] = 0;
                }

                 
                if (frozenTimes[frozenAddr].length == 0) {
                    if (!removeAccount(i)) {
                        return false;
                    }                    
                } else {
                     
                    owned.freezeAccount(frozenAddr, true);
                }

                return true;
            }          

            i = i.add(1);
        }
        
        return false;
    }
}

contract ReleaseTokenV2 is ReleaseToken {
    mapping (address => uint256) oldBalances;
    mapping (address => address) public releaseAddrs;
    
    
     
    function setNewEndtime(address _target, uint256 _oldEndTime, uint256 _newEndTime) public returns (bool) {
        require(_target != address(0));
        require(_oldEndTime > 0 && _newEndTime > 0);

        uint256 len = frozenAccounts.length;
        uint256 i = 0;
        while (i < len) {
            address frozenAddr = frozenAccounts[i];
            if (frozenAddr == _target) {
                uint256 timeRecLen = frozenTimes[frozenAddr].length;
                uint256 j = 0;
                while (j < timeRecLen) {
                    TimeRec storage timePair = frozenTimes[frozenAddr][j];
                    if (_oldEndTime == timePair.endTime) {
                        uint256 duration = timePair.releasePeriodEndTime.sub(timePair.endTime);
                        timePair.endTime = _newEndTime;
                        timePair.releasePeriodEndTime = timePair.endTime.add(duration);                        
                        
                        return true;
                    }

                    j = j.add(1);
                }

                return false;
            }

            i = i.add(1);
        }

        return false;
    }

     
    function setNewReleasePeriod(address _target, uint256 _origEndTime, uint256 _duration) public returns (bool) {
        require(_target != address(0));
        require(_origEndTime > 0 && _duration > 0);

        uint256 len = frozenAccounts.length;
        uint256 i = 0;
        while (i < len) {
            address frozenAddr = frozenAccounts[i];
            if (frozenAddr == _target) {
                uint256 timeRecLen = frozenTimes[frozenAddr].length;
                uint256 j = 0;
                while (j < timeRecLen) {
                    TimeRec storage timePair = frozenTimes[frozenAddr][j];
                    if (_origEndTime == timePair.endTime) {
                        timePair.releasePeriodEndTime = _origEndTime.add(_duration);
                        return true;
                    }

                    j = j.add(1);
                }

                return false;
            }

            i = i.add(1);
        }

        return false;
    }

     
    function setReleasedAddress(address _target, address _releaseTo) public {
        require(_target != address(0));
        require(_releaseTo != address(0));

        releaseAddrs[_target] = _releaseTo;
    }

     
    function getLockedStages(address _target) public view returns (uint) {
        require(_target != address(0));

        uint256 len = frozenAccounts.length;
        uint256 i = 0;
        while (i < len) {
            address frozenAddr = frozenAccounts[i];
            if (frozenAddr == _target) {
                return frozenTimes[frozenAddr].length;               
            }

            i = i.add(1);
        }

        return 0;
    }

     
    function getEndTimeOfStage(address _target, uint _num) public view returns (uint256) {
        require(_target != address(0));

        uint256 len = frozenAccounts.length;
        uint256 i = 0;
        while (i < len) {
            address frozenAddr = frozenAccounts[i];
            if (frozenAddr == _target) {
                TimeRec storage timePair = frozenTimes[frozenAddr][_num];                
                return timePair.endTime;               
            }

            i = i.add(1);
        }

        return 0;
    }

     
    function getRemainOfStage(address _target, uint _num) public view returns (uint256) {
        require(_target != address(0));

        uint256 len = frozenAccounts.length;
        uint256 i = 0;
        while (i < len) {
            address frozenAddr = frozenAccounts[i];
            if (frozenAddr == _target) {
                TimeRec storage timePair = frozenTimes[frozenAddr][_num];                
                return timePair.remain;               
            }

            i = i.add(1);
        }

        return 0;
    }

     
    function getRemainReleaseTimeOfStage(address _target, uint _num) public view returns (uint256) {
        require(_target != address(0));

        uint256 len = frozenAccounts.length;
        uint256 i = 0;
        while (i < len) {
            address frozenAddr = frozenAccounts[i];
            if (frozenAddr == _target) {
                TimeRec storage timePair = frozenTimes[frozenAddr][_num];  
                if (timePair.releasePeriodEndTime == timePair.endTime || now <= timePair.endTime ) {
                    return (timePair.releasePeriodEndTime.sub(timePair.endTime));
                }    

                if (timePair.releasePeriodEndTime < now) {
                    return 0;
                }

                return (timePair.releasePeriodEndTime.sub(now));               
            }

            i = i.add(1);
        }

        return 0;
    }

     
    function gatherOldBalanceOf(address _target) public returns (uint256) {
        require(_target != address(0));
        require(frozenTimes[_target].length == 0);  

         
        uint256 origBalance = owned.balanceOf(_target);
        if (origBalance > 0) {
            oldBalances[_target] = origBalance;
        }

        return origBalance;
    }

     
    function gatherAllOldBalanceOf(address[] _targets) public returns (uint256) {
        require(_targets.length != 0);
        
        uint256 res = 0;
        for (uint256 i = 0; i < _targets.length; i = i.add(1)) {
            require(_targets[i] != address(0));
            res = res.add(gatherOldBalanceOf(_targets[i]));
        }

        return res;
    }
    
     
    function freeze(address _target, uint256 _value, uint256 _frozenEndTime, uint256 _releasePeriod) onlyOwner public returns (bool) {
        if (frozenTimes[_target].length == 0) {
            gatherOldBalanceOf(_target);
        }
        return super.freeze(_target, _value, _frozenEndTime, _releasePeriod);
    }    

     
    function releaseOldBalanceOf(address _target) onlyOwner public returns (bool) {
        require(_target != address(0));
        require(releaseAddrs[_target] != address(0));

         
        assert(owned.allowance(_target, this) > 0);

         
        if (oldBalances[_target] > 0) {
            bool freezeStatus = owned.frozenAccount(_target);
            owned.freezeAccount(_target, false);
            if (!owned.transferFrom(_target, releaseAddrs[_target], oldBalances[_target])) {
                return false;
            }

             
            owned.freezeAccount(_target, freezeStatus);
        }

        return true;
    }    

     
    function releaseByStage(address _target) onlyOwner public returns (bool) {
        require(_target != address(0));

        return releaseWithStage(_target, releaseAddrs[_target]);
    }  
}