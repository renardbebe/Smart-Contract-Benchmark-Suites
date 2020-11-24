 

 

pragma solidity ^0.4.22;

 
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
    
     
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }
    
     
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }
    
     
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
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

     
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }
    
}

contract owned {
    address public holder;

    constructor() public {
        holder = msg.sender;
    }

    modifier onlyHolder {
        require(msg.sender == holder, "This function can only be called by holder");
        _;
    }
}

contract asset is owned {
    using strings for *;

     
    struct data {
         
         
        string link;
         
        string encryptionType;
         
        string hashValue;
    }

    data[] dataArray;
    uint dataNum;

     
    bool public isValid;
    
     
    bool public isInit;
    
     
    bool public isTradeable;
    uint public price;

     
    string public remark1;

     
     
    string public remark2;

     
    constructor() public {
        isValid = true;
        isInit = false;
        isTradeable = false;
        price = 0;
        dataNum = 0;
    }

     
    function initAsset(
        uint dataNumber,
        string linkSet,
        string encryptionTypeSet,
        string hashValueSet) public onlyHolder {
         
        var links = linkSet.toSlice();
        var encryptionTypes = encryptionTypeSet.toSlice();
        var hashValues = hashValueSet.toSlice();
        var delim = " ".toSlice();
        
        dataNum = dataNumber;
        
         
        require(isInit == false, "The contract has been initialized");

         
        require(dataNumber >= 1, "Param dataNumber smaller than 1");
        require(dataNumber - 1 == links.count(delim), "Param linkSet invalid");
        require(dataNumber - 1 == encryptionTypes.count(delim), "Param encryptionTypeSet invalid");
        require(dataNumber - 1 == hashValues.count(delim), "Param hashValueSet invalid");
        
        isInit = true;
        
        var empty = "".toSlice();
        
        for (uint i = 0; i < dataNumber; i++) {
            var link = links.split(delim);
            var encryptionType = encryptionTypes.split(delim);
            var hashValue = hashValues.split(delim);
            
             
             
            require(!encryptionType.empty(), "Param encryptionTypeSet data error");
            require(!hashValue.empty(), "Param hashValueSet data error");
            
            dataArray.push(
                data(link.toString(), encryptionType.toString(), hashValue.toString())
                );
        }
    }
    
      
    function getAssetBaseInfo() public view returns (uint _price,
                                                 bool _isTradeable,
                                                 uint _dataNum,
                                                 string _remark1,
                                                 string _remark2) {
        require(isValid == true, "contract invaild");
        _price = price;
        _isTradeable = isTradeable;
        _dataNum = dataNum;
        _remark1 = remark1;
        _remark2 = remark2;
    }
    
     
    function getDataByIndex(uint index) public view returns (string link, string encryptionType, string hashValue) {
        require(isValid == true, "contract invaild");
        require(index >= 0, "Param index smaller than 0");
        require(index < dataNum, "Param index not smaller than dataNum");
        link = dataArray[index].link;
        encryptionType = dataArray[index].encryptionType;
        hashValue = dataArray[index].hashValue;
    }

     
    function setPrice(uint newPrice) public onlyHolder {
        require(isValid == true, "contract invaild");
        price = newPrice;
    }

     
    function setTradeable(bool status) public onlyHolder {
        require(isValid == true, "contract invaild");
        isTradeable = status;
    }

     
    function setRemark1(string content) public onlyHolder {
        require(isValid == true, "contract invaild");
        remark1 = content;
    }

     
    function setRemark2(string content) public onlyHolder {
        require(isValid == true, "contract invaild");
        remark2 = content;
    }

     
    function setDataLink(uint index, string url) public onlyHolder {
        require(isValid == true, "contract invaild");
        require(index >= 0, "Param index smaller than 0");
        require(index < dataNum, "Param index not smaller than dataNum");
        dataArray[index].link = url;
    }

     
    function cancelContract() public onlyHolder {
        isValid = false;
    }
    
     
    function getDataNum() public view returns (uint num) {
        num = dataNum;
    }

     
    function transferOwnership(address newHolder, bool status) public onlyHolder {
        holder = newHolder;
        isTradeable = status;
    }
}