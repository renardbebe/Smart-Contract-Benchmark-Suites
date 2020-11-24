 

 
 

pragma solidity ^0.4.21;

contract OraclizeI {
    address public cbAddress;
    function query(uint _timestamp, string _datasource, string _arg) external payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) external payable returns (bytes32 _id);
    function query2(uint _timestamp, string _datasource, string _arg1, string _arg2) public payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string _datasource, string _arg1, string _arg2, uint _gaslimit) external payable returns (bytes32 _id);
    function queryN(uint _timestamp, string _datasource, bytes _argN) public payable returns (bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string _datasource, bytes _argN, uint _gaslimit) external payable returns (bytes32 _id);
    function getPrice(string _datasource) public view returns (uint _dsprice);
    function getPrice(string _datasource, uint gaslimit) public view returns (uint _dsprice);
    function setProofType(byte _proofType) external;
    function setCustomGasPrice(uint _gasPrice) external;
    function randomDS_getSessionPubKeyHash() external view returns(bytes32);
}
contract OraclizeAddrResolverI {
    function getAddress() public view returns (address _addr);
}
library oraclizeLib {

    function proofType_NONE()
    public
    pure
    returns (byte) {
        return 0x00;
    }

    function proofType_TLSNotary()
    public
    pure
    returns (byte) {
        return 0x10;
    }

    function proofType_Android()
    public
    pure
    returns (byte) {
        return 0x20;
    }

    function proofType_Ledger()
    public
    pure
    returns (byte) {
        return 0x30;
    }

    function proofType_Native()
    public
    pure
    returns (byte) {
        return 0xF0;
    }

    function proofStorage_IPFS()
    public
    pure
    returns (byte) {
        return 0x01;
    }

     

    function OAR()
    public
    view
    returns (OraclizeAddrResolverI) {
        return oraclize_setNetwork();
    }

     

    function oraclize()
    public
    view
    returns (OraclizeI) {
        return OraclizeI(OAR().getAddress());
    }

    function oraclize_setNetwork()
    public
    view
    returns(OraclizeAddrResolverI){
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed)>0){  
            return OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1)>0){  
            return OraclizeAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e)>0){  
            return OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48)>0){  
            return OraclizeAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
        }
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475)>0){  
            return OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
        }
        if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF)>0){  
            return OraclizeAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA)>0){  
            return OraclizeAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
        }
    }

    function oraclize_getPrice(string datasource)
    public
    view
    returns (uint){
        return oraclize().getPrice(datasource);
    }

    function oraclize_getPrice(string datasource, uint gaslimit)
    public
    view
    returns (uint){
        return oraclize().getPrice(datasource, gaslimit);
    }

    function oraclize_query(string datasource, string arg)
    public
    returns (bytes32 id){
        return oraclize_query(0, datasource, arg);
    }

    function oraclize_query(uint timestamp, string datasource, string arg)
    public
    returns (bytes32 id){
        OraclizeI oracle = oraclize();
        uint price = oracle.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        return oracle.query.value(price)(timestamp, datasource, arg);
    }

    function oraclize_query(string datasource, string arg, uint gaslimit)
    public
    returns (bytes32 id){
        return oraclize_query(0, datasource, arg, gaslimit);
    }

    function oraclize_query(uint timestamp, string datasource, string arg, uint gaslimit)
    public
    returns (bytes32 id){
        OraclizeI oracle = oraclize();
        uint price = oracle.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        return oracle.query_withGasLimit.value(price)(timestamp, datasource, arg, gaslimit);
    }

    function oraclize_query(string datasource, string arg1, string arg2)
    public
    returns (bytes32 id){
        return oraclize_query(0, datasource, arg1, arg2);
    }

    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2)
    public
    returns (bytes32 id){
        OraclizeI oracle = oraclize();
        uint price = oracle.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        return oracle.query2.value(price)(timestamp, datasource, arg1, arg2);
    }

    function oraclize_query(string datasource, string arg1, string arg2, uint gaslimit)
    public
    returns (bytes32 id){
        return oraclize_query(0, datasource, arg1, arg2, gaslimit);
    }

    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2, uint gaslimit)
    public
    returns (bytes32 id){
        OraclizeI oracle = oraclize();
        uint price = oracle.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        return oracle.query2_withGasLimit.value(price)(timestamp, datasource, arg1, arg2, gaslimit);
    }

     
    function oraclize_query(string datasource, string[] argN)
    internal
    returns (bytes32 id){
        return oraclize_query(0, datasource, argN);
    }

     
    function oraclize_query(uint timestamp, string datasource, string[] argN)
    internal
    returns (bytes32 id){
        OraclizeI oracle = oraclize();
        uint price = oracle.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        bytes memory args = stra2cbor(argN);
        return oracle.queryN.value(price)(timestamp, datasource, args);
    }

     
    function oraclize_query(string datasource, string[] argN, uint gaslimit)
    internal
    returns (bytes32 id){
        return oraclize_query(0, datasource, argN, gaslimit);
    }

     
    function oraclize_query(uint timestamp, string datasource, string[] argN, uint gaslimit)
    internal
    returns (bytes32 id){
        OraclizeI oracle = oraclize();
        uint price = oracle.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        bytes memory args = stra2cbor(argN);
        return oracle.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
    }

    function oraclize_cbAddress()
    public
    view
    returns (address){
        return oraclize().cbAddress();
    }

    function oraclize_setProof(byte proofP)
    public {
        return oraclize().setProofType(proofP);
    }

    function oraclize_setCustomGasPrice(uint gasPrice)
    public {
        return oraclize().setCustomGasPrice(gasPrice);
    }

     
     
    function getCodeSize(address _addr)
    public
    view
    returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

     
    function parseAddr(string _a)
    public
    pure
    returns (address){
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i=2; i<2+2*20; i+=2){
            iaddr *= 256;
            b1 = uint160(tmp[i]);
            b2 = uint160(tmp[i+1]);
            if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;
            else if ((b1 >= 65)&&(b1 <= 70)) b1 -= 55;
            else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;
            if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;
            else if ((b2 >= 65)&&(b2 <= 70)) b2 -= 55;
            else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;
            iaddr += (b1*16+b2);
        }
        return address(iaddr);
    }

    function strCompare(string _a, string _b)
    public
    pure
    returns (int) {
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

    function indexOf(string _haystack, string _needle)
    public
    pure
    returns (int) {
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

    function strConcat(string _a, string _b, string _c, string _d, string _e)
    internal
    pure
    returns (string) {
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

    function strConcat(string _a, string _b, string _c, string _d)
    internal
    pure
    returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c)
    internal
    pure
    returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b)
    internal
    pure
    returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

     
    function parseInt(string _a)
    public
    pure
    returns (uint) {
        return parseInt(_a, 0);
    }

     
    function parseInt(string _a, uint _b)
    public
    pure
    returns (uint) {
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

    function uint2str(uint i)
    internal
    pure
    returns (string){
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

    function stra2cbor(string[] arr)
    internal
    pure
    returns (bytes) {
        uint arrlen = arr.length;

         
        uint outputlen = 0;
        bytes[] memory elemArray = new bytes[](arrlen);
        for (uint i = 0; i < arrlen; i++) {
            elemArray[i] = (bytes(arr[i]));
            outputlen += elemArray[i].length + (elemArray[i].length - 1)/23 + 3;  
        }
        uint ctr = 0;
        uint cborlen = arrlen + 0x80;
        outputlen += byte(cborlen).length;
        bytes memory res = new bytes(outputlen);

        while (byte(cborlen).length > ctr) {
            res[ctr] = byte(cborlen)[ctr];
            ctr++;
        }
        for (i = 0; i < arrlen; i++) {
            res[ctr] = 0x5F;
            ctr++;
            for (uint x = 0; x < elemArray[i].length; x++) {
                 
                if (x % 23 == 0) {
                    uint elemcborlen = elemArray[i].length - x >= 24 ? 23 : elemArray[i].length - x;
                    elemcborlen += 0x40;
                    uint lctr = ctr;
                    while (byte(elemcborlen).length > ctr - lctr) {
                        res[ctr] = byte(elemcborlen)[ctr - lctr];
                        ctr++;
                    }
                }
                res[ctr] = elemArray[i][x];
                ctr++;
            }
            res[ctr] = 0xFF;
            ctr++;
        }
        return res;
    }    
}
 


 

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

     
    function toSlice(string self) internal pure returns (slice) {
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

     
    function toSliceB32(bytes32 self) internal pure returns (slice ret) {
         
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

     
    function copy(slice self) internal pure returns (slice) {
        return slice(self._len, self._ptr);
    }

     
    function toString(slice self) internal pure returns (string) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

     
    function len(slice self) internal pure returns (uint l) {
         
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

     
    function empty(slice self) internal pure returns (bool) {
        return self._len == 0;
    }

     
    function compare(slice self, slice other) internal pure returns (int) {
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

     
    function equals(slice self, slice other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

     
    function nextRune(slice self, slice rune) internal pure returns (slice) {
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

     
    function nextRune(slice self) internal pure returns (slice ret) {
        nextRune(self, ret);
    }

     
    function ord(slice self) internal pure returns (uint ret) {
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

     
    function keccak(slice self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

     
    function startsWith(slice self, slice needle) internal pure returns (bool) {
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

     
    function beyond(slice self, slice needle) internal pure returns (slice) {
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

     
    function endsWith(slice self, slice needle) internal pure returns (bool) {
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

     
    function until(slice self, slice needle) internal pure returns (slice) {
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

    event log_bytemask(bytes32 mask);

     
     
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
                assembly { hash := sha3(needleptr, needlelen) }

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

     
    function find(slice self, slice needle) internal pure returns (slice) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

     
    function rfind(slice self, slice needle) internal pure returns (slice) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

     
    function split(slice self, slice needle, slice token) internal pure returns (slice) {
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

     
    function split(slice self, slice needle) internal pure returns (slice token) {
        split(self, needle, token);
    }

     
    function rsplit(slice self, slice needle, slice token) internal pure returns (slice) {
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

     
    function rsplit(slice self, slice needle) internal pure returns (slice token) {
        rsplit(self, needle, token);
    }

     
    function count(slice self, slice needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

     
    function contains(slice self, slice needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

     
    function concat(slice self, slice other) internal pure returns (string) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

     
    function join(slice self, slice[] parts) internal pure returns (string) {
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


   
  function Ownable() public{
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public{
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused public returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}


 
contract Config is Pausable {
     
    uint public taxRate;     
    uint gasForOraclize;
    uint systemGasForOraclize; 
    uint256 public minStake;
    uint256 public maxStake;
    uint256 public maxWin;
    uint256 public normalRoomMin;
    uint256 public normalRoomMax;
    uint256 public tripleRoomMin;
    uint256 public tripleRoomMax;
    uint referrelFund;
    string random_api_key;
    uint public minSet;
    uint public maxSet;

    function Config() public{
        setOraGasLimit(235000);         
        setSystemOraGasLimit(120000);   
        setMinStake(0.1 ether);
        setMaxStake(10 ether);
        setMaxWin(10 ether); 
        taxRate = 20;
        setNormalRoomMin(0.1 ether);
        setNormalRoomMax(1 ether);
        setTripleRoomMin(1 ether);
        setTripleRoomMax(10 ether);
        setRandomApiKey("50faa373-68a1-40ce-8da8-4523db62d42a");
        setMinSet(3);
        setMaxSet(10);
        referrelFund = 10;
    }

    function setRandomApiKey(string value) public onlyOwner {        
        random_api_key = value;
    }           

    function setOraGasLimit(uint gasLimit) public onlyOwner {
        if(gasLimit == 0){
            return;
        }
        gasForOraclize = gasLimit;
    }

    function setSystemOraGasLimit(uint gasLimit) public onlyOwner {
        if(gasLimit == 0){
            return;
        }
        systemGasForOraclize = gasLimit;
    }       
    

    function setMinStake(uint256 value) public onlyOwner{
        if(value == 0){
            return;
        }
        minStake = value;
    }

    function setMaxStake(uint256 value) public onlyOwner{
        if(value == 0){
            return;
        }
        maxStake = value;
    }

    function setMinSet(uint value) public onlyOwner{
        if(value == 0){
            return;
        }
        minSet = value;
    }

    function setMaxSet(uint value) public onlyOwner{
        if(value == 0){
            return;
        }
        maxSet = value;
    }

    function setMaxWin(uint256 value) public onlyOwner{
        if(value == 0){
            return;
        }
        maxWin = value;
    }

    function setNormalRoomMax(uint256 value) public onlyOwner{
        if(value == 0){
            return;
        }
        normalRoomMax = value;
    }

    function setNormalRoomMin(uint256 value) public onlyOwner{
        if(value == 0){
            return;
        }
        normalRoomMin = value;
    }

    function setTripleRoomMax(uint256 value) public onlyOwner{
        if(value == 0){
            return;
        }
        tripleRoomMax = value;
    }

    function setTripleRoomMin(uint256 value) public onlyOwner{
        if(value == 0){
            return;
        }
        tripleRoomMin = value;
    }

    function setTaxRate(uint value) public onlyOwner{
        if(value == 0 || value >= 1000){
            return;
        }
        taxRate = value;
    }

    function setReferralFund(uint value) public onlyOwner{
        if(value == 0 || value >= 1000){
            return;
        }
        referrelFund = value;
    }  
}

contract UserManager {    
    struct UserInfo {         
        uint256 playAmount;
        uint playCount;
        uint openRoomCount;
        uint256 winAmount;
        address referral;       
    }
   
    mapping (address => UserInfo) allUsers;
    
    
    function UserManager() public{        
    }    

    function addBet (address player,uint256 value) internal {        
        allUsers[player].playCount++;
        allUsers[player].playAmount += value;
    }

    function addWin (address player,uint256 value) internal {            
        allUsers[player].winAmount += value;
    }
    
    function addOpenRoomCount (address player) internal {
       allUsers[player].openRoomCount ++;
    }

    function subOpenRoomCount (address player) internal {          
        if(allUsers[player].openRoomCount > 0){
            allUsers[player].openRoomCount--;
        }
    }

    function setReferral (address player,address referral) internal { 
        if(referral == 0)
            return;
        if(allUsers[player].referral == 0 && referral != player){
            allUsers[player].referral = referral;
        }
    }
    
    function getPlayedInfo (address player) public view returns(uint playedCount,uint openRoomCount,
        uint256 playAmount,uint256 winAmount) {
        playedCount = allUsers[player].playCount;
        openRoomCount = allUsers[player].openRoomCount;
        playAmount = allUsers[player].playAmount;
        winAmount = allUsers[player].winAmount;
    }
    

    function fundReferrel(address player,uint256 value) internal {
        if(allUsers[player].referral != 0){
            allUsers[player].referral.transfer(value);
        }
    }    
}

 
contract RoomManager {  
    uint constant roomFree = 0;
    uint constant roomPending = 1;
    uint constant roomEnded = 2;

    struct RoomInfo{
        uint roomid;
        address owner;
        uint setCount;   
        uint256 balance;
        uint status;
        uint currentSet;
        uint256 initBalance;
        uint roomData;   
        address lastPlayer;
        uint256 lastBet;
    }

    uint[] roomIDList;

    mapping (uint => RoomInfo) roomMapping;   

    uint _roomindex;

    event evt_calculate(address indexed player,address owner,uint num123,int256 winAmount,uint roomid,uint256 playTime,bytes32 serialNumber);
    event evt_gameRecord(address indexed player,uint256 betAmount,int256 winAmount,uint playTypeAndData,uint256 time,uint num123,address owner,uint setCountAndEndSet,uint256 roomInitBalance);
    

    function RoomManager ()  public {       
        _roomindex = 1;  
    }
    
    function getResult(uint num123) internal pure returns(uint){
        uint num1 = num123 / 100;
        uint num2 = (num123 % 100) / 10;
        uint num3 = num123 % 10;
        if(num1 + num2 + num3 > 10){
            return 1;
        }
        return 0;
    }
    
    function isTripleNumber(uint num123) internal pure returns(bool){
        uint num1 = num123 / 100;
        uint num2 = (num123 % 100) / 10;
        uint num3 = num123 % 10;
        return (num1 == num2 && num1 == num3);
    }

    
    function tryOpenRoom(address owner,uint256 value,uint setCount,uint roomData) internal returns(uint roomID){
        roomID = _roomindex;
        roomMapping[_roomindex].owner = owner;
        roomMapping[_roomindex].initBalance = value;
        roomMapping[_roomindex].balance = value;
        roomMapping[_roomindex].setCount = setCount;
        roomMapping[_roomindex].roomData = roomData;
        roomMapping[_roomindex].roomid = _roomindex;
        roomMapping[_roomindex].status = roomFree;
        roomIDList.push(_roomindex);
        _roomindex++;
        if(_roomindex == 0){
            _roomindex = 1;
        }      
    }

    function tryCloseRoom(address owner,uint roomid,uint taxrate) internal returns(bool ret,bool taxPayed)  {
         
        ret = false;
        taxPayed = false;
        if(roomMapping[roomid].roomid == 0){
            return;
        }       
        RoomInfo memory room = roomMapping[roomid];
         
        if(room.owner != owner){
            return;
        }
         
        if(room.status == roomPending){
            return;
        }
        ret = true;
         
         
        if(room.balance > room.initBalance){
            uint256 tax = SafeMath.div(SafeMath.mul(room.balance,taxrate),1000);            
            room.balance -= tax;
            taxPayed = true;
        }
        room.owner.transfer(room.balance);
        deleteRoomByRoomID(roomid);
        return;
    }

    function tryDismissRoom(uint roomid) internal {
         
        if(roomMapping[roomid].roomid == 0){
            return;
        }    

        RoomInfo memory room = roomMapping[roomid];
        
        if(room.lastPlayer == 0){
            room.owner.transfer(room.balance);
            deleteRoomByRoomID(roomid);
            return;
        }
        room.lastPlayer.transfer(room.lastBet);
        room.owner.transfer(SafeMath.sub(room.balance,room.lastBet));
        deleteRoomByRoomID(roomid);
    }   

     
    function tryRollRoom(address user,uint256 value,uint roomid) internal returns(bool)  {
        if(value <= 0){
            return false;
        }

        if(roomMapping[roomid].roomid == 0){
            return false;
        }

        RoomInfo storage room = roomMapping[roomid];

        if(room.status != roomFree || room.balance == 0){
            return false;
        }

        uint256 betValue = getBetValue(room.initBalance,room.balance,room.setCount);

         
        if (value < betValue){
            return false;
        }
        if(value > betValue){
            user.transfer(value - betValue);
            value = betValue;
        }
         
        room.balance += value;
        room.lastPlayer = user;
        room.lastBet = value;
        room.status = roomPending;
        return true;
    }

     
     
    function calculateRoom(uint roomid,uint num123,uint taxrate,bytes32 myid) internal returns(bool success,
        bool isend,address winer,uint256 tax) {
        success = false;        
        tax = 0;
        if(roomMapping[roomid].roomid == 0){
            return;
        }

        RoomInfo memory room = roomMapping[roomid];
        if(room.status != roomPending || room.balance == 0){            
            return;
        }

         
        success = true;        
         
        if(room.setCount == 0){
            isend = true;
            (winer,tax) = calSimpleRoom(roomid,taxrate,num123,myid);            
            return;
        }

        (winer,tax,isend) = calTripleRoom(roomid,taxrate,num123,myid);
    }

    function calSimpleRoom(uint roomid,uint taxrate,uint num123,bytes32 myid) internal returns(address winer,uint256 tax) { 
        RoomInfo storage room = roomMapping[roomid];
        uint result = getResult(num123);
        tax = SafeMath.div(SafeMath.mul(room.balance,taxrate),1000);
        room.balance -= tax; 
        int256 winamount = -int256(room.lastBet);
        if(room.roomData == result){
             
            winer = room.owner;
            winamount += int256(tax);
        } else {
             
            winer = room.lastPlayer;
            winamount = int256(room.balance - room.initBalance);
        }
        room.status = roomEnded;            
        winer.transfer(room.balance);       
        
        emit evt_calculate(room.lastPlayer,room.owner,num123,winamount,room.roomid,now,myid);
        emit evt_gameRecord(room.lastPlayer,room.lastBet,winamount,10 + room.roomData,now,num123,room.owner,0,room.initBalance);
        deleteRoomByRoomID(roomid);
    }

    function calTripleRoom(uint roomid,uint taxrate,uint num123,bytes32 myid) internal 
        returns(address winer,uint256 tax,bool isend) { 
        RoomInfo storage room = roomMapping[roomid];       
         
        room.currentSet++;
        int256 winamount = -int256(room.lastBet);
        bool isTriple = isTripleNumber(num123);
        isend = room.currentSet >= room.setCount || isTriple;
        if(isend){
            tax = SafeMath.div(SafeMath.mul(room.balance,taxrate),1000);
            room.balance -= tax; 
            if(isTriple){   
                 
                winer = room.lastPlayer;
                winamount = int256(room.balance - room.lastBet);
            } else {
                 
                winer = room.owner;
            }
            room.status = roomEnded;
            winer.transfer(room.balance);       
            
            room.balance = 0;            
            emit evt_calculate(room.lastPlayer,room.owner,num123,winamount,room.roomid,now,myid);
            emit evt_gameRecord(room.lastPlayer,room.lastBet,winamount,10,now,num123,room.owner,room.setCount * 100 + room.currentSet,room.initBalance);
            deleteRoomByRoomID(roomid);
        } else {
            room.status = roomFree;
            emit evt_gameRecord(room.lastPlayer,room.lastBet,winamount,10,now,num123,room.owner,room.setCount * 100 + room.currentSet,room.initBalance);
            emit evt_calculate(room.lastPlayer,room.owner,num123,winamount,room.roomid,now,myid);
        }
    }
    

    function getBetValue(uint256 initBalance,uint256 curBalance,uint setCount) public pure returns(uint256) {
         
        if(setCount == 0){
            return initBalance;
        }

         
        return SafeMath.div(curBalance,setCount);
    }   

    function deleteRoomByRoomID (uint roomID) internal {
        delete roomMapping[roomID];
        uint len = roomIDList.length;
        for(uint i = 0;i < len;i++){
            if(roomIDList[i] == roomID){
                roomIDList[i] = roomIDList[len - 1];
                roomIDList.length--;
                return;
            }
        }        
    }

    function deleteRoomByIndex (uint index) internal {    
        uint len = roomIDList.length;
        if(index > len - 1){
            return;
        }
        delete roomMapping[roomIDList[index]];
        roomIDList[index] = roomIDList[len - 1];   
        roomIDList.length--;
    }

    function getAllBalance() public view returns(uint256) {
        uint256 ret = 0;
        for(uint i = 0;i < roomIDList.length;i++){
            ret += roomMapping[roomIDList[i]].balance;
        }
        return ret;
    }
    
    function returnAllRoomsBalance() internal {
        for(uint i = 0;i < roomIDList.length;i++){            
            if(roomMapping[roomIDList[i]].balance > 0){
                roomMapping[roomIDList[i]].owner.transfer(roomMapping[roomIDList[i]].balance);
                roomMapping[roomIDList[i]].balance = 0;
                roomMapping[roomIDList[i]].status = roomEnded;
            }
        }
    }

    function removeFreeRoom() internal {
        for(uint i = 0;i < roomIDList.length;i++){
            if(roomMapping[roomIDList[i]].balance ==0 && roomMapping[roomIDList[i]].status == roomEnded){
                deleteRoomByIndex(i);
                removeFreeRoom();
                return;
            }
        }
    }

    function getRoomCount() public view returns(uint) {
        return roomIDList.length;
    }

    function getRoomID(uint index) public view returns(uint)  {
        if(index > roomIDList.length){
            return 0;
        }
        return roomIDList[index];
    } 

    function getRoomInfo(uint index) public view 
        returns(uint roomID,address owner,uint setCount,
            uint256 balance,uint status,uint curSet,uint data) {
        if(index > roomIDList.length){
            return;
        }
        roomID = roomMapping[roomIDList[index]].roomid;
        owner = roomMapping[roomIDList[index]].owner;
        setCount = roomMapping[roomIDList[index]].setCount;
        balance = roomMapping[roomIDList[index]].balance;
        status = roomMapping[roomIDList[index]].status;
        curSet = roomMapping[roomIDList[index]].currentSet;
        data = roomMapping[roomIDList[index]].roomData;
    }    
}

contract DiceOffline is Config,RoomManager,UserManager {
     
    event withdraw_failed();
    event withdraw_succeeded(address toUser,uint256 value);    
    event bet_failed(address indexed player,uint256 value,uint result,uint roomid,uint errorcode);
    event bet_succeeded(address indexed player,uint256 value,uint result,uint roomid,bytes32 serialNumber);    
    event evt_createRoomFailed(address indexed player);
    event evt_createRoomSucceeded(address indexed player,uint roomid);
    event evt_closeRoomFailed(address indexed player,uint roomid);
    event evt_closeRoomSucceeded(address indexed player,uint roomid);

     
    struct BetInfo{
        address player;
        uint result;
        uint256 value;  
        uint roomid;       
    }

    mapping (bytes32 => BetInfo) rollingBet;
    uint256 public allWagered;
    uint256 public allWon;
    uint    public allPlayCount;

    function DiceOffline() public{        
    }  
   
    
     
    function destroy() onlyOwner public{     
        returnAllRoomsBalance();
        selfdestruct(owner);
    }

     
    function () public payable {        
    }

     
    function withdraw(uint256 value) public onlyOwner{
        if(getAvailableBalance() < value){
            emit withdraw_failed();
            return;
        }
        owner.transfer(value);  
        emit withdraw_succeeded(owner,value);
    }

     
    function getAvailableBalance() public view returns (uint256){
        return SafeMath.sub(getBalance(),getAllBalance());
    }

    function rollSystem (uint result,address referral) public payable returns(bool) {
        if(msg.value == 0){
            return;
        }
        BetInfo memory bet = BetInfo(msg.sender,result,msg.value,0);
       
        if(bet.value < minStake){
            bet.player.transfer(bet.value);
            emit bet_failed(bet.player,bet.value,result,0,0);
            return false;
        }

        uint256 maxBet = getAvailableBalance() / 10;
        if(maxBet > maxStake){
            maxBet = maxStake;
        }

        if(bet.value > maxBet){
            bet.player.transfer(SafeMath.sub(bet.value,maxBet));
            bet.value = maxBet;
        }
      
        allWagered += bet.value;
        allPlayCount++;

        addBet(msg.sender,bet.value);
        setReferral(msg.sender,referral);        
         
        bytes32 serialNumber = doOraclize(true);
        rollingBet[serialNumber] = bet;
        emit bet_succeeded(bet.player,bet.value,result,0,serialNumber);        
        return true;
    }   

     
    function openRoom(uint setCount,uint roomData,address referral) public payable returns(bool) {
        if(setCount > 0 && (setCount > maxSet || setCount < minSet)){
            emit evt_createRoomFailed(msg.sender);
            msg.sender.transfer(msg.value);
            return false;
        }
        uint256 minValue = normalRoomMin;
        uint256 maxValue = normalRoomMax;
        if(setCount > 0){
            minValue = tripleRoomMin;
            maxValue = tripleRoomMax;
        }

        if(msg.value < minValue || msg.value > maxValue){
            emit evt_createRoomFailed(msg.sender);
            msg.sender.transfer(msg.value);
            return false;
        }

        allWagered += msg.value;

        uint roomid = tryOpenRoom(msg.sender,msg.value,setCount,roomData);
        setReferral(msg.sender,referral);
        addOpenRoomCount(msg.sender);

        emit evt_createRoomSucceeded(msg.sender,roomid); 
    }

    function closeRoom(uint roomid) public returns(bool) {        
        bool ret = false;
        bool taxPayed = false;        
        (ret,taxPayed) = tryCloseRoom(msg.sender,roomid,taxRate);
        if(!ret){
            emit evt_closeRoomFailed(msg.sender,roomid);
            return false;
        }
        
        emit evt_closeRoomSucceeded(msg.sender,roomid);

        if(!taxPayed){
            subOpenRoomCount(msg.sender);
        }
        
        return true;
    }    

    function rollRoom(uint roomid,address referral) public payable returns(bool) {
        bool ret = tryRollRoom(msg.sender,msg.value,roomid);
        if(!ret){
            emit bet_failed(msg.sender,msg.value,0,roomid,0);
            msg.sender.transfer(msg.value);
            return false;
        }        
        
        BetInfo memory bet = BetInfo(msg.sender,0,msg.value,roomid);

        allWagered += bet.value;
        allPlayCount++;
       
        setReferral(msg.sender,referral);
        addBet(msg.sender,bet.value);
         
        bytes32 serialNumber = doOraclize(false);
        rollingBet[serialNumber] = bet;
        emit bet_succeeded(msg.sender,msg.value,0,roomid,serialNumber);       
        return true;
    }

    function dismissRoom(uint roomid) public onlyOwner {
        tryDismissRoom(roomid);
    } 

    function doOraclize(bool isSystem) internal returns(bytes32) {        
        uint256 random = uint256(keccak256(block.difficulty,now));
        return bytes32(random);       
    }

     

    function doCalculate(uint num123,bytes32 myid) internal {
        BetInfo memory bet = rollingBet[myid];   
        if(bet.player == 0){            
            return;
        }       
        
        if(bet.roomid == 0){     
             
            int256 winAmount = -int256(bet.value);
            if(bet.result == getResult(num123)){
                uint256 tax = (bet.value + bet.value) * taxRate / 1000;                
                winAmount = int256(bet.value - tax);
                addWin(bet.player,uint256(winAmount));
                bet.player.transfer(bet.value + uint256(winAmount));
                fundReferrel(bet.player,tax * referrelFund / 1000);
                allWon += uint256(winAmount);
            }
             
            emit evt_calculate(bet.player,0x0,num123,winAmount,0,now,myid);
            emit evt_gameRecord(bet.player,bet.value,winAmount,bet.result,now,num123,0x0,0,0);
            delete rollingBet[myid];
            return;
        }
        
        doCalculateRoom(num123,myid);
    }

    function doCalculateRoom(uint num123,bytes32 myid) internal {
         
        BetInfo memory bet = rollingBet[myid];         
       
        bool success;
        bool isend;
        address winer;
        uint256 tax;     

        (success,isend,winer,tax) = calculateRoom(bet.roomid,num123,taxRate,myid);
        delete rollingBet[myid];
        if(!success){            
            return;
        }

        if(isend){
            addWin(winer,tax * 1000 / taxRate);
            fundReferrel(winer,SafeMath.div(SafeMath.mul(tax,referrelFund),1000));            
        }        
    }
  
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
}

contract DiceOnline is DiceOffline {    
    using strings for *;     
     
    uint randomQueryID;   
    
    function DiceOnline() public{   
        oraclizeLib.oraclize_setProof(oraclizeLib.proofType_TLSNotary() | oraclizeLib.proofStorage_IPFS());     
        oraclizeLib.oraclize_setCustomGasPrice(20000000000 wei);        
        randomQueryID = 0;
    }    

     
    modifier onlyOraclize {
        require(msg.sender == oraclizeLib.oraclize_cbAddress());
        _;
    }    
    
    function doOraclize(bool isSystem) internal returns(bytes32) {
        randomQueryID += 1;
        string memory queryString1 = "[URL] ['json(https://api.random.org/json-rpc/1/invoke).result.random[\"data\"]', '\\n{\"jsonrpc\":\"2.0\",\"method\":\"generateSignedIntegers\",\"params\":{\"apiKey\":\"";
        string memory queryString2 = random_api_key;
        string memory queryString3 = "\",\"n\":3,\"min\":1,\"max\":6},\"id\":";
        string memory queryString4 = oraclizeLib.uint2str(randomQueryID);
        string memory queryString5 = "}']";

        string memory queryString1_2 = queryString1.toSlice().concat(queryString2.toSlice());
        string memory queryString1_2_3 = queryString1_2.toSlice().concat(queryString3.toSlice());
        string memory queryString1_2_3_4 = queryString1_2_3.toSlice().concat(queryString4.toSlice());
        string memory queryString1_2_3_4_5 = queryString1_2_3_4.toSlice().concat(queryString5.toSlice());
         
        if(isSystem)
            return oraclizeLib.oraclize_query("nested", queryString1_2_3_4_5,systemGasForOraclize);
        else
            return oraclizeLib.oraclize_query("nested", queryString1_2_3_4_5,gasForOraclize);
    }

     
    function __callback(bytes32 myid, string result, bytes proof) public onlyOraclize {
         
        proof;
         
        strings.slice memory sl_result = result.toSlice();
        sl_result = sl_result.beyond("[".toSlice()).until("]".toSlice());        
      
        string memory numString = sl_result.split(', '.toSlice()).toString();
        uint num1 = oraclizeLib.parseInt(numString);
        numString = sl_result.split(', '.toSlice()).toString();
        uint num2 = oraclizeLib.parseInt(numString);
        numString = sl_result.split(', '.toSlice()).toString();
        uint num3 = oraclizeLib.parseInt(numString);
        if(num1 < 1 || num1 > 6){            
            return;
        }
        if(num2 < 1 || num2 > 6){            
            return;
        }
        if(num3 < 1 || num3 > 6){            
            return;
        }        
        doCalculate(num1  * 100 + num2 * 10 + num3,myid);        
    }    
}