 

pragma solidity 0.4.25;

 
contract MyMileage {

     
    address private owner;

     
    mapping(bytes32 => uint) private map;

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    constructor() public {
        owner = msg.sender;
    }

     
    function put(bytes32 fileHash) onlyOwner public {

         
        require(free(fileHash));

         
        map[fileHash] = now;
    }

     
    function free(bytes32 fileHash) view public returns (bool) {
        return map[fileHash] == 0;
    }

     
    function get(bytes32 fileHash) view public returns (uint) {
        return map[fileHash];
    }

     
     
    function getConfirmationCode() view public returns (bytes32) {
        return blockhash(block.number - 6);
    }
}