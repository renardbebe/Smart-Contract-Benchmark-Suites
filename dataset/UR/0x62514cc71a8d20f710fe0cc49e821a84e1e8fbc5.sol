 

pragma solidity ^0.4.24;

contract Storage {
    address owner;  
    
    bytes32[] public data;  
    uint remainder;  
    
    bool readOnly;  

    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier readWrite () {
        require(readOnly != true);
        _;
    }

     
    function uploadData(bytes _data) onlyOwner readWrite public {

        uint startPoint;

        if(remainder != 0) {

            startPoint = 32 - remainder;
            bytes memory rest = new bytes(32);
            for(uint i = 0; i < remainder; i++) {
                rest[i] = data[data.length - 1][i];
            }
            for(i = 0; i < startPoint; i++) {
                rest[remainder + i] = _data[i];
            }
            bytes32 p;
            assembly {
                p := mload(add(rest, 32))
            }
            data[data.length - 1] = p;
        }
        for(i = 0; i < (uint(_data.length - startPoint) / 32); i++) {
            bytes32 word;
            assembly {
                word:= mload(add(_data, add(add(32, startPoint), mul(i, 32))))
            }
            data.push(word);
        }
        uint loose = (_data.length - startPoint) % 32;
        if(loose != 0) {
            uint position = _data.length - loose;
            bytes32 leftover;
            assembly {
                leftover := mload(add(_data, add(32, position)))
            }
            data.push(leftover);
        }
        remainder = loose;
    }
     
    function erase(uint _entriesToDelete) onlyOwner readWrite public {
        require(_entriesToDelete != 0);
        if(data.length < _entriesToDelete) { 
            delete data;
        }
        else data.length -= _entriesToDelete;
        remainder = 0;
    }
    function uploadFinish() onlyOwner public {
        readOnly = true;
    }

     
     

    function getData() public view returns (bytes){
        bytes memory result = new bytes(data.length*0x20);
        for(uint i = 0; i < data.length; i++) {
            bytes32 word = data[i];
            assembly {
                mstore(add(result, add(0x20, mul(i, 32))), word)
            }
        }
        return result;
    }
}