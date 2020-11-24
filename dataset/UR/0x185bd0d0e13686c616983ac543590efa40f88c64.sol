 

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

     
    function put(bytes32 imageHash) onlyOwner public {

         
        require(free(imageHash));

         
        map[imageHash] = now;
    }

     
    function free(bytes32 imageHash) view public returns (bool) {
        return map[imageHash] == 0;
    }

     
    function get(bytes32 imageHash) view public returns (uint) {
        return map[imageHash];
    }
    
     
     
    function getConfirmationCode() view public returns (bytes32) {
        return blockhash(block.number - 6);
    }
}