 

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


interface itoken {
     
    function freezeAccount(address _target, bool _freeze) external;
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transferOwnership(address newOwner) external;
    function allowance(address _owner, address _spender) external view returns (uint256);
}

contract OwnerContract is Ownable {
    itoken public owned;
    
     
    function setContract(address _contract) public onlyOwner {
        require(_contract != address(0));
        owned = itoken(_contract);
    }

     
    function changeContractOwner(address _newOwner) public onlyOwner returns(bool) {
        require(_newOwner != address(0));
        owned.transferOwnership(_newOwner);
        owned = itoken(address(0));
        
        return true;
    }
}

contract ReleaseToken is OwnerContract {
    using SafeMath for uint256;

     
    struct TimeRec {
        uint256 amount;
        uint256 remain;
        uint256 endTime;
        uint256 duration;
    }

    address[] public frozenAccounts;
    mapping (address => TimeRec[]) frozenTimes;
     
    mapping (address => uint256) preReleaseAmounts;

    event ReleaseFunds(address _target, uint256 _amount);

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

         
        
         
        frozenTimes[_target].push(TimeRec(_value, _value, _frozenEndTime, _releasePeriod));
        owned.freezeAccount(_target, true);
        
        return true;
    }

     
    function transferAndFreeze( address _target, uint256 _value, uint256 _frozenEndTime, uint256 _releasePeriod) onlyOwner public returns (bool) {
         
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
            if (frozenTimes[target].length == 1 && 0 == frozenTimes[target][0].duration && frozenTimes[target][0].endTime > 0 && now >= frozenTimes[target][0].endTime) {
                bool res = removeAccount(i);
                if (!res) {
                    return false;
                }
                
                owned.freezeAccount(target, false);
                 
                 
                ReleaseFunds(target, frozenTimes[target][0].amount);
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
                if (frozenTimes[destAddr].length == 1 && 0 == frozenTimes[destAddr][0].duration && frozenTimes[destAddr][0].endTime > 0 && now >= frozenTimes[destAddr][0].endTime) { 
                    bool res = removeAccount(i);
                    if (!res) {
                        return false;
                    }

                    owned.freezeAccount(destAddr, false);
                     
                     
                    ReleaseFunds(destAddr, frozenTimes[destAddr][0].amount);
                     
                     

                }

                 
                return true; 
            }

            i = i.add(1);
        }
        
        return false;
    }

     
    function releaseMultiAccounts(address[] _targets) onlyOwner public returns (bool) {
         
        require(_targets.length != 0);

        uint256 i = 0;
        while (i < _targets.length) {
            if (!releaseAccount(_targets[i])) {
                return false;
            }

            i = i.add(1);
        }

        return true;
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
                for (uint256 j = 0; j < timeRecLen; released = false) {
                     
                    TimeRec storage timePair = frozenTimes[frozenAddr][j];
                    uint256 nowTime = now;
                    if (nowTime > timePair.endTime && timePair.endTime > 0 && timePair.duration > 0) {                        
                        uint256 value = timePair.amount * (nowTime - timePair.endTime) / timePair.duration;
                        if (value > timePair.remain) {
                            value = timePair.remain;
                        } 
                        
                         
                        
                        timePair.endTime = nowTime;        
                        timePair.remain = timePair.remain.sub(value);
                        if (timePair.remain < 1e8) {
                            if (!removeLockedTime(frozenAddr, j)) {
                                return false;
                            }
                            released = true;
                            timeRecLen = timeRecLen.sub(1);
                        }
                         
                         
                         
                        ReleaseFunds(frozenAddr, value);
                        preReleaseAmounts[frozenAddr] = preReleaseAmounts[frozenAddr].add(value);
                         
                    } else if (nowTime >= timePair.endTime && timePair.endTime > 0 && timePair.duration == 0) {
                         
                        
                        if (!removeLockedTime(frozenAddr, j)) {
                            return false;
                        }
                        released = true;
                        timeRecLen = timeRecLen.sub(1);

                         
                         
                         
                        ReleaseFunds(frozenAddr, timePair.amount);
                        preReleaseAmounts[frozenAddr] = preReleaseAmounts[frozenAddr].add(timePair.amount);
                         
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

     
    function releaseMultiWithStage(address[] _targets, address[] _dests) onlyOwner public returns (bool) {
         
        require(_targets.length != 0);
        require(_dests.length != 0);
        assert(_targets.length == _dests.length);

        uint256 i = 0;
        while (i < _targets.length) {
            if (!releaseWithStage(_targets[i], _dests[i])) {
                return false;
            }

            i = i.add(1);
        }

        return true;
    }
}