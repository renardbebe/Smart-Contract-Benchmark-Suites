 

pragma solidity ^0.4.8;

 
 


contract OraclizeI {
    address public cbAddress;
    function query(uint _timestamp, string _datasource, string _arg) payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) payable returns (bytes32 _id);
    function query2(uint _timestamp, string _datasource, string _arg1, string _arg2) payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string _datasource, string _arg1, string _arg2, uint _gaslimit) payable returns (bytes32 _id);
    function getPrice(string _datasource) returns (uint _dsprice);
    function getPrice(string _datasource, uint gaslimit) returns (uint _dsprice);
    function useCoupon(string _coupon);
    function setProofType(byte _proofType);
    function setConfig(bytes32 _config);
    function setCustomGasPrice(uint _gasPrice);
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
        if(address(OAR)==0) oraclize_setNetwork(networkID_auto);
        oraclize = OraclizeI(OAR.getAddress());
        _;
    }
    modifier coupon(string code){
        oraclize = OraclizeI(OAR.getAddress());
        oraclize.useCoupon(code);
        _;
    }

    function oraclize_setNetwork(uint8 networkID) internal returns(bool){
        if (getCodeSize(0x1d3b2638a7cc9f2cb3d298a3da7a90b67e5506ed)>0){  
            OAR = OraclizeAddrResolverI(0x1d3b2638a7cc9f2cb3d298a3da7a90b67e5506ed);
            return true;
        }
        if (getCodeSize(0xc03a2615d5efaf5f49f60b7bb6583eaec212fdf1)>0){  
            OAR = OraclizeAddrResolverI(0xc03a2615d5efaf5f49f60b7bb6583eaec212fdf1);
            return true;
        }
        if (getCodeSize(0x20e12a1f859b3feae5fb2a0a32c18f5a65555bbf)>0){  
            OAR = OraclizeAddrResolverI(0x20e12a1f859b3feae5fb2a0a32c18f5a65555bbf);
            return true;
        }
        if (getCodeSize(0x93bbbe5ce77034e3095f0479919962a903f898ad)>0){  
            OAR = OraclizeAddrResolverI(0x93bbbe5ce77034e3095f0479919962a903f898ad);
            return true;
        }
        if (getCodeSize(0x51efaf4c8b3c9afbd5ab9f4bbc82784ab6ef8faa)>0){  
            OAR = OraclizeAddrResolverI(0x51efaf4c8b3c9afbd5ab9f4bbc82784ab6ef8faa);
            return true;
        }
        return false;
    }
    
    function __callback(bytes32 myid, string result) {
        __callback(myid, result, new bytes(0));
    }
    function __callback(bytes32 myid, string result, bytes proof) {
    }
    
    function oraclize_getPrice(string datasource) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource);
    }
    function oraclize_getPrice(string datasource, uint gaslimit) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource, gaslimit);
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
    function oraclize_setCustomGasPrice(uint gasPrice) oraclizeAPI internal {
        return oraclize.setCustomGasPrice(gasPrice);
    }    
    function oraclize_setConfig(bytes32 config) oraclizeAPI internal {
        return oraclize.setConfig(config);
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
    
    function uint2str(uint i) internal returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }
    
    

}
 



