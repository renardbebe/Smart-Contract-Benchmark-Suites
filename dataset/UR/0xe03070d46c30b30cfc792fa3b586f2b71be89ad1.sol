 

pragma solidity ^0.4.21;

interface itoken {
    function freezeAccount(address _target, bool _freeze) external;
    function freezeAccountPartialy(address _target, uint256 _value) external;
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function balanceOf(address _owner) external view returns (uint256 balance);
     
    function allowance(address _owner, address _spender) external view returns (uint256);
    function frozenAccount(address _account) external view returns (bool);
    function frozenAmount(address _account) external view returns (uint256);
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

contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract OwnerContract is Claimable {
    Claimable public ownedContract;
    address internal origOwner;

     
    function bindContract(address _contract) onlyOwner public returns (bool) {
        require(_contract != address(0));
        ownedContract = Claimable(_contract);
        origOwner = ownedContract.owner();

         
        ownedContract.claimOwnership();

        return true;
    }

     
    function transferOwnershipBack() onlyOwner public {
        ownedContract.transferOwnership(origOwner);
        ownedContract = Claimable(address(0));
        origOwner = address(0);
    }

     
    function changeOwnershipto(address _nextOwner)  onlyOwner public {
        ownedContract.transferOwnership(_nextOwner);
        ownedContract = Claimable(address(0));
        origOwner = address(0);
    }
}

contract ReleaseToken is OwnerContract {
    using SafeMath for uint256;

     
    struct TimeRec {
        uint256 amount;
        uint256 remain;
        uint256 endTime;
        uint256 releasePeriodEndTime;
    }

    itoken internal owned;

    address[] public frozenAccounts;
    mapping (address => TimeRec[]) frozenTimes;
     
    mapping (address => uint256) preReleaseAmounts;

    event ReleaseFunds(address _target, uint256 _amount);

     
    function bindContract(address _contract) onlyOwner public returns (bool) {
        require(_contract != address(0));
        owned = itoken(_contract);
        return super.bindContract(_contract);
    }

     
    function removeAccount(uint _ind) internal returns (bool) {
        require(_ind < frozenAccounts.length);

        uint256 i = _ind;
        while (i < frozenAccounts.length.sub(1)) {
            frozenAccounts[i] = frozenAccounts[i.add(1)];
            i = i.add(1);
        }

        delete frozenAccounts[frozenAccounts.length.sub(1)];
        frozenAccounts.length = frozenAccounts.length.sub(1);
        return true;
    }

     
    function removeLockedTime(address _target, uint _ind) internal returns (bool) {
        require(_target != address(0));

        TimeRec[] storage lockedTimes = frozenTimes[_target];
        require(_ind < lockedTimes.length);

        uint256 i = _ind;
        while (i < lockedTimes.length.sub(1)) {
            lockedTimes[i] = lockedTimes[i.add(1)];
            i = i.add(1);
        }

        delete lockedTimes[lockedTimes.length.sub(1)];
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
        require(_frozenEndTime > 0);

        uint256 len = frozenAccounts.length;

        uint256 i = 0;
        for (; i < len; i = i.add(1)) {
            if (frozenAccounts[i] == _target) {
                break;
            }
        }

        if (i >= len) {
            frozenAccounts.push(_target);  
        }

         
        frozenTimes[_target].push(TimeRec(_value, _value, _frozenEndTime, _frozenEndTime.add(_releasePeriod)));
        if (owned.frozenAccount(_target)) {
            uint256 preFrozenAmount = owned.frozenAmount(_target);
            owned.freezeAccountPartialy(_target, _value.add(preFrozenAmount));
        } else {
            owned.freezeAccountPartialy(_target, _value);
        }

        return true;
    }

     
    function transferAndFreeze(address _target, uint256 _value, uint256 _frozenEndTime, uint256 _releasePeriod) onlyOwner public returns (bool) {
         
        require(_target != address(0));
        require(_value > 0);
        require(_frozenEndTime > 0);

         
        require(owned.allowance(msg.sender, this) > 0);

         
        require(owned.transferFrom(msg.sender, _target, _value));

         
        if (!freeze(_target, _value, _frozenEndTime, _releasePeriod)) {
            return false;
        }

        return true;
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

                 
                if (!removeAccount(i)) {
                    return false;
                }

                uint256 preFrozenAmount = owned.frozenAmount(target);
                if (preFrozenAmount > releasedAmount) {
                    owned.freezeAccountPartialy(target, preFrozenAmount.sub(releasedAmount));
                } else {
                    owned.freezeAccount(target, false);
                }

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

                     
                    if (!removeAccount(i)) {
                        return false;
                    }

                    uint256 preFrozenAmount = owned.frozenAmount(destAddr);
                    if (preFrozenAmount > releasedAmount) {
                        owned.freezeAccountPartialy(destAddr, preFrozenAmount.sub(releasedAmount));
                    } else {
                        owned.freezeAccount(destAddr, false);
                    }

                    ReleaseFunds(destAddr, releasedAmount);
                }

                 
                return true;
            }

