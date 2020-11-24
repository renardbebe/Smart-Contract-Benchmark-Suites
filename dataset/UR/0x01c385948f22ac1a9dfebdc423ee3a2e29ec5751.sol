 

pragma solidity ^0.4.13;

interface IFlyDropTokenMgr {
     
    function prepare(uint256 _rand,
                     address _from,
                     address _token,
                     uint256 _value) external returns (bool);

     
    function flyDrop(address[] _destAddrs, uint256[] _values) external returns (uint256);

     
    function isPoweruser(address _addr) external view returns (bool);
}

interface ILockedStorage {
     
    function frozenAccounts(address _wallet) external view returns (bool);

     
    function isExisted(address _wallet) external view returns (bool);

     
    function walletName(address _wallet) external view returns (string);

     
    function frozenAmount(address _wallet) external view returns (uint256);

     
    function balanceOf(address _wallet) external view returns (uint256);

     
    function addressByIndex(uint256 _ind) external view returns (address);

     
    function lockedStagesNum(address _target) external view returns (uint256);

     
    function endTimeOfStage(address _target, uint _ind) external view returns (uint256);

     
    function remainOfStage(address _target, uint _ind) external view returns (uint256);

     
    function amountOfStage(address _target, uint _ind) external view returns (uint256);

     
    function releaseEndTimeOfStage(address _target, uint _ind) external view returns (uint256);

     
    function size() external view returns (uint256);

     
    function addAccount(address _wallet, string _name, uint256 _value) external returns (bool);

     
    function addLockedTime(address _target,
                           uint256 _value,
                           uint256 _frozenEndTime,
                           uint256 _releasePeriod) external returns (bool);

     
    function freezeTokens(address _wallet, bool _freeze, uint256 _value) external returns (bool);

     
    function increaseBalance(address _wallet, uint256 _value) external returns (bool);

     
    function decreaseBalance(address _wallet, uint256 _value) external returns (bool);

     
    function removeAccount(address _wallet) external returns (bool);

     
    function removeLockedTime(address _target, uint _ind) external returns (bool);

     
    function changeEndTime(address _target, uint256 _ind, uint256 _newEndTime) external returns (bool);

     
    function setNewReleaseEndTime(address _target, uint256 _ind, uint256 _newReleaseEndTime) external returns (bool);

     
    function decreaseRemainLockedOf(address _target, uint256 _ind, uint256 _value) external returns (bool);

     
    function withdrawToken(address _token, address _to, uint256 _value) external returns (bool);
}

library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract DelayedClaimable is Claimable {

  uint256 public end;
  uint256 public start;

   
  function setLimits(uint256 _start, uint256 _end) public onlyOwner {
    require(_start <= _end);
    end = _end;
    start = _start;
  }

   
  function claimOwnership() public onlyPendingOwner {
    require((block.number <= end) && (block.number >= start));
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
    end = 0;
  }

}

contract OwnerContract is DelayedClaimable {
    Claimable public ownedContract;
    address public pendingOwnedOwner;
     

     
    function bindContract(address _contract) onlyOwner public returns (bool) {
        require(_contract != address(0));
        ownedContract = Claimable(_contract);
         

         
        if (ownedContract.owner() != address(this)) {
            ownedContract.claimOwnership();
        }

        return true;
    }

     
     
     
     
     
     

     
    function changeOwnershipto(address _nextOwner)  onlyOwner public {
        require(ownedContract != address(0));

        if (ownedContract.owner() != pendingOwnedOwner) {
            ownedContract.transferOwnership(_nextOwner);
            pendingOwnedOwner = _nextOwner;
             
             
        } else {
             
            ownedContract = Claimable(address(0));
            pendingOwnedOwner = address(0);
        }
    }

     
    function ownedOwnershipTransferred() onlyOwner public returns (bool) {
        require(ownedContract != address(0));
        if (ownedContract.owner() == pendingOwnedOwner) {
             
            ownedContract = Claimable(address(0));
            pendingOwnedOwner = address(0);
            return true;
        } else {
            return false;
        }
    }
}

