 

pragma solidity 0.4.19;

 
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

 
library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private {
         
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

         
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

     
    function toSlice(string self) internal returns (slice) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

     
    function len(bytes32 self) internal returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (self & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (self & 0xffffffffffffffff == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (self & 0xffffffff == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (self & 0xffff == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (self & 0xff == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

     
    function toSliceB32(bytes32 self) internal returns (slice ret) {
         
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

     
    function copy(slice self) internal returns (slice) {
        return slice(self._len, self._ptr);
    }

     
    function toString(slice self) internal returns (string) {
        var ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

     
    function len(slice self) internal returns (uint l) {
         
        var ptr = self._ptr - 31;
        var end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

     
    function empty(slice self) internal returns (bool) {
        return self._len == 0;
    }

     
    function compare(slice self, slice other) internal returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        var selfptr = self._ptr;
        var otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                 
                uint mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                var diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

     
    function equals(slice self, slice other) internal returns (bool) {
        return compare(self, other) == 0;
    }

     
    function nextRune(slice self, slice rune) internal returns (slice) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint len;
        uint b;
         
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            len = 1;
        } else if(b < 0xE0) {
            len = 2;
        } else if(b < 0xF0) {
            len = 3;
        } else {
            len = 4;
        }

         
        if (len > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += len;
        self._len -= len;
        rune._len = len;
        return rune;
    }

     
    function nextRune(slice self) internal returns (slice ret) {
        nextRune(self, ret);
    }

     
    function ord(slice self) internal returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

         
        assembly { word:= mload(mload(add(self, 32))) }
        var b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

         
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                 
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

     
    function keccak(slice self) internal returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

     
    function startsWith(slice self, slice needle) internal returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

     
    function beyond(slice self, slice needle) internal returns (slice) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(sha3(selfptr, length), sha3(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

     
    function endsWith(slice self, slice needle) internal returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        var selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

     
    function until(slice self, slice needle) internal returns (slice) {
        if (self._len < needle._len) {
            return self;
        }

        var selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

     
     
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private returns (uint) {
        uint ptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                 
                assembly {
                    let mask := not(sub(exp(2, mul(8, sub(32, needlelen))), 1))
                    let needledata := and(mload(needleptr), mask)
                    let end := add(selfptr, sub(selflen, needlelen))
                    ptr := selfptr
                    loop:
                    jumpi(exit, eq(and(mload(ptr), mask), needledata))
                    ptr := add(ptr, 1)
                    jumpi(loop, lt(sub(ptr, 1), end))
                    ptr := add(selfptr, selflen)
                    exit:
                }
                return ptr;
            } else {
                 
                bytes32 hash;
                assembly { hash := sha3(needleptr, needlelen) }
                ptr = selfptr;
                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := sha3(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

     
     
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                 
                assembly {
                    let mask := not(sub(exp(2, mul(8, sub(32, needlelen))), 1))
                    let needledata := and(mload(needleptr), mask)
                    ptr := add(selfptr, sub(selflen, needlelen))
                    loop:
                    jumpi(ret, eq(and(mload(ptr), mask), needledata))
                    ptr := sub(ptr, 1)
                    jumpi(loop, gt(add(ptr, 1), selfptr))
                    ptr := selfptr
                    jump(exit)
                    ret:
                    ptr := add(ptr, needlelen)
                    exit:
                }
                return ptr;
            } else {
                 
                bytes32 hash;
                assembly { hash := sha3(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := sha3(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

     
    function find(slice self, slice needle) internal returns (slice) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

     
    function rfind(slice self, slice needle) internal returns (slice) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

     
    function split(slice self, slice needle, slice token) internal returns (slice) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
             
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

     
    function split(slice self, slice needle) internal returns (slice token) {
        split(self, needle, token);
    }

     
    function rsplit(slice self, slice needle, slice token) internal returns (slice) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
             
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

     
    function rsplit(slice self, slice needle) internal returns (slice token) {
        rsplit(self, needle, token);
    }

     
    function count(slice self, slice needle) internal returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

     
    function contains(slice self, slice needle) internal returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

     
    function concat(slice self, slice other) internal returns (string) {
        var ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

     
    function join(slice self, slice[] parts) internal returns (string) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for (uint i = 0; i < parts.length; i++) {
            length += parts[i]._len;
        }

        var ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
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

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address addr) internal {
        role.bearer[addr] = true;
    }

     
    function remove(Role storage role, address addr) internal {
        role.bearer[addr] = false;
    }

     
    function check(Role storage role, address addr) view internal {
        require(has(role, addr));
    }

     
    function has(Role storage role, address addr) view internal returns (bool) {
        return role.bearer[addr];
    }
}

 
contract RBAC is Ownable {
    using Roles for Roles.Role;

    mapping (string => Roles.Role) private roles;

    event RoleAdded(address addr, string roleName);
    event RoleRemoved(address addr, string roleName);

     
    function RBAC() public {
    }

     
    function checkRole(address addr, string roleName) view public {
        roles[roleName].check(addr);
    }

     
    function hasRole(address addr, string roleName) view public returns (bool) {
        return roles[roleName].has(addr);
    }

     
    function adminAddRole(address addr, string roleName) onlyOwner public {
        roles[roleName].add(addr);
        RoleAdded(addr, roleName);
    }

     
    function adminRemoveRole(address addr, string roleName) onlyOwner public {
        roles[roleName].remove(addr);
        RoleRemoved(addr, roleName);
    }

     
    modifier onlyRole(string roleName) {
        checkRole(msg.sender, roleName);
        _;
    }

    modifier onlyOwnerOr(string roleName) {
        require(msg.sender == owner || roles[roleName].has(msg.sender));
        _;
    }    
}

 
contract Heritable is RBAC {
  address private heir_;

   
  uint256 private heartbeatTimeout_;

   
  uint256 private timeOfDeath_;

  event HeirChanged(address indexed owner, address indexed newHeir);
  event OwnerHeartbeated(address indexed owner);
  event OwnerProclaimedDead(address indexed owner, address indexed heir, uint256 timeOfDeath);
  event HeirOwnershipClaimed(address indexed previousOwner, address indexed newOwner);


   
  modifier onlyHeir() {
    require(msg.sender == heir_);
    _;
  }


   
  function Heritable(uint256 _heartbeatTimeout) public {
    setHeartbeatTimeout(_heartbeatTimeout);
  }

  function setHeir(address newHeir) public onlyOwner {
    require(newHeir != owner);
    heartbeat();
    HeirChanged(owner, newHeir);
    heir_ = newHeir;
  }

   
  function heir() public view returns(address) {
    return heir_;
  }

  function heartbeatTimeout() public view returns(uint256) {
    return heartbeatTimeout_;
  }
  
  function timeOfDeath() public view returns(uint256) {
    return timeOfDeath_;
  }

   
  function removeHeir() public onlyOwner {
    heartbeat();
    heir_ = 0;
  }

   
  function proclaimDeath() public onlyHeir {
    require(ownerLives());
    OwnerProclaimedDead(owner, heir_, timeOfDeath_);
    timeOfDeath_ = block.timestamp;
  }

   
  function heartbeat() public onlyOwner {
    OwnerHeartbeated(owner);
    timeOfDeath_ = 0;
  }

   
  function claimHeirOwnership() public onlyHeir {
    require(!ownerLives());
    require(block.timestamp >= timeOfDeath_ + heartbeatTimeout_);
    OwnershipTransferred(owner, heir_);
    HeirOwnershipClaimed(owner, heir_);
    owner = heir_;
    timeOfDeath_ = 0;
  }

  function setHeartbeatTimeout(uint256 newHeartbeatTimeout) internal onlyOwner {
    require(ownerLives());
    heartbeatTimeout_ = newHeartbeatTimeout;
  }

  function ownerLives() internal view returns (bool) {
    return timeOfDeath_ == 0;
  }
}

contract BettingBase {
    enum BetStatus {
        None,
        Won
    }

    enum LineStages {
        OpenedUntilStart,
        ResultSubmitted,
        Cancelled,
        Refunded,
        Paid
    }    

    enum LineType {
        ThreeWay,
        TwoWay,
        DoubleChance,
        SomeOfMany
    }

    enum TwoWayLineType {
        Standart,
        YesNo,
        OverUnder,
        AsianHandicap,
        HeadToHead
    }

    enum PaymentType {
        No,
        Gain, 
        Refund
    }
}

contract AbstractBetStorage is BettingBase {
    function addBet(uint lineId, uint betId, address player, uint amount) external;
    function addLine(uint lineId, LineType lineType, uint start, uint resultCount) external;
    function cancelLine(uint lineId) external;
    function getBetPool(uint lineId, uint betId) external view returns (BetStatus status, uint sum);
    function getLineData(uint lineId) external view returns (uint startTime, uint resultCount, LineType lineType, LineStages stage);
    function getLineData2(uint lineId) external view returns (uint resultCount, LineStages stage);
    function getLineSum(uint lineId) external view returns (uint sum);
    function getPlayerBet(uint lineId, uint betId, address player) external view returns (uint result);
    function getSumOfPlayerBetsById(uint lineId, uint playerId, PaymentType paymentType) external view returns (address player, uint amount);
    function isBetStorage() external pure returns (bool);
    function setLineStartTime(uint lineId, uint time) external;    
    function startPayments(uint lineId, uint chunkSize) external returns (PaymentType paymentType, uint startId, uint endId, uint luckyPool, uint unluckyPool);
    function submitResult(uint lineId, uint[] results) external;
    function transferOwnership(address newOwner) public;
    function tryCloseLine(uint lineId, uint lastPlayerId, PaymentType paymentType) external returns (bool lineClosed);
}

contract BettingCore is BettingBase, Heritable {
    using SafeMath for uint;
    using strings for *;

    enum ActivityType{
        Soccer,
        IceHockey,
        Basketball,
        Tennis,
        BoxingAndMMA, 
        Formula1,               
        Volleyball,
        Chess,
        Athletics,
        Biathlon,
        Baseball,
        Rugby,
        AmericanFootball,
        Cycling,
        AutoMotorSports,        
        Other
    }    
    
    struct Activity {
        string title;
        ActivityType activityType;
    }

    struct Event {
        uint activityId;
        string title;
    }    

    struct Line {
        uint eventId;
        string title;
        string outcomes;
    }

    struct FeeDiscount {
        uint64 till;
        uint8 discount;
    }    

     
    bool public payoutToOwnerIsLimited;
     
    uint public blockedSum; 
    uint public fee;
    uint public minBetAmount;
    string public contractMessage;
   
    Activity[] public activities;
    Event[] public events;
    Line[] private lines;

    mapping(address => FeeDiscount) private discounts;

    event NewActivity(uint indexed activityId, ActivityType activityType, string title);
    event NewEvent(uint indexed activityId, uint indexed eventId, string title);
    event NewLine(uint indexed eventId, uint indexed lineId, string title, LineType lineType, uint start, string outcomes);     
    event BetMade(uint indexed lineId, uint betId, address indexed player, uint amount);
    event PlayerPaid(uint indexed lineId, address indexed player, uint amount);
    event ResultSubmitted(uint indexed lineId, uint[] results);
    event LineCanceled(uint indexed lineId, string comment);
    event LineClosed(uint indexed lineId, PaymentType paymentType, uint totalPool);
    event LineStartTimeChanged(uint indexed lineId, uint newTime);

    AbstractBetStorage private betStorage;

    function BettingCore() Heritable(2592000) public {
        minBetAmount = 5 finney;  
        fee = 200;  
        payoutToOwnerIsLimited = true;
        blockedSum = 1 wei;
        contractMessage = "betdapp.co";
    }

    function() external onlyOwner payable {
    }

    function addActivity(ActivityType activityType, string title) external onlyOwnerOr("Edit") returns (uint activityId) {
        Activity memory _activity = Activity({
            title: title, 
            activityType: activityType
        });

        activityId = activities.push(_activity) - 1;
        NewActivity(activityId, activityType, title);
    }

    function addDoubleChanceLine(uint eventId, string title, uint start) external onlyOwnerOr("Edit") {
        addLine(eventId, title, LineType.DoubleChance, start, "1X_12_X2");
    }

    function addEvent(uint activityId, string title) external onlyOwnerOr("Edit") returns (uint eventId) {
        Event memory _event = Event({
            activityId: activityId, 
            title: title
        });

        eventId = events.push(_event) - 1;
        NewEvent(activityId, eventId, title);      
    }

    function addThreeWayLine(uint eventId, string title, uint start) external onlyOwnerOr("Edit") {
        addLine(eventId, title, LineType.ThreeWay, start,  "1_X_2");
    }

    function addSomeOfManyLine(uint eventId, string title, uint start, string outcomes) external onlyOwnerOr("Edit") {
        addLine(eventId, title, LineType.SomeOfMany, start, outcomes);
    }

    function addTwoWayLine(uint eventId, string title, uint start, TwoWayLineType customType) external onlyOwnerOr("Edit") {
        string memory outcomes;

        if (customType == TwoWayLineType.YesNo) {
            outcomes = "Yes_No";
        } else if (customType == TwoWayLineType.OverUnder) {
            outcomes = "Over_Under";
        } else {
            outcomes = "1_2";
        }
        
        addLine(eventId, title, LineType.TwoWay, start, outcomes);
    }

    function bet(uint lineId, uint betId) external payable {
        uint amount = msg.value;
        require(amount >= minBetAmount);
        address player = msg.sender;
        betStorage.addBet(lineId, betId, player, amount);
        blockedSum = blockedSum.add(amount);
        BetMade(lineId, betId, player, amount);
    }

    function cancelLine(uint lineId, string comment) external onlyOwnerOr("Submit") {
        betStorage.cancelLine(lineId);
        LineCanceled(lineId, comment);
    }   

    function getMyBets(uint lineId) external view returns (uint[] result) {
        return getPlayerBets(lineId, msg.sender);
    }

    function getMyDiscount() external view returns (uint discount, uint till) {
        (discount, till) = getPlayerDiscount(msg.sender);
    }

    function getLineData(uint lineId) external view returns (uint eventId, string title, string outcomes, uint startTime, uint resultCount, LineType lineType, LineStages stage, BetStatus[] status, uint[] pool) {
        (startTime, resultCount, lineType, stage) = betStorage.getLineData(lineId);

        Line storage line = lines[lineId];
        eventId = line.eventId;
        title = line.title;
        outcomes = line.outcomes;
        status = new BetStatus[](resultCount);
        pool = new uint[](resultCount);

        for (uint i = 0; i < resultCount; i++) {
            (status[i], pool[i]) = betStorage.getBetPool(lineId, i);
        }
    }

    function getLineStat(uint lineId) external view returns (LineStages stage, BetStatus[] status, uint[] pool) {       
        uint resultCount;
        (resultCount, stage) = betStorage.getLineData2(lineId);
        status = new BetStatus[](resultCount);
        pool = new uint[](resultCount);

        for (uint i = 0; i < resultCount; i++) {
            (status[i], pool[i]) = betStorage.getBetPool(lineId, i);
        }
    }

     
    function kill() external onlyOwner {
        selfdestruct(msg.sender);
    }

    function payout(uint sum) external onlyOwner {
        require(sum > 0);
        require(!payoutToOwnerIsLimited || (this.balance - blockedSum) >= sum);
        msg.sender.transfer(sum);
    }    

    function payPlayers(uint lineId, uint chunkSize) external onlyOwnerOr("Pay") {
        uint startId;
        uint endId;
        PaymentType paymentType;
        uint luckyPool;
        uint unluckyPool;

        (paymentType, startId, endId, luckyPool, unluckyPool) = betStorage.startPayments(lineId, chunkSize);

        for (uint i = startId; i < endId; i++) {
            address player;
            uint amount; 
            (player, amount) = betStorage.getSumOfPlayerBetsById(lineId, i, paymentType);

            if (amount == 0) {
                continue;
            }

            uint payment;            
            
            if (paymentType == PaymentType.Gain) {
                payment = amount.add(amount.mul(unluckyPool).div(luckyPool)).div(10000).mul(10000 - getFee(player));

                if (payment < amount) {
                    payment = amount;
                }
            } else {
                payment = amount;               
            }

            if (payment > 0) {
                player.transfer(payment);
                PlayerPaid(lineId, player, payment);
            }
        }

        if (betStorage.tryCloseLine(lineId, endId, paymentType)) {
            uint totalPool = betStorage.getLineSum(lineId);
            blockedSum = blockedSum.sub(totalPool);
            LineClosed(lineId, paymentType, totalPool);
        }
    }
    
    function setContractMessage(string value) external onlyOwner {
        contractMessage = value;
    }    

    function setDiscountForPlayer(address player, uint discount, uint till) external onlyOwner {
        require(till > now && discount > 0 && discount <= 100);
        discounts[player].till = uint64(till);
        discounts[player].discount = uint8(discount);
    }

    function setFee(uint value) external onlyOwner {
         
        require(value >= 0 && value <= 500);
        fee = value;
    }

    function setLineStartTime(uint lineId, uint time) external onlyOwnerOr("Edit") {
        betStorage.setLineStartTime(lineId, time);
        LineStartTimeChanged(lineId, time);
    }    

    function setMinBetAmount(uint value) external onlyOwner {
        require(value > 0);
        minBetAmount = value;
    }

     
     
    function setPayoutLimit(bool value) external onlyOwner {
        payoutToOwnerIsLimited = value;
    }

    function setStorage(address contractAddress) external onlyOwner {        
        AbstractBetStorage candidateContract = AbstractBetStorage(contractAddress);
        require(candidateContract.isBetStorage());
        betStorage = candidateContract;
         
    }

    function setStorageOwner(address newOwner) external onlyOwner {
        betStorage.transferOwnership(newOwner);
    }    

    function submitResult(uint lineId, uint[] results) external onlyOwnerOr("Submit") {
        betStorage.submitResult(lineId, results);
        ResultSubmitted(lineId, results);
    }    

    function addLine(uint eventId, string title, LineType lineType, uint start, string outcomes) private {
        require(start > now);

        Line memory line = Line({
            eventId: eventId, 
            title: title, 
            outcomes: outcomes
        });

        uint lineId = lines.push(line) - 1;
        uint resultCount;

        if (lineType == LineType.ThreeWay || lineType == LineType.DoubleChance) {
            resultCount = 3;           
        } else if (lineType == LineType.TwoWay) {
            resultCount = 2; 
        } else {
            resultCount = getSplitCount(outcomes);
        }       

        betStorage.addLine(lineId, lineType, start, resultCount);
        NewLine(eventId, lineId, title, lineType, start, outcomes);
    }

    function getFee(address player) private view returns (uint newFee) {
        var data = discounts[player];

        if (data.till > now) {
            return fee * (100 - data.discount) / 100;
        }

        return fee;
    }    

    function getPlayerBets(uint lineId, address player) private view returns (uint[] result) {
        Line storage line = lines[lineId];
        uint count = getSplitCount(line.outcomes);
        result = new uint[](count);

        for (uint i = 0; i < count; i++) {
            result[i] = betStorage.getPlayerBet(lineId, i, player);
        }
    }

    function getPlayerDiscount(address player) private view returns (uint discount, uint till) {
        FeeDiscount storage discountFee = discounts[player];
        discount = discountFee.discount;
        till = discountFee.till;
    }    

    function getSplitCount(string input) private returns (uint) { 
        var s = input.toSlice();
        var delim = "_".toSlice();
        var parts = new string[](s.count(delim) + 1);

        for (uint i = 0; i < parts.length; i++) {
            parts[i] = s.split(delim).toString();
        }

        return parts.length;
    }
}