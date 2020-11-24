 

 

 
 
 
 

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
    function oraclize_setCustomGasPrice(uint gasPrice) oraclizeAPI internal {
        return oraclize.setCustomGasPrice(gasPrice);
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


 

 

contract FlightDelay is usingOraclize {

	using strings for *;

	modifier noEther { if (msg.value > 0) throw; _ }
	modifier onlyOwner { if (msg.sender != owner) throw; _ }
	modifier onlyOraclize {	if (msg.sender != oraclize_cbAddress()) throw; _ }

	modifier onlyInState (uint _policyId, policyState _state) {

		policy p = policies[_policyId];
		if (p.state != _state) throw;
		_

	}

	modifier onlyCustomer(uint _policyId) {

		policy p = policies[_policyId];
		if (p.customer != msg.sender) throw;
		_

	}

	modifier notInMaintenance {
		healthCheck();
		if (maintenance_mode >= maintenance_Emergency) throw;
		_
	}

	 
	 
	modifier noReentrant {
		if (reentrantGuard) throw;
		reentrantGuard = true;
		_
		reentrantGuard = false;
	}

	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 


	 
	enum policyState {Applied, Accepted, Revoked, PaidOut,
	 
					  Expired, Declined, SendFailed}

	 
	enum oraclizeState { ForUnderwriting, ForPayout }

	event LOG_PolicyApplied(
		uint policyId,
		address customer,
		string carrierFlightNumber,
		uint premium
	);
	event LOG_PolicyAccepted(
		uint policyId,
		uint statistics0,
		uint statistics1,
		uint statistics2,
		uint statistics3,
		uint statistics4,
		uint statistics5
	);
	event LOG_PolicyRevoked(
		uint policyId
	);
	event LOG_PolicyPaidOut(
		uint policyId,
		uint amount
	);
	event LOG_PolicyExpired(
		uint policyId
	);
	event LOG_PolicyDeclined(
		uint policyId,
		bytes32 reason
	);
	event LOG_PolicyManualPayout(
		uint policyId,
		bytes32 reason
	);
	event LOG_SendFail(
		uint policyId,
		bytes32 reason
	);
	event LOG_OraclizeCall(
		uint policyId,
		bytes32 queryId,
		string oraclize_url
	);
	event LOG_OraclizeCallback(
		uint policyId,
		bytes32 queryId,
		string result,
		bytes proof
	);
	event LOG_HealthCheck(
		bytes32 message, 
		int diff,
		uint balance,
		int ledgerBalance 
	);

	 
	 
	uint constant minObservations 			= 10;
	 
	uint constant minPremium 				= 500 finney;
	 
	uint constant maxPremium 				= 5 ether;
	 
	uint constant maxPayout 				= 150 ether;
	 
	uint maxCumulatedWeightedPremium		= 300 ether; 
	 
	uint8 constant rewardPercent 			= 2;
	 
	uint8 constant reservePercent 			= 1;
	 
	 
	 
    uint8[6] weightPattern 					= [0, 10,20,30,50,50];
	 
	uint contractDeadline 					= 1474891200; 

	 
	 
	uint8 constant acc_Premium 				= 0;
	 
	uint8 constant acc_RiskFund 			= 1;
	 
	uint8 constant acc_Payout 				= 2;
	 
	uint8 constant acc_Balance 				= 3;
	 
	uint8 constant acc_Reward 				= 4;
	 
	uint8 constant acc_OraclizeCosts 		= 5;
	 

	 
	uint8 constant maintenance_None      	= 0;
	uint8 constant maintenance_BalTooHigh 	= 1;
	uint8 constant maintenance_Emergency 	= 255;
	
	
	 
	uint constant oraclizeGas 				= 500000;

	 

	string constant oraclize_RatingsBaseUrl =
		"[URL] json(https://api.flightstats.com/flex/ratings/rest/v1/json/flight/";
	string constant oraclizeRatingsQuery =
		"?${[decrypt] BN0pJDw6e65XSHqRe1zGji/QU9y5NgK9eTda3VmITxeRgncyGQewbTE+46EFY/waH5KXoHWSb0d/Wpwm1rE5SVeA5SvXrSZCKHw13krbK8D/F/RqL9/VoAx8fGJnYsWQ1q2G5lZbiY9sd6sKhozb/epq4GpcHpdjNf111/pJTwHttxsrUno/}).ratings[0]['observations','late15','late30','late45','cancelled','diverted']";

	 
	string constant oraclize_StatusBaseUrl =
	  "[URL] json(https://api.flightstats.com/flex/flightstatus/rest/v2/json/flight/status/";
	string constant oraclizeStatusQuery =
		"?${[decrypt] BN0pJDw6e65XSHqRe1zGji/QU9y5NgK9eTda3VmITxeRgncyGQewbTE+46EFY/waH5KXoHWSb0d/Wpwm1rE5SVeA5SvXrSZCKHw13krbK8D/F/RqL9/VoAx8fGJnYsWQ1q2G5lZbiY9sd6sKhozb/epq4GpcHpdjNf111/pJTwHttxsrUno/}&utc=true).flightStatuses[0]['status','delays','operationalTimes']";


	 
	 

	struct policy {

		 
		address customer;
		 
		uint premium;

		 
		 
		bytes32 riskId;
		 
		 
		 
		 
		 
		uint weight;
		 
		uint calculatedPayout;
		 
		uint actualPayout;

		 
		 
		policyState state;
		 
		uint stateTime;
		 
		bytes32 stateMessage;
		 
		bytes proof;
	}

	 
	 
	 
	 

	struct risk {

		 
		string carrierFlightNumber;
		 
		string departureYearMonthDay;
		 
		uint arrivalTime;
		 
		uint delayInMinutes;
		 
		uint8 delay;
		 
		uint cumulatedWeightedPremium;
		 
		uint premiumMultiplier;
	}

	 
	 
	 

	struct oraclizeCallback {

		 
		uint policyId;
		 
		oraclizeState oState;
		uint oraclizeTime;

	}

	address public owner;

	 
	policy[] public policies;
	 
	mapping (address => uint[]) public customerPolicies;
	 
	mapping (bytes32 => oraclizeCallback) public oraclizeCallbacks;
	mapping (bytes32 => risk) public risks;
	 
	int[6] public ledger;

	 
	 

	 
	bool public reentrantGuard;
	uint8 public maintenance_mode;

	function healthCheck() internal {
		int diff = int(this.balance-msg.value) + ledger[acc_Balance];
		if (diff == 0) {
			return;  
		}
		if (diff > 0) {
			LOG_HealthCheck('Balance too high', diff, this.balance, ledger[acc_Balance]);
			maintenance_mode = maintenance_BalTooHigh;
		} else {
			LOG_HealthCheck('Balance too low', diff, this.balance, ledger[acc_Balance]);
			maintenance_mode = maintenance_Emergency;
		}
	}

	 
	 
	 
	 
	 
	function performHealthCheck(uint8 _maintenance_mode) onlyOwner {
		maintenance_mode = _maintenance_mode;
		if (maintenance_mode > 0 && maintenance_mode < maintenance_Emergency) {
			healthCheck();
		}
	}

	function payReward() onlyOwner {

		if (!owner.send(this.balance)) throw;
		maintenance_mode = maintenance_Emergency;  

	}

	function bookkeeping(uint8 _from, uint8 _to, uint _amount) internal {

		ledger[_from] -= int(_amount);
		ledger[_to] += int(_amount);

	}

	 
	function audit(uint8 _from, uint8 _to, uint _amount) onlyOwner {

		bookkeeping (_from, _to, _amount);

	}

	function getPolicyCount(address _customer)
		constant returns (uint _count) {
		return policies.length;
	}

	function getCustomerPolicyCount(address _customer)
		constant returns (uint _count) {
		return customerPolicies[_customer].length;
	}

	function bookAndCalcRemainingPremium() internal returns (uint) {

		uint v = msg.value;
		uint reserve = v * reservePercent / 100;
		uint remain = v - reserve;
		uint reward = remain * rewardPercent / 100;

		bookkeeping(acc_Balance, acc_Premium, v);
		bookkeeping(acc_Premium, acc_RiskFund, reserve);
		bookkeeping(acc_Premium, acc_Reward, reward);

		return (uint(remain - reward));

	}

	 
	function FlightDelay (address _owner) {

		owner = _owner;
		reentrantGuard = false;
		maintenance_mode = maintenance_None;

		 
		bookkeeping(acc_Balance, acc_RiskFund, msg.value);
		oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);

	}

	 
    function toYMD (uint departure) returns (string) {
        uint diff = (departure - 1472601600) / 86400;
        uint8 d1 = uint8(diff / 10);
        uint8 d2 = uint8(diff - 10*d1);
        string memory str = '/dep/2016/09/xx';
        bytes memory strb = bytes(str);
        strb[13] = bytes1(d1+48);
        strb[14] = bytes1(d2+48);
		return(string(strb));
    }


	 
	function newPolicy(
		string _carrierFlightNumber, 
		string _departureYearMonthDay, 
		uint _departureTime, 
		uint _arrivalTime
		) 
		notInMaintenance {

		_departureYearMonthDay = toYMD(_departureTime);
		 

		 

		if (msg.value < minPremium || msg.value > maxPremium) {
			LOG_PolicyDeclined(0, 'Invalid premium value');
			if (!msg.sender.send(msg.value)) {
				LOG_SendFail(0, 'newPolicy sendback failed (1)');
			}
			return;
		}

         
		 
		 
        if (
			_arrivalTime < _departureTime ||
			_arrivalTime > _departureTime + 2 days ||
			_departureTime < now + 24 hours ||
			_departureTime > contractDeadline) {
			LOG_PolicyDeclined(0, 'Invalid arrival/departure time');
			if (!msg.sender.send(msg.value)) {
				LOG_SendFail(0, 'newPolicy sendback failed (2)');
			}
			return;
        }
		
		 
		
		bytes32 riskId = sha3(
			_carrierFlightNumber, 
			_departureYearMonthDay, 
			_arrivalTime
		);
		risk r = risks[riskId];
	
		 
		 
		 
		 
		if (msg.value * r.premiumMultiplier + r.cumulatedWeightedPremium >= 
			maxCumulatedWeightedPremium) {
			LOG_PolicyDeclined(0, 'Cluster risk');
			if (!msg.sender.send(msg.value)) {
				LOG_SendFail(0, 'newPolicy sendback failed (3)');
			}
			return;
		} else if (r.cumulatedWeightedPremium == 0) {
			 
			 
			 
			r.cumulatedWeightedPremium = maxCumulatedWeightedPremium;
		}

		 
		uint policyId = policies.length++;
		customerPolicies[msg.sender].push(policyId);
		policy p = policies[policyId];

		p.customer = msg.sender;
		 
		p.premium = bookAndCalcRemainingPremium();
		p.riskId = riskId;

		 
		 
		if (r.premiumMultiplier == 0) {  
			 
			r.carrierFlightNumber = _carrierFlightNumber;
			r.departureYearMonthDay = _departureYearMonthDay;
			r.arrivalTime = _arrivalTime;
		} else {  
			r.cumulatedWeightedPremium += p.premium * r.premiumMultiplier;
		}

		 
		p.state = policyState.Applied;
		p.stateMessage = 'Policy applied by customer';
		p.stateTime = now;
		LOG_PolicyApplied(policyId, msg.sender, _carrierFlightNumber, p.premium);

		 
		getFlightStats(policyId, _carrierFlightNumber);
	}
	
	function underwrite(uint _policyId, uint[6] _statistics, bytes _proof) internal {

		policy p = policies[_policyId];  
		uint weight;
		for (uint8 i = 1; i <= 5; i++ ) {
			weight += weightPattern[i] * _statistics[i];
			 
		}
		 
		 
		if (weight == 0) { weight = 100000 / _statistics[0]; }

		risk r = risks[p.riskId];
		 
		if (r.premiumMultiplier == 0) { 
			 
			r.premiumMultiplier = 100000 / weight;
			r.cumulatedWeightedPremium = p.premium * 100000 / weight;
		}
		
		p.proof = _proof;
		p.weight = weight;

		 
		schedulePayoutOraclizeCall(
			_policyId, 
			r.carrierFlightNumber, 
			r.departureYearMonthDay, 
			r.arrivalTime + 15 minutes
		);

		p.state = policyState.Accepted;
		p.stateMessage = 'Policy underwritten by oracle';
		p.stateTime = now;

		LOG_PolicyAccepted(
			_policyId, 
			_statistics[0], 
			_statistics[1], 
			_statistics[2], 
			_statistics[3], 
			_statistics[4],
			_statistics[5]
		);

	}
	
	function decline(uint _policyId, bytes32 _reason, bytes _proof)	internal {

		policy p = policies[_policyId];

		p.state = policyState.Declined;
		p.stateMessage = _reason;
		p.stateTime = now;  
		p.proof = _proof;
		bookkeeping(acc_Premium, acc_Balance, p.premium);

		if (!p.customer.send(p.premium))  {
			bookkeeping(acc_Balance, acc_RiskFund, p.premium);
			p.state = policyState.SendFailed;
			p.stateMessage = 'decline: Send failed.';
			LOG_SendFail(_policyId, 'decline sendfail');
		}
		else {
			LOG_PolicyDeclined(_policyId, _reason);
		}


	}
	
	function schedulePayoutOraclizeCall(
		uint _policyId, 
		string _carrierFlightNumber, 
		string _departureYearMonthDay, 
		uint _oraclizeTime) 
		internal {

		string memory oraclize_url = strConcat(
			oraclize_StatusBaseUrl,
			_carrierFlightNumber,
			_departureYearMonthDay,
			oraclizeStatusQuery
			);

		bytes32 queryId = oraclize_query(_oraclizeTime, 'nested', oraclize_url, oraclizeGas);
		bookkeeping(acc_OraclizeCosts, acc_Balance, uint((-ledger[acc_Balance]) - int(this.balance)));
		oraclizeCallbacks[queryId] = oraclizeCallback(_policyId, oraclizeState.ForPayout, _oraclizeTime);

		LOG_OraclizeCall(_policyId, queryId, oraclize_url);
	}

	function payOut(uint _policyId, uint8 _delay, uint _delayInMinutes)
		notInMaintenance
		onlyOraclize
		onlyInState(_policyId, policyState.Accepted)
		internal {

		policy p = policies[_policyId];
		risk r = risks[p.riskId];
		r.delay = _delay;
		r.delayInMinutes = _delayInMinutes;
		
		if (_delay == 0) {
			p.state = policyState.Expired;
			p.stateMessage = 'Expired - no delay!';
			p.stateTime = now;
			LOG_PolicyExpired(_policyId);
		} else {

			uint payout = p.premium * weightPattern[_delay] * 10000 / p.weight;
			p.calculatedPayout = payout;

			if (payout > maxPayout) {
				payout = maxPayout;
			}

			if (payout > uint(-ledger[acc_Balance])) {  
				payout = uint(-ledger[acc_Balance]);
			}

			p.actualPayout = payout;
			bookkeeping(acc_Payout, acc_Balance, payout);       


			if (!p.customer.send(payout))  {
				bookkeeping(acc_Balance, acc_Payout, payout);
				p.state = policyState.SendFailed;
				p.stateMessage = 'Payout, send failed!';
				p.actualPayout = 0;
				LOG_SendFail(_policyId, 'payout sendfail');
			}
			else {
				p.state = policyState.PaidOut;
				p.stateMessage = 'Payout successful!';
				p.stateTime = now;  
				LOG_PolicyPaidOut(_policyId, payout);
			}
		}

	}

	 
	function () onlyOwner {

		 
		bookkeeping(acc_Balance, acc_RiskFund, msg.value);

	}

	 
	function getFlightStats(
		uint _policyId,
		string _carrierFlightNumber)
		internal {

		 
		 

		 
		 
		 
		 
		string memory oraclize_url = strConcat(
			oraclize_RatingsBaseUrl,
			_carrierFlightNumber,
			oraclizeRatingsQuery
			);

		bytes32 queryId = oraclize_query("nested", oraclize_url, oraclizeGas);
		 
		bookkeeping(acc_OraclizeCosts, acc_Balance, uint((-ledger[acc_Balance]) - int(this.balance)));
		oraclizeCallbacks[queryId] = oraclizeCallback(_policyId, oraclizeState.ForUnderwriting, 0);

		LOG_OraclizeCall(_policyId, queryId, oraclize_url);

	}

	 
	function __callback(bytes32 _queryId, string _result, bytes _proof) 
		onlyOraclize 
		noReentrant {

		oraclizeCallback o = oraclizeCallbacks[_queryId];
		LOG_OraclizeCallback(o.policyId, _queryId, _result, _proof);
		
		if (o.oState == oraclizeState.ForUnderwriting) {
            callback_ForUnderwriting(o.policyId, _result, _proof);
		}
        else {
            callback_ForPayout(_queryId, _result, _proof);
        }
	}

	function callback_ForUnderwriting(uint _policyId, string _result, bytes _proof) 
		onlyInState(_policyId, policyState.Applied)
		internal {

		var sl_result = _result.toSlice(); 		
		risk r = risks[policies[_policyId].riskId];

		 
		 
		 

		if (bytes(_result).length == 0) {
			decline(_policyId, 'Declined (empty result)', _proof);
		} else {

			 
			 

			if (sl_result.count(', '.toSlice()) != 5) { 
				 
				decline(_policyId, 'Declined (invalid result)', _proof);
			} else {
				sl_result.beyond("[".toSlice()).until("]".toSlice());

				uint observations = parseInt(
					sl_result.split(', '.toSlice()).toString());

				 
				 
				if (observations <= minObservations) {
					decline(_policyId, 'Declined (too few observations)', _proof);
				} else {
					uint[6] memory statistics;
					 
					statistics[0] = observations;
					for(uint i = 1; i <= 5; i++) {
						statistics[i] =
							parseInt(
								sl_result.split(', '.toSlice()).toString()) 
								* 10000/observations;
					}

					 
					underwrite(_policyId, statistics, _proof);
				}
			}
		}
	} 

	function callback_ForPayout(bytes32 _queryId, string _result, bytes _proof) internal {

		oraclizeCallback o = oraclizeCallbacks[_queryId];
		uint policyId = o.policyId;
		var sl_result = _result.toSlice(); 		
		risk r = risks[policies[policyId].riskId];

		if (bytes(_result).length == 0) {
			if (o.oraclizeTime > r.arrivalTime + 180 minutes) {
				LOG_PolicyManualPayout(policyId, 'No Callback at +120 min');
				return;
			} else {
				schedulePayoutOraclizeCall(
					policyId, 
					r.carrierFlightNumber, 
					r.departureYearMonthDay, 
					o.oraclizeTime + 45 minutes
				);
			}
		} else {
						
			 

			 
			sl_result.find('"'.toSlice()).beyond('"'.toSlice());
			sl_result.until(sl_result.copy().find('"'.toSlice()));
			bytes1 status = bytes(sl_result.toString())[0];	 
			
			if (status == 'C') {
				 
				payOut(policyId, 4, 0);
				return;
			} else if (status == 'D') {
				 
				payOut(policyId, 5, 0);
				return;
			} else if (status != 'L' && status != 'A' && status != 'C' && status != 'D') {
				LOG_PolicyManualPayout(policyId, 'Unprocessable status');
				return;
			}
			
			 
			sl_result = _result.toSlice();
			bool arrived = sl_result.contains('actualGateArrival'.toSlice());

			if (status == 'A' || (status == 'L' && !arrived)) {
				 
				if (o.oraclizeTime > r.arrivalTime + 180 minutes) {
					LOG_PolicyManualPayout(policyId, 'No arrival at +120 min');
				} else {
					schedulePayoutOraclizeCall(
						policyId, 
						r.carrierFlightNumber, 
						r.departureYearMonthDay, 
						o.oraclizeTime + 45 minutes
					);
				}
			} else if (status == 'L' && arrived) {
				var aG = '"arrivalGateDelayMinutes": '.toSlice();
				if (sl_result.contains(aG)) {
					sl_result.find(aG).beyond(aG);
					sl_result.until(sl_result.copy().find('"'.toSlice())
						.beyond('"'.toSlice()));
					sl_result.until(sl_result.copy().find('}'.toSlice()));
					sl_result.until(sl_result.copy().find(','.toSlice()));
					uint delayInMinutes = parseInt(sl_result.toString());
				} else {
					delayInMinutes = 0;
				}
				
				if (delayInMinutes < 15) {
					payOut(policyId, 0, 0);
				} else if (delayInMinutes < 30) {
					payOut(policyId, 1, delayInMinutes);
				} else if (delayInMinutes < 45) {
					payOut(policyId, 2, delayInMinutes);
				} else {
					payOut(policyId, 3, delayInMinutes);
				}
			} else {  
				payOut(policyId, 0, 0);
			}
		} 
	}
}




 