contract ReleaseAndLockToken is OwnerContract {
    using SafeMath for uint256;

    ILockedStorage lockedStorage;
    IFlyDropTokenMgr flyDropMgr;
     
    mapping (address => uint256) preReleaseAmounts;

    event ReleaseFunds(address indexed _target, uint256 _amount);

     
    function initialize(address _contract, address _flyDropContract) onlyOwner public returns (bool) {
        require(_contract != address(0));
        require(_flyDropContract != address(0));

        require(super.bindContract(_contract));
        lockedStorage = ILockedStorage(_contract);
        flyDropMgr = IFlyDropTokenMgr(_flyDropContract);
         

        return true;
    }

     
    function needRelease() public view returns (bool) {
        uint256 len = lockedStorage.size();
        uint256 i = 0;
        while (i < len) {
            address frozenAddr = lockedStorage.addressByIndex(i);
            uint256 timeRecLen = lockedStorage.lockedStagesNum(frozenAddr);
            uint256 j = 0;
            while (j < timeRecLen) {
                if (now >= lockedStorage.endTimeOfStage(frozenAddr, j)) {
                    return true;
                }

                j = j.add(1);
            }

            i = i.add(1);
        }

        return false;
    }

     
    function needReleaseFor(address _target) public view returns (bool) {
        require(_target != address(0));

        uint256 timeRecLen = lockedStorage.lockedStagesNum(_target);
        uint256 j = 0;
        while (j < timeRecLen) {
            if (now >= lockedStorage.endTimeOfStage(_target, j)) {
                return true;
            }

            j = j.add(1);
        }

        return false;
    }

     
    function freeze(address _target, string _name, uint256 _value, uint256 _frozenEndTime, uint256 _releasePeriod) onlyOwner public returns (bool) {
         
        require(_target != address(0));
        require(_value > 0);
        require(_frozenEndTime > 0);

        if (!lockedStorage.isExisted(_target)) {
            lockedStorage.addAccount(_target, _name, _value);  
        }

         
        require(lockedStorage.addLockedTime(_target, _value, _frozenEndTime, _releasePeriod));
        require(lockedStorage.freezeTokens(_target, true, _value));

        return true;
    }

     
    function transferAndFreeze(address _target,
                               string _name,
                               address _from,
                               address _tk,
                               uint256 _value,
                               uint256 _frozenEndTime,
                               uint256 _releasePeriod) onlyOwner public returns (bool) {
        require(_from != address(0));
        require(_target != address(0));
        require(_value > 0);
        require(_frozenEndTime > 0);

         
         
        uint rand = now % 6 + 7;  
        require(flyDropMgr.prepare(rand, _from, _tk, _value));

         
         
        address[] memory dests = new address[](1);
        dests[0] = address(lockedStorage);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _value;
        require(flyDropMgr.flyDrop(dests, amounts) >= 1);
        if (!lockedStorage.isExisted(_target)) {
            require(lockedStorage.addAccount(_target, _name, _value));
        } else {
            require(lockedStorage.increaseBalance(_target, _value));
        }

         
        require(freeze(_target, _name, _value, _frozenEndTime, _releasePeriod));
        return true;
    }

     
    function releaseTokens(address _target, address _tk, uint256 _value) internal {
        require(lockedStorage.withdrawToken(_tk, _target, _value));
        require(lockedStorage.freezeTokens(_target, false, _value));
        require(lockedStorage.decreaseBalance(_target, _value));
    }

     
    function releaseAllOnceLock(address _tk) onlyOwner public returns (bool) {
        require(_tk != address(0));

        uint256 len = lockedStorage.size();
        uint256 i = 0;
        while (i < len) {
            address target = lockedStorage.addressByIndex(i);
            if (lockedStorage.lockedStagesNum(target) == 1
                && lockedStorage.endTimeOfStage(target, 0) == lockedStorage.releaseEndTimeOfStage(target, 0)
                && lockedStorage.endTimeOfStage(target, 0) > 0
                && now >= lockedStorage.endTimeOfStage(target, 0)) {
                uint256 releasedAmount = lockedStorage.amountOfStage(target, 0);

                 
                if (!lockedStorage.removeLockedTime(target, 0)) {
                    return false;
                }

                 
                if (!lockedStorage.removeAccount(target)) {
                    return false;
                }

                releaseTokens(target, _tk, releasedAmount);
                emit ReleaseFunds(target, releasedAmount);
                len = len.sub(1);
            } else {
                 
                i = i.add(1);
            }
        }

        return true;
    }

     
    function releaseAccount(address _target, address _tk) onlyOwner public returns (bool) {
        require(_tk != address(0));

        if (!lockedStorage.isExisted(_target)) {
            return false;
        }

        if (lockedStorage.lockedStagesNum(_target) == 1
            && lockedStorage.endTimeOfStage(_target, 0) == lockedStorage.releaseEndTimeOfStage(_target, 0)
            && lockedStorage.endTimeOfStage(_target, 0) > 0
            && now >= lockedStorage.endTimeOfStage(_target, 0)) {
            uint256 releasedAmount = lockedStorage.amountOfStage(_target, 0);

             
            if (!lockedStorage.removeLockedTime(_target, 0)) {
                return false;
            }

             
            if (!lockedStorage.removeAccount(_target)) {
                return false;
            }

            releaseTokens(_target, _tk, releasedAmount);
            emit ReleaseFunds(_target, releasedAmount);
        }

         
        return true;
    }

     
    function releaseWithStage(address _target, address _tk) onlyOwner public returns (bool) {
        require(_tk != address(0));

        address frozenAddr = _target;
        if (!lockedStorage.isExisted(frozenAddr)) {
            return false;
        }

        uint256 timeRecLen = lockedStorage.lockedStagesNum(frozenAddr);
        bool released = false;
        uint256 nowTime = now;
        for (uint256 j = 0; j < timeRecLen; released = false) {
             
            uint256 endTime = lockedStorage.endTimeOfStage(frozenAddr, j);
            uint256 releasedEndTime = lockedStorage.releaseEndTimeOfStage(frozenAddr, j);
            uint256 amount = lockedStorage.amountOfStage(frozenAddr, j);
            uint256 remain = lockedStorage.remainOfStage(frozenAddr, j);
            if (nowTime > endTime && endTime > 0 && releasedEndTime > endTime) {
                uint256 lastReleased = amount.sub(remain);
                uint256 value = (amount * nowTime.sub(endTime) / releasedEndTime.sub(endTime)).sub(lastReleased);

                if (value > remain) {
                    value = remain;
                }
                lockedStorage.decreaseRemainLockedOf(frozenAddr, j, value);
                emit ReleaseFunds(_target, value);

                preReleaseAmounts[frozenAddr] = preReleaseAmounts[frozenAddr].add(value);
                if (lockedStorage.remainOfStage(frozenAddr, j) < 1e8) {
                    if (!lockedStorage.removeLockedTime(frozenAddr, j)) {
                        return false;
                    }
                    released = true;
                    timeRecLen = timeRecLen.sub(1);
                }
            } else if (nowTime >= endTime && endTime > 0 && releasedEndTime == endTime) {
                lockedStorage.decreaseRemainLockedOf(frozenAddr, j, remain);
                emit ReleaseFunds(frozenAddr, amount);
                preReleaseAmounts[frozenAddr] = preReleaseAmounts[frozenAddr].add(amount);
                if (!lockedStorage.removeLockedTime(frozenAddr, j)) {
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
            releaseTokens(frozenAddr, _tk, preReleaseAmounts[frozenAddr]);

             
            preReleaseAmounts[frozenAddr] = 0;
        }

         
        if (lockedStorage.lockedStagesNum(frozenAddr) == 0) {
            if (!lockedStorage.removeAccount(frozenAddr)) {
                return false;
            }
        }

        return true;
    }

     
    function setNewEndtime(address _target, uint256 _oldEndTime, uint256 _oldDuration, uint256 _newEndTime) onlyOwner public returns (bool) {
        require(_target != address(0));
        require(_oldEndTime > 0 && _newEndTime > 0);

        if (!lockedStorage.isExisted(_target)) {
            return false;
        }

        uint256 timeRecLen = lockedStorage.lockedStagesNum(_target);
        uint256 j = 0;
        while (j < timeRecLen) {
            uint256 endTime = lockedStorage.endTimeOfStage(_target, j);
            uint256 releasedEndTime = lockedStorage.releaseEndTimeOfStage(_target, j);
            uint256 duration = releasedEndTime.sub(endTime);
            if (_oldEndTime == endTime && _oldDuration == duration) {
                bool res = lockedStorage.changeEndTime(_target, j, _newEndTime);
                res = lockedStorage.setNewReleaseEndTime(_target, j, _newEndTime.add(duration)) && res;
                return res;
            }

            j = j.add(1);
        }

        return false;
    }

     
    function setNewReleasePeriod(address _target, uint256 _origEndTime, uint256 _origDuration, uint256 _newDuration) onlyOwner public returns (bool) {
        require(_target != address(0));
        require(_origEndTime > 0);

        if (!lockedStorage.isExisted(_target)) {
            return false;
        }

        uint256 timeRecLen = lockedStorage.lockedStagesNum(_target);
        uint256 j = 0;
        while (j < timeRecLen) {
            uint256 endTime = lockedStorage.endTimeOfStage(_target, j);
            uint256 releasedEndTime = lockedStorage.releaseEndTimeOfStage(_target, j);
            if (_origEndTime == endTime && _origDuration == releasedEndTime.sub(endTime)) {
                return lockedStorage.setNewReleaseEndTime(_target, j, _origEndTime.add(_newDuration));
            }

            j = j.add(1);
        }

        return false;
    }

     
    function getLockedStages(address _target) public view returns (uint) {
        require(_target != address(0));

        return lockedStorage.lockedStagesNum(_target);
    }

     
    function getEndTimeOfStage(address _target, uint _num) public view returns (uint256) {
        require(_target != address(0));

        return lockedStorage.endTimeOfStage(_target, _num);
    }

     
    function getRemainOfStage(address _target, uint _num) public view returns (uint256) {
        require(_target != address(0));

        return lockedStorage.remainOfStage(_target, _num);
    }

     
    function getRemainLockedOf(address _account) public view returns (uint256) {
        require(_account != address(0));

        uint256 totalRemain = 0;
        if(lockedStorage.isExisted(_account)) {
            uint256 timeRecLen = lockedStorage.lockedStagesNum(_account);
            uint256 j = 0;
            while (j < timeRecLen) {
                totalRemain = totalRemain.add(lockedStorage.remainOfStage(_account, j));
                j = j.add(1);
            }
        }

        return totalRemain;
    }

     
    function getRemainReleaseTimeOfStage(address _target, uint _num) public view returns (uint256) {
        require(_target != address(0));

        uint256 nowTime = now;
        uint256 releaseEndTime = lockedStorage.releaseEndTimeOfStage(_target, _num);

        if (releaseEndTime == 0 || releaseEndTime < nowTime) {
            return 0;
        }

        uint256 endTime = lockedStorage.endTimeOfStage(_target, _num);
        if (releaseEndTime == endTime || nowTime <= endTime ) {
            return (releaseEndTime.sub(endTime));
        }

        return (releaseEndTime.sub(nowTime));
    }

     
    function releaseMultiAccounts(address[] _targets, address _tk) onlyOwner public returns (bool) {
        require(_targets.length != 0);

        bool res = false;
        uint256 i = 0;
        while (i < _targets.length) {
            res = releaseAccount(_targets[i], _tk) || res;
            i = i.add(1);
        }

        return res;
    }

     
    function releaseMultiWithStage(address[] _targets, address _tk) onlyOwner public returns (bool) {
        require(_targets.length != 0);

        bool res = false;
        uint256 i = 0;
        while (i < _targets.length) {
            res = releaseWithStage(_targets[i], _tk) || res;  
            i = i.add(1);
        }

        return res;
    }

     
    function bytes32ToString(bytes32 _b32) internal pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(_b32) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

      
    function freezeMulti(address[] _targets, bytes32[] _names, uint256[] _values, uint256[] _frozenEndTimes, uint256[] _releasePeriods) onlyOwner public returns (bool) {
        require(_targets.length != 0);
        require(_names.length != 0);
        require(_values.length != 0);
        require(_frozenEndTimes.length != 0);
        require(_releasePeriods.length != 0);
        require(_targets.length == _names.length && _names.length == _values.length && _values.length == _frozenEndTimes.length && _frozenEndTimes.length == _releasePeriods.length);

        bool res = true;
        for (uint256 i = 0; i < _targets.length; i = i.add(1)) {
             
            res = freeze(_targets[i], bytes32ToString(_names[i]), _values[i], _frozenEndTimes[i], _releasePeriods[i]) && res;
        }

        return res;
    }

     
    function transferAndFreezeMulti(address[] _targets, bytes32[] _names, address _from, address _tk, uint256[] _values, uint256[] _frozenEndTimes, uint256[] _releasePeriods) onlyOwner public returns (bool) {
        require(_targets.length != 0);
        require(_names.length != 0);
        require(_values.length != 0);
        require(_frozenEndTimes.length != 0);
        require(_releasePeriods.length != 0);
        require(_targets.length == _names.length && _names.length == _values.length && _values.length == _frozenEndTimes.length && _frozenEndTimes.length == _releasePeriods.length);

        bool res = true;
        for (uint256 i = 0; i < _targets.length; i = i.add(1)) {
             
            res = transferAndFreeze(_targets[i], bytes32ToString(_names[i]), _from, _tk, _values[i], _frozenEndTimes[i], _releasePeriods[i]) && res;
        }

        return res;
    }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}