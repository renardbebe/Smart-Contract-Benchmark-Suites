 

pragma solidity ^0.5.10;

contract Trusti {
    string public data = "trusti.id";
    
    function getData() public view returns (string memory) {
        return data;
    }
    
    function setData(string memory _dataHash, string memory _dataSignee) public {
        data = _dataHash;
        data = _dataSignee;
    }
}