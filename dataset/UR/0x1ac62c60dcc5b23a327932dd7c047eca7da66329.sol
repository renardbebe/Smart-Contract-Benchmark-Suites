 

pragma solidity ^0.5.8;
contract CheckAddress {
    uint256 createTime;
    constructor () public {
      
        createTime = now;
    }
    function() external payable {
        require(createTime > now);
    }
}