            i = i.add(1);
        }

        return false;
    }

     
    function releaseWithStage(address _target ) onlyOwner public returns (bool) {
         
        require(_target != address(0));
         
         

         
         

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
                    uint256 preReleasedAmount = preReleaseAmounts[frozenAddr];
                    uint256 preFrozenAmount = owned.frozenAmount(frozenAddr);

                     
                    preReleaseAmounts[frozenAddr] = 0;
                    if (preFrozenAmount > preReleasedAmount) {
                        owned.freezeAccountPartialy(frozenAddr, preFrozenAmount.sub(preReleasedAmount));
                    } else {
                        owned.freezeAccount(frozenAddr, false);
                    }
                     
                     
                     
                }

                 
                if (frozenTimes[frozenAddr].length == 0) {
                    if (!removeAccount(i)) {
                        return false;
                    }
                }  

                return true;
            }

            i = i.add(1);
        }

        return false;
    }

     
    function setNewEndtime(address _target, uint256 _oldEndTime, uint256 _newEndTime) onlyOwner public returns (bool) {
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

     
    function setNewReleasePeriod(address _target, uint256 _origEndTime, uint256 _duration) onlyOwner public returns (bool) {
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
                uint256 nowTime = now;
                if (timePair.releasePeriodEndTime == timePair.endTime || nowTime <= timePair.endTime ) {
                    return (timePair.releasePeriodEndTime.sub(timePair.endTime));
                }

                if (timePair.releasePeriodEndTime < nowTime) {
                    return 0;
                }

                return (timePair.releasePeriodEndTime.sub(nowTime));
            }

            i = i.add(1);
        }

        return 0;
    }

     
    function releaseMultiAccounts(address[] _targets) onlyOwner public returns (bool) {
         
        require(_targets.length != 0);

        bool res = false;
        uint256 i = 0;
        while (i < _targets.length) {
            res = releaseAccount(_targets[i]) || res;
            i = i.add(1);
        }

        return res;
    }

     
    function releaseMultiWithStage(address[] _targets) onlyOwner public returns (bool) {
        require(_targets.length != 0);

        bool res = false;
        uint256 i = 0;
        while (i < _targets.length) {
            require(_targets[i] != address(0));

            res = releaseWithStage(_targets[i]) || res;  
            i = i.add(1);
        }

        return res;
    }

      
    function freezeMulti(address[] _targets, uint256[] _values, uint256[] _frozenEndTimes, uint256[] _releasePeriods) onlyOwner public returns (bool) {
        require(_targets.length != 0);
        require(_values.length != 0);
        require(_frozenEndTimes.length != 0);
        require(_releasePeriods.length != 0);
        require(_targets.length == _values.length && _values.length == _frozenEndTimes.length && _frozenEndTimes.length == _releasePeriods.length);

        bool res = true;
        for (uint256 i = 0; i < _targets.length; i = i.add(1)) {
            require(_targets[i] != address(0));
            res = freeze(_targets[i], _values[i], _frozenEndTimes[i], _releasePeriods[i]) && res;
        }

        return res;
    }

     
    function transferAndFreezeMulti(address[] _targets, uint256[] _values, uint256[] _frozenEndTimes, uint256[] _releasePeriods) onlyOwner public returns (bool) {
        require(_targets.length != 0);
        require(_values.length != 0);
        require(_frozenEndTimes.length != 0);
        require(_releasePeriods.length != 0);
        require(_targets.length == _values.length && _values.length == _frozenEndTimes.length && _frozenEndTimes.length == _releasePeriods.length);

        bool res = true;
        for (uint256 i = 0; i < _targets.length; i = i.add(1)) {
            require(_targets[i] != address(0));
            res = transferAndFreeze(_targets[i], _values[i], _frozenEndTimes[i], _releasePeriods[i]) && res;
        }

        return res;
    }
}