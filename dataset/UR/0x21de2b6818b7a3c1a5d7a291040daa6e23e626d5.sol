 

 


pragma solidity ^0.4.19;

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract mall is owned {

     
    struct Commodity {
        uint commodityId;             
        uint seedBlock;          
        string MD5;          
    }

    uint commodityNum;
     
    mapping(uint => Commodity) commodities;
    mapping(uint => uint) indexMap;

     
    constructor() public {
        commodityNum = 1;
    }

     
    function newCommodity(uint commodityId, uint seedBlock, string MD5) onlyOwner public returns (uint commodityIndex) {
        require(indexMap[commodityId] == 0);              
        commodityIndex = commodityNum++;
        indexMap[commodityId] = commodityIndex;
        commodities[commodityIndex] = Commodity(commodityId, seedBlock, MD5);
    }

     
    function getCommodityInfoByIndex(uint commodityIndex) onlyOwner public view returns (uint commodityId, uint seedBlock, string MD5) {
        require(commodityIndex < commodityNum);                
        require(commodityIndex >= 1);                     
        commodityId = commodities[commodityIndex].commodityId;
        seedBlock = commodities[commodityIndex].seedBlock;
        MD5 = commodities[commodityIndex].MD5;
    }

     
    function getCommodityInfoById(uint commodityId) public view returns (uint commodityIndex, uint seedBlock, string MD5) {
        commodityIndex = indexMap[commodityId];
        require(commodityIndex < commodityNum);               
        require(commodityIndex >= 1);                    
        seedBlock = commodities[commodityIndex].seedBlock;
        MD5 = commodities[commodityIndex].MD5;
    }

     
    function getCommodityNum() onlyOwner public view returns (uint num) {
        num = commodityNum - 1;
    }
}