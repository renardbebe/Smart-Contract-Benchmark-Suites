 

 
 

contract OraclizeI {
    address public cbAddress;
    function query(uint _timestamp, string _datasource, string _arg) returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) returns (bytes32 _id);
    function query2(uint _timestamp, string _datasource, string _arg1, string _arg2) returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string _datasource, string _arg1, string _arg2, uint _gaslimit) returns (bytes32 _id);
    function getPrice(string _datasource) returns (uint _dsprice);
    function getPrice(string _datasource, uint gaslimit) returns (uint _dsprice);
    function useCoupon(string _coupon);
    function setProofType(byte _proofType);
}
contract OraclizeAddrResolverI {
    function getAddress() returns (address _addr);
}
contract usingOraclize {
    uint constant day = 60*60*24;
    uint constant week = 60*60*24*7;
    uint constant month = 60*60*24*30;
    byte constant proofType_NONE = 0x00;
    byte constant proofType_TLSNotary = 0x10;
    byte constant proofStorage_IPFS = 0x01;
    uint8 constant networkID_auto = 0;
    uint8 constant networkID_mainnet = 1;
    uint8 constant networkID_testnet = 2;
    uint8 constant networkID_morden = 2;
    uint8 constant networkID_consensys = 161;

    OraclizeAddrResolverI OAR;
    
    OraclizeI oraclize;
    modifier oraclizeAPI {
        address oraclizeAddr = OAR.getAddress();
        if (oraclizeAddr == 0){
            oraclize_setNetwork(networkID_auto);
            oraclizeAddr = OAR.getAddress();
        }
        oraclize = OraclizeI(oraclizeAddr);
        _
    }
    modifier coupon(string code){
        oraclize = OraclizeI(OAR.getAddress());
        oraclize.useCoupon(code);
        _
    }

    function oraclize_setNetwork(uint8 networkID) internal returns(bool){
        if (getCodeSize(0x1d3b2638a7cc9f2cb3d298a3da7a90b67e5506ed)>0){
            OAR = OraclizeAddrResolverI(0x1d3b2638a7cc9f2cb3d298a3da7a90b67e5506ed);
            return true;
        }
        if (getCodeSize(0x9efbea6358bed926b293d2ce63a730d6d98d43dd)>0){
            OAR = OraclizeAddrResolverI(0x9efbea6358bed926b293d2ce63a730d6d98d43dd);
            return true;
        }
        if (getCodeSize(0x20e12a1f859b3feae5fb2a0a32c18f5a65555bbf)>0){
            OAR = OraclizeAddrResolverI(0x20e12a1f859b3feae5fb2a0a32c18f5a65555bbf);
            return true;
        }
        return false;
    }
    
    function oraclize_query(string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        return oraclize.query.value(price)(0, datasource, arg);
    }
    function oraclize_query(uint timestamp, string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        return oraclize.query.value(price)(timestamp, datasource, arg);
    }
    function oraclize_query(uint timestamp, string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        return oraclize.query_withGasLimit.value(price)(timestamp, datasource, arg, gaslimit);
    }
    function oraclize_query(string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        return oraclize.query_withGasLimit.value(price)(0, datasource, arg, gaslimit);
    }
    function oraclize_query(string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        return oraclize.query2.value(price)(0, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        return oraclize.query2.value(price)(timestamp, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        return oraclize.query2_withGasLimit.value(price)(timestamp, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_query(string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        return oraclize.query2_withGasLimit.value(price)(0, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_cbAddress() oraclizeAPI internal returns (address){
        return oraclize.cbAddress();
    }
    function oraclize_setProof(byte proofP) oraclizeAPI internal {
        return oraclize.setProofType(proofP);
    }

    function getCodeSize(address _addr) constant internal returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }


    function parseAddr(string _a) internal returns (address){
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i=2; i<2+2*20; i+=2){
            iaddr *= 256;
            b1 = uint160(tmp[i]);
            b2 = uint160(tmp[i+1]);
            if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;
            else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;
            if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;
            else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;
            iaddr += (b1*16+b2);
        }
        return address(iaddr);
    }


    function strCompare(string _a, string _b) internal returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
   } 

    function indexOf(string _haystack, string _needle) internal returns (int)
    {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if(h.length < 1 || n.length < 1 || (n.length > h.length)) 
            return -1;
        else if(h.length > (2**128 -1))
            return -1;                                  
        else
        {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i ++)
            {
                if (h[i] == n[0])
                {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex])
                    {
                        subindex++;
                    }   
                    if(subindex == n.length)
                        return int(i);
                }
            }
            return -1;
        }   
    }

    function strConcat(string _a, string _b, string _c, string _d, string _e) internal returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }
    
    function strConcat(string _a, string _b, string _c, string _d) internal returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

     
    function parseInt(string _a) internal returns (uint) {
        return parseInt(_a, 0);
    }

     
    function parseInt(string _a, uint _b) internal returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i=0; i<bresult.length; i++){
            if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
                if (decimals){
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) mint *= 10**_b;
        return mint;
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

     
    function len(slice self) internal returns (uint) {
         
        var ptr = self._ptr - 31;
        var end = ptr + self._len;
        for (uint len = 0; ptr < end; len++) {
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
        return len;
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
        uint len;
        uint div = 2 ** 248;

         
        assembly { word:= mload(mload(add(self, 32))) }
        var b = word / div;
        if (b < 0x80) {
            ret = b;
            len = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            len = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            len = 3;
        } else {
            ret = b & 0x07;
            len = 4;
        }

         
        if (len > self._len) {
            return 0;
        }

        for (uint i = 1; i < len; i++) {
            div = div / 256;
            b = (word / div) & 0xFF;
            if (b & 0xC0 != 0x80) {
                 
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

     
    function keccak(slice self) internal returns (bytes32 ret) {
        assembly {
            ret := sha3(mload(add(self, 32)), mload(self))
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
            let len := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(sha3(selfptr, len), sha3(needleptr, len))
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
                let len := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(sha3(selfptr, len), sha3(needleptr, len))
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
            let len := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(sha3(selfptr, len), sha3(needleptr, len))
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
                let len := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(sha3(selfptr, len), sha3(needleptr, len))
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

     
    function count(slice self, slice needle) internal returns (uint count) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            count++;
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

        uint len = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            len += parts[i]._len;

        var ret = new string(len);
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


contract mortal {
    address owner;

    function mortal() {
        owner = msg.sender;
    }

    function kill() internal{
        suicide(owner);
    }
}

contract Pray4Prey is mortal, usingOraclize {
	using strings for *;
	
     
    mapping(address => uint128) winBalances;
     
    address[] public players;
     
    uint16 public numPlayers;
    
     
    mapping(uint8 => address[]) animals;
     
    uint128[] public costs;
     
    uint128[] public values;
     
    uint8[] probabilityFactors;
     
    uint8[] public fees;

     
    
   
    
     
    uint16 public numAnimals;
     
    uint16 public maxAnimals;
     
    mapping(address => uint8) numAnimalsXPlayer;
     
    mapping(uint8 => uint16) numAnimalsXType;

    
     
    string randomQuery;
     
    uint public nextAttackTimestamp;
     
    uint32 public oraclizeGas;
     
    bytes32 nextAttackId;
    
    
     
    event newPurchase(address player, uint8 animalType, uint8 amount);
     
    event newExit(address player, uint256 totalBalance);
     
    event newAttack();
    
    
     
    function Pray4Prey(uint128[] animalCosts, uint8[] gameFees) {
        costs = animalCosts;
        fees = gameFees;
        for(uint8 i = 0; i< costs.length; i++){
            values.push(costs[i]-costs[i]/100*fees[i]);
            probabilityFactors.push(uint8(costs[costs.length-i-1]/costs[0]));
        }
        maxAnimals = 3000;
        randomQuery = "https://www.random.org/integers/?num=10&min=0&max=10000&col=1&base=10&format=plain&rnd=new";
        oraclizeGas=550000;
    }
    
      
     function (){
         for(uint8 i = 0; i < costs.length; i++)
            if(msg.value==costs[i])
                addAnimals(i);
                
        if(msg.value==1000000000000000)
            exit();
        else
            throw;
            
     }
     
      
     function addAnimals(uint8 animalType){
        uint8 amount = uint8(msg.value/costs[animalType]);
        if(animalType >= costs.length || msg.value<costs[animalType] || numAnimalsXPlayer[msg.sender]+amount>50 || numAnimals+amount>=maxAnimals) throw;
         
        if(numAnimalsXPlayer[msg.sender]==0) 
            addPlayer();
        for(uint8 j = 0; j<amount; j++){
            addAnimal(animalType);
        }
        numAnimals+=amount;
        numAnimalsXPlayer[msg.sender]+=amount;
         
        winBalances[msg.sender]+=uint128(msg.value*(100-fees[animalType])/100);
        newPurchase(msg.sender, animalType, j);
        
     }
     
      
     function addAnimal(uint8 animalType) internal{
        if(numAnimalsXType[animalType]<animals[animalType].length)
            animals[animalType][numAnimalsXType[animalType]]=msg.sender;
        else
            animals[animalType].push(msg.sender);
        numAnimalsXType[animalType]++;
     }
     
  
     
      
     function addPlayer() internal{
        if(numPlayers<players.length)
            players[numPlayers]=msg.sender;
        else
            players.push(msg.sender);
        numPlayers++;
     }
     
      
     function deletePlayer(address playerAddress) internal{
         for(uint16 i  = 0; i < numPlayers; i++)
             if(players[i]==playerAddress){
                numPlayers--;
                players[i]=players[numPlayers];
                delete players[numPlayers];
                return;
             }
     }
     
     
      
    function exit(){
    	cleanUp(msg.sender); 
        newExit(msg.sender, winBalances[msg.sender]);  
        if(!payout(msg.sender)) throw;
        delete winBalances[msg.sender];
        deletePlayer(msg.sender);
    }
    
     
    function cleanUp(address playerAddress) internal{
    	for(uint8 animalType = 0;  animalType< costs.length;  animalType++){ 
    	    if(numAnimalsXType[animalType]>0){
                for(uint16 i = 0; i < numAnimalsXType[animalType]; i++){
                    if(animals[animalType][i] == playerAddress){
                       replaceAnimal(animalType,i, true);
                    }
                }
    	    }
        }
        numAnimals-=numAnimalsXPlayer[playerAddress];
        delete numAnimalsXPlayer[playerAddress];
    }
    
    
     
    function replaceAnimal(uint8 animalType, uint16 index, bool exit) internal{
        if(exit){ 
            while(animals[animalType][numAnimalsXType[animalType]-1]==animals[animalType][index]){
                numAnimalsXType[animalType]--;
                delete animals[animalType][numAnimalsXType[animalType]];
                if(numAnimalsXType[animalType]==index)
                    return;
            }
        }
        numAnimalsXType[animalType]--;
		animals[animalType][index]=animals[animalType][numAnimalsXType[animalType]];
		delete animals[animalType][numAnimalsXType[animalType]]; 
    }
    
    
    
     
    function payout(address playerAddress) internal returns(bool){
        return playerAddress.send(winBalances[playerAddress]);
    }

    
     
    function triggerAttackManually(uint32 inseconds){
        if(!(msg.sender==owner && nextAttackTimestamp < now+300)) throw;
        triggerAttack(inseconds);
    }
    
     
    function triggerAttack(uint32 inseconds) internal{
    	nextAttackTimestamp = now+inseconds;
    	nextAttackId = oraclize_query(nextAttackTimestamp, "URL", randomQuery, oraclizeGas+6000*numPlayers);
    }
    
     
    function __callback(bytes32 myid, string result) {
        if (msg.sender != oraclize_cbAddress()||myid!=nextAttackId) throw;  
        
        uint16[] memory ranges = new uint16[](costs.length+1);
        ranges[0] = 0;
        for(uint8 animalType = 0; animalType < costs.length; animalType ++){
            ranges[animalType+1] = ranges[animalType]+uint16(probabilityFactors[animalType]*numAnimalsXType[animalType]); 
        }     
        uint128 pot;
        uint16 random;        
        uint16 howmany = numAnimals<100?(numAnimals<10?1:numAnimals/10):10; 
        uint16[] memory randomNumbers = getNumbersFromString(result,"\n", howmany);
        for(uint8 i = 0; i < howmany; i++){
            random = mapToNewRange(randomNumbers[i], ranges[costs.length]);
            for(animalType = 0; animalType < costs.length; animalType ++)
                if (random < ranges[animalType+1]){
                    pot+= killAnimal(animalType, (random-ranges[animalType])/probabilityFactors[animalType]);
                    break;
                }
        }
        numAnimals-=howmany;
        newAttack();
        if(pot>uint128(oraclizeGas*tx.gasprice))
            distribute(uint128(pot-oraclizeGas*tx.gasprice)); 
        triggerAttack(timeTillNextAttack());
    }
    
     
    function timeTillNextAttack() constant internal returns(uint32){
        return (86400/(1+numAnimals/100));
    }
    

     
    function killAnimal(uint8 animalType, uint16 index) internal returns(uint128){
        address preyOwner = animals[animalType][index];

        replaceAnimal(animalType,index,false);
        numAnimalsXPlayer[preyOwner]--;
        
         
         
        if(numAnimalsXPlayer[preyOwner]>0){
        	winBalances[preyOwner]-=values[animalType];
            return values[animalType];
        }
         
        else{
            uint128 bounty = winBalances[preyOwner];
            delete winBalances[preyOwner];
            deletePlayer(preyOwner);
            return bounty;
        }

    }
    
    
     
    function distribute(uint128 amount) internal{
        uint128 share = amount/numAnimals;
        for(uint16 i = 0; i < numPlayers; i++){
            winBalances[players[i]]+=share*numAnimalsXPlayer[players[i]];
        }
    }
    
     
    function collectFees(uint128 amount){
        if(!(msg.sender==owner)) throw;
        uint collectedFees = getFees();
        if(amount + 100 finney < collectedFees){
            if(!owner.send(amount)) throw;
        }
    }
    
     
    function stop(){
        if(!(msg.sender==owner)) throw;
        for(uint16 i = 0; i< numPlayers; i++){
            payout(players[i]);
        }
        kill();
    }
    
     
    function addAnimalType(uint128 cost, uint8 fee){
        if(!(msg.sender==owner)||cost<costs[0]||costs.length>=100) throw;
        costs.push(cost);
        fees.push(fee);
        values.push(cost/100*fee);
        probabilityFactors.push(uint8(cost/costs[0]));
    }
    
 
   
    
    
    
    function getWinBalancesOf(address playerAddress) constant returns(uint128){
        return winBalances[playerAddress];
    }
    
    function getAnimals(uint8 animalType) constant returns(address[]){
        return animals[animalType];
    }
    
    function getFees() constant returns(uint){
        uint reserved = 0;
        for(uint16 j = 0; j< numPlayers; j++)
            reserved+=winBalances[players[j]];
        return address(this).balance - reserved;
    }

    function getNumAnimalsXType(uint8 animalType) constant returns(uint16){
        return numAnimalsXType[animalType];
    }
    
    function getNumAnimalsXPlayer(address playerAddress) constant returns(uint16){
        return numAnimalsXPlayer[playerAddress];
    }
    
    
     
    
    function setOraclizeGas(uint32 newGas){
        if(!(msg.sender==owner)) throw;
    	oraclizeGas = newGas;
    }
    
    function setMaxAnimals(uint16 number){
        if(!(msg.sender==owner)) throw;
    	maxAnimals = number;
    }
    
     

     
    function mapToNewRange(uint number, uint range) constant internal returns (uint16 randomNumber) {
        return uint16(number*range / 10000);
    }
    
     
     function getNumbersFromString(string s, string delimiter, uint16 howmany) constant internal returns(uint16[] numbers){
         strings.slice memory myresult = s.toSlice();
         strings.slice memory delim = delimiter.toSlice();
         numbers = new uint16[](howmany);
         for(uint8 i = 0; i < howmany; i++){
             numbers[i]= uint16(parseInt(myresult.split(delim).toString())); 
         }
         return numbers;
     }
    
}