contract mortal {
	address owner;

	function mortal() {
		owner = msg.sender;
	}

	function kill() internal {
		suicide(owner);
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

      
      

contract transferable {
	function receive(address player, uint8 animalType, uint32[] animalIds) payable {}
}

contract Pray4Prey is mortal, usingOraclize, transferable {
	using strings
	for * ;

	struct Animal {
		uint8 animalType;
		uint128 value;
		address owner;
	}

	 
	uint32[] public ids;
	 
	uint32 public nextId;
	 
	uint32 public oldest;
	 
	mapping(uint32 => Animal) animals;
	 
	uint128[] public costs;
	 
	uint128[] public values;
	 
	uint8 fee;
	 
	address lastP4P;

	 
	uint32 public numAnimals;
	 
	uint16 public maxAnimals;
	 
	mapping(uint8 => uint16) public numAnimalsXType;


	 
	string randomQuery;
	 
	string queryType;
	 
	uint public nextAttackTimestamp;
	 
	uint32 public oraclizeGas;
	 
	bytes32 nextAttackId;


	 
	event newPurchase(address player, uint8 animalType, uint8 amount, uint32 startId);
	 
	event newExit(address player, uint256 totalBalance, uint32[] removedAnimals);
	 
	event newAttack(uint32[] killedAnimals);
	 
	event newSell(uint32 animalId, address player, uint256 value);


	 
	function init(address oldContract) {
		if(msg.sender != owner) throw;
		costs = [100000000000000000, 200000000000000000, 500000000000000000, 1000000000000000000, 5000000000000000000];
		fee = 5;
		for (uint8 i = 0; i < costs.length; i++) {
			values.push(costs[i] - costs[i] / 100 * fee);
		}
		maxAnimals = 300;
		randomQuery = "10 random numbers between 1 and 1000";
		queryType = "WolframAlpha";
		oraclizeGas = 700000;
		lastP4P = oldContract;  
		nextId = 500;
		oldest = 500;
	}

	 
	function() payable {
		for (uint8 i = 0; i < costs.length; i++)
			if (msg.value == costs[i])
				addAnimals(i);

		if (msg.value == 1000000000000000)
			exit();
		else
			throw;

	}

	 
	function addAnimals(uint8 animalType) payable {
		giveAnimals(animalType, msg.sender);
	}

	 
	function giveAnimals(uint8 animalType, address receiver) payable {
		uint8 amount = uint8(msg.value / costs[animalType]);
		if (animalType >= costs.length || msg.value < costs[animalType] || numAnimals + amount >= maxAnimals) throw;
		 
		for (uint8 j = 0; j < amount; j++) {
			addAnimal(animalType, receiver, nextId);
			nextId++;
		}
		numAnimalsXType[animalType] += amount;
		newPurchase(receiver, animalType, amount, nextId - amount);
	}

	 
	function addAnimal(uint8 animalType, address receiver, uint32 nId) internal {
		if (numAnimals < ids.length)
			ids[numAnimals] = nId;
		else
			ids.push(nId);
		animals[nId] = Animal(animalType, values[animalType], receiver);
		numAnimals++;
	}



	 
	function exit() {
		uint32[] memory removed = new uint32[](50);
		uint8 count;
		uint32 lastId;
		uint playerBalance;
		for (uint16 i = 0; i < numAnimals; i++) {
			if (animals[ids[i]].owner == msg.sender) {
				 
				while (numAnimals > 0 && animals[ids[numAnimals - 1]].owner == msg.sender) {
					numAnimals--;
					lastId = ids[numAnimals];
					numAnimalsXType[animals[lastId].animalType]--;
					playerBalance += animals[lastId].value;
					removed[count] = lastId;
					count++;
					if (lastId == oldest) oldest = 0;
					delete animals[lastId];
				}
				 
				if (numAnimals > i + 1) {
					playerBalance += animals[ids[i]].value;
					removed[count] = ids[i];
					count++;
					replaceAnimal(i);
				}
			}
		}
		newExit(msg.sender, playerBalance, removed);  
		if (!msg.sender.send(playerBalance)) throw;
	}


	 
	function replaceAnimal(uint16 index) internal {
		uint32 animalId = ids[index];
		numAnimalsXType[animals[animalId].animalType]--;
		numAnimals--;
		if (animalId == oldest) oldest = 0;
		delete animals[animalId];
		ids[index] = ids[numAnimals];
		delete ids[numAnimals];
	}


	 
	function triggerAttackManually(uint32 inseconds) {
		if (!(msg.sender == owner && nextAttackTimestamp < now + 300)) throw;
		triggerAttack(inseconds, (oraclizeGas + 10000 * numAnimals));
	}

	 
	function triggerAttack(uint32 inseconds, uint128 gasAmount) internal {
		nextAttackTimestamp = now + inseconds;
		nextAttackId = oraclize_query(nextAttackTimestamp, queryType, randomQuery, gasAmount);
	}

	 
	function __callback(bytes32 myid, string result) {
		if (msg.sender != oraclize_cbAddress() || myid != nextAttackId) throw;  
		uint128 pot;
		uint16 random;
		uint32 howmany = numAnimals < 100 ? (numAnimals < 10 ? 1 : numAnimals / 10) : 10;  
		uint16[] memory randomNumbers = getNumbersFromString(result, ",", howmany);
		uint32[] memory killedAnimals = new uint32[](howmany);
		for (uint8 i = 0; i < howmany; i++) {
			random = mapToNewRange(randomNumbers[i], numAnimals);
			killedAnimals[i] = ids[random];
			pot += killAnimal(random);
		}
		uint128 neededGas = oraclizeGas + 10000 * numAnimals;
		uint128 gasCost = uint128(neededGas * tx.gasprice);
		if (pot > gasCost)
			distribute(uint128(pot - gasCost));  
		triggerAttack(timeTillNextAttack(), neededGas);
		newAttack(killedAnimals);
	}

	 
	function timeTillNextAttack() constant internal returns(uint32) {
		return (86400 / (1 + numAnimals / 100));
	}


	 
	function killAnimal(uint16 index) internal returns(uint128 animalValue) {
		animalValue = animals[ids[index]].value;
		replaceAnimal(index);
	}

	 
	function findOldest() {
		oldest = ids[0];
		for (uint16 i = 1; i < numAnimals; i++) {
			if (ids[i] < oldest)  
				oldest = ids[i];
		}
	}


	 
	function distribute(uint128 totalAmount) internal {
		 
		if (oldest == 0)
			findOldest();
		animals[oldest].value += totalAmount / 10;
		uint128 amount = totalAmount / 10 * 9;
		 
		uint128 valueSum;
		uint128[] memory shares = new uint128[](values.length);
		for (uint8 v = 0; v < values.length; v++) {
			if (numAnimalsXType[v] > 0) valueSum += values[v];
		}
		for (uint8 m = 0; m < values.length; m++) {
			if (numAnimalsXType[m] > 0)
				shares[m] = amount * values[m] / valueSum / numAnimalsXType[m];
		}
		for (uint16 i = 0; i < numAnimals; i++) {
			animals[ids[i]].value += shares[animals[ids[i]].animalType];
		}

	}

	 
	function collectFees(uint128 amount) {
		if (!(msg.sender == owner)) throw;
		uint collectedFees = getFees();
		if (amount + 100 finney < collectedFees) {
			if (!owner.send(amount)) throw;
		}
	}

	 
	function stop() {
		if (!(msg.sender == owner)) throw;
		for (uint16 i = 0; i < numAnimals; i++) {
			if(!animals[ids[i]].owner.send(animals[ids[i]].value)) throw;
		}
		kill();
	}


	 
	function sellAnimal(uint32 animalId) {
		if (msg.sender != animals[animalId].owner) throw;
		uint128 val = animals[animalId].value;
		uint16 animalIndex;
		for (uint16 i = 0; i < ids.length; i++) {
			if (ids[i] == animalId) {
				animalIndex = i;
				break;
			}
		}
		replaceAnimal(animalIndex);
		if (!msg.sender.send(val)) throw;
		newSell(animalId, msg.sender, val);
	}

	 
	function transfer(address contractAddress) {
		transferable newP4P = transferable(contractAddress);
		uint8[] memory numXType = new uint8[](costs.length);
		mapping(uint16 => uint32[]) tids;
		uint winnings;

		for (uint16 i = 0; i < numAnimals; i++) {

			if (animals[ids[i]].owner == msg.sender) {
				Animal a = animals[ids[i]];
				numXType[a.animalType]++;
				winnings += a.value - values[a.animalType];
				tids[a.animalType].push(ids[i]);
				replaceAnimal(i);
				i--;
			}
		}
		for (i = 0; i < costs.length; i++){
			if(numXType[i]>0){
				newP4P.receive.value(numXType[i]*values[i])(msg.sender, uint8(i), tids[i]);
				delete tids[i];
			}
			
		}
			
		if(winnings>0 && !msg.sender.send(winnings)) throw;
	}
	
	 
	function receive(address receiver, uint8 animalType, uint32[] oldids) payable {
		if(msg.sender!=lastP4P) throw;
		if (msg.value < oldids.length * values[animalType]) throw;
		for (uint8 i = 0; i < oldids.length; i++) {
			if (animals[oldids[i]].value == 0) {
				addAnimal(animalType, receiver, oldids[i]);
				if(oldids[i]<oldest) oldest = oldids[i];
			} else {
				addAnimal(animalType, receiver, nextId);
				nextId++;
			}
		}
		numAnimalsXType[animalType] += uint16(oldids.length);
	}

	
	
	 


	function getAnimal(uint32 animalId) constant returns(uint8, uint128, address) {
		return (animals[animalId].animalType, animals[animalId].value, animals[animalId].owner);
	}

	function get10Animals(uint16 startIndex) constant returns(uint32[10] animalIds, uint8[10] types, uint128[10] values, address[10] owners) {
		uint32 endIndex = startIndex + 10 > numAnimals ? numAnimals : startIndex + 10;
		uint8 j = 0;
		uint32 id;
		for (uint16 i = startIndex; i < endIndex; i++) {
			id = ids[i];
			animalIds[j] = id;
			types[j] = animals[id].animalType;
			values[j] = animals[id].value;
			owners[j] = animals[id].owner;
			j++;
		}

	}


	function getFees() constant returns(uint) {
		uint reserved = 0;
		for (uint16 j = 0; j < numAnimals; j++)
			reserved += animals[ids[j]].value;
		return address(this).balance - reserved;
	}


	 

	function setOraclizeGas(uint32 newGas) {
		if (!(msg.sender == owner)) throw;
		oraclizeGas = newGas;
	}

	function setMaxAnimals(uint16 number) {
		if (!(msg.sender == owner)) throw;
		maxAnimals = number;
	}
	

	 

	 
	function mapToNewRange(uint number, uint range) constant internal returns(uint16 randomNumber) {
		return uint16(number * range / 1000);
	}

	 
	function getNumbersFromString(string s, string delimiter, uint32 howmany) constant internal returns(uint16[] numbers) {
		strings.slice memory myresult = s.toSlice();
		strings.slice memory delim = delimiter.toSlice();
		numbers = new uint16[](howmany);
		for (uint8 i = 0; i < howmany; i++) {
			numbers[i] = uint16(parseInt(myresult.split(delim).toString()));
		}
		return numbers;
	}

}