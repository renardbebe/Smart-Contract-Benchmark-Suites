 

pragma solidity ^0.4.24;


 



library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
         
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

     
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

     
    function len(bytes32 self) internal pure returns (uint) {
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

     
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
         
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

     
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

     
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

     
    function len(slice memory self) internal pure returns (uint l) {
         
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
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

     
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

     
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                 
                uint256 mask = uint256(-1);  
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                uint256 diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

     
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

     
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
         
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

         
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

     
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

     
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

         
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
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

     
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

     
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
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

     
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

     
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

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

     
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
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

     
     
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                 
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

     
     
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                 
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

     
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

     
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

     
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
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

     
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

     
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
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

     
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

     
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

     
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

     
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

     
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
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

contract Control {
    using strings for *;

    uint constant REWARD_BASE = 100;
    uint constant REWARD_TAX = 8;
    uint constant REWARD_GET = REWARD_BASE - REWARD_TAX;
    uint constant MAX_ALLBET = 2**120; 
    uint constant MIN_BET = 0.001 ether;

    bytes32 constant SHA_DEUCE = keccak256("DEUCE");

    address internal creator;
    address internal owner;
    uint public destroy_time;

    constructor(address target)
    public {
        creator = msg.sender;
        owner = target;
         
        destroy_time = now + 365 * 24 * 60 * 60;
    }

    function kill()
    external payable {
        require(now >= destroy_time);
        selfdestruct(owner);
    }

    struct PlayerBet {
        uint bet0;  
        uint bet1;
        uint bet2;
        bool drawed;
    }

    struct MatchBet {
        uint betDeadline;
        uint allbet;
        uint allbet0; 
        uint allbet1;
        uint allbet2;
        bool ownerDrawed;
        bytes32 SHA_WIN;
        bytes32 SHA_T1;
        bytes32 SHA_T2;
        mapping(address => PlayerBet) list;
    }

    MatchBet[] public MatchList;

    modifier onlyOwner() {
        require(msg.sender == creator || msg.sender == owner);
        _;
    }

    modifier MatchExist(uint index) {
        require(index < MatchList.length);
        _;
    }

    function AddMatch(string troop1, string troop2, uint deadline)
    external
    onlyOwner {
        MatchList.push(MatchBet({
            betDeadline :deadline,
            allbet      :0,
            allbet0     :0,
            allbet1     :0,
            allbet2     :0,
            ownerDrawed :false,
            SHA_T1      :keccak256(bytes(troop1)),
            SHA_T2      :keccak256(bytes(troop2)),
            SHA_WIN     :bytes32(0)
        }));
    }

     
    function MatchResetDeadline(uint index,uint time)
    external
    onlyOwner MatchExist(index) {
        MatchBet storage oMatch = MatchList[index];
        oMatch.betDeadline = time;
    }

    function MatchEnd(uint index,string winTroop)
    external
    onlyOwner MatchExist(index) {
        MatchBet storage oMatch = MatchList[index];
        require(oMatch.SHA_WIN == 0);
        bytes32 shaWin = keccak256(bytes(winTroop));
        require(shaWin == SHA_DEUCE || shaWin == oMatch.SHA_T1 || shaWin == oMatch.SHA_T2 );
        oMatch.SHA_WIN = shaWin;
    }

    function Bet(uint index, string troop)
    external payable
    MatchExist(index) {
         
        require(msg.value >= MIN_BET);

        MatchBet storage oMatch = MatchList[index];

         
        require(oMatch.SHA_WIN == 0 && oMatch.betDeadline >= now);

        uint tempAllBet = oMatch.allbet + msg.value;
         
        require(tempAllBet > oMatch.allbet && tempAllBet <= MAX_ALLBET);

        PlayerBet storage oBet = oMatch.list[msg.sender];
        oMatch.allbet = tempAllBet;
        bytes32 shaBetTroop = keccak256(bytes(troop));
        if ( shaBetTroop == oMatch.SHA_T1 ) {
            oBet.bet1 += msg.value;
            oMatch.allbet1 += msg.value;
        }
        else if ( shaBetTroop == oMatch.SHA_T2 ) {
            oBet.bet2 += msg.value;
            oMatch.allbet2 += msg.value;
        }
        else {
            require( shaBetTroop == SHA_DEUCE );
            oBet.bet0 += msg.value;
            oMatch.allbet0 += msg.value;
        }
    }

    function CalReward(MatchBet storage oMatch,PlayerBet storage oBet)
    internal view
    returns(uint) {
        uint myWinBet;
        uint allWinBet;
        if ( oMatch.SHA_WIN == oMatch.SHA_T1) {
            myWinBet = oBet.bet1;
            allWinBet = oMatch.allbet1;
        }
        else if ( oMatch.SHA_WIN == oMatch.SHA_T2 ) {
            myWinBet = oBet.bet2;
            allWinBet = oMatch.allbet2;
        }
        else {
            myWinBet = oBet.bet0;
            allWinBet = oMatch.allbet0;
        }
        if (myWinBet == 0) return 0;
        return myWinBet + (oMatch.allbet - allWinBet) * myWinBet / allWinBet * REWARD_GET / REWARD_BASE;
    }

    function Withdraw(uint index,address target)
    public payable
    MatchExist(index) {
        MatchBet storage oMatch = MatchList[index];
        PlayerBet storage oBet = oMatch.list[target];
        if (oBet.drawed) return;
        if (oMatch.SHA_WIN == 0) return;
        uint reward = CalReward(oMatch,oBet);
        if (reward == 0) return;
        oBet.drawed = true;
        target.transfer(reward);
    }

    function WithdrawAll(address target)
    external payable {
        for (uint i=0; i<MatchList.length; i++) {
            Withdraw(i,target);
        }
    }

    function CreatorWithdraw(uint index)
    internal {
        MatchBet storage oMatch = MatchList[index];
        if (oMatch.ownerDrawed) return;
        if (oMatch.SHA_WIN == 0) return;
        oMatch.ownerDrawed = true;
        uint allWinBet;
        if ( oMatch.SHA_WIN == oMatch.SHA_T1) {
            allWinBet = oMatch.allbet1;
        }
        else if ( oMatch.SHA_WIN == oMatch.SHA_T2 ) {
            allWinBet = oMatch.allbet2;
        }
        else {
            allWinBet = oMatch.allbet0;
        }
        if (oMatch.allbet == allWinBet) return;
        if (allWinBet == 0) {
             
            owner.transfer(oMatch.allbet);
        }
        else {
             
            uint alltax = (oMatch.allbet - allWinBet) * REWARD_TAX / REWARD_BASE;
            owner.transfer(alltax);
        }
    }

    function CreatorWithdrawAll()
    external payable {
        for (uint i=0; i<MatchList.length; i++) {
            CreatorWithdraw(i);
        }
    }

    function GetMatchLength()
    external view
    returns(uint) {
        return MatchList.length;
    }

    function uint2str(uint i)
    internal pure
    returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        while (i != 0){
            bstr[--len] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

    function GetInfo(MatchBet storage obj,uint idx,address target)
    internal view
    returns(string){
        PlayerBet storage oBet = obj.list[target];
        string memory info = "#";
        info = info.toSlice().concat(uint2str(idx).toSlice());
        info = info.toSlice().concat(",".toSlice()).toSlice().concat(uint2str(oBet.bet1).toSlice());
        info = info.toSlice().concat(",".toSlice()).toSlice().concat(uint2str(obj.allbet1).toSlice());
        info = info.toSlice().concat(",".toSlice()).toSlice().concat(uint2str(oBet.bet2).toSlice());
        info = info.toSlice().concat(",".toSlice()).toSlice().concat(uint2str(obj.allbet2).toSlice());
        info = info.toSlice().concat(",".toSlice()).toSlice().concat(uint2str(oBet.bet0).toSlice());
        info = info.toSlice().concat(",".toSlice()).toSlice().concat(uint2str(obj.allbet0).toSlice());
        if (oBet.drawed) {
            info = info.toSlice().concat(",".toSlice()).toSlice().concat("1".toSlice());
        }
        else {
            info = info.toSlice().concat(",".toSlice()).toSlice().concat("0".toSlice());
        }
        return info;
    }

    function GetDetail(address target)
    external view
    returns(string) {
        string memory res;
        for (uint i=0; i<MatchList.length; i++){
            res = res.toSlice().concat(GetInfo(MatchList[i],i,target).toSlice());
        }
        return res;
    }

}