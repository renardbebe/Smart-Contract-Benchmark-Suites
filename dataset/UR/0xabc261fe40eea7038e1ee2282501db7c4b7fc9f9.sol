 

pragma solidity ^0.4.24;

interface token {
    function transfer(address receiver, uint amount) external;
}

contract Ownable {

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract ZenswapDistributionTest is Ownable {
    
    token public tokenReward;
    
     
    constructor() public {
        
        tokenReward = token(0xbaD16E6bACaF330D3615539dbf3884836071f279);
        
    }
    
     
    function distributeToken(address[] _addresses, uint256[] _amount) public onlyOwner {
    
    uint256 addressCount = _addresses.length;
    uint256 amountCount = _amount.length;
    require(addressCount == amountCount);
    
    for (uint256 i = 0; i < addressCount; i++) {
        uint256 _tokensAmount = _amount[i] * 10 ** uint256(18);
        tokenReward.transfer(_addresses[i], _tokensAmount);
    }
  }

     
    function withdrawToken(address _address, uint256 _amount) public onlyOwner {
        
        uint256 _tokensAmount = _amount * 10 ** uint256(18); 
        tokenReward.transfer(_address, _tokensAmount);
    }
    
     
    function setTokenReward(address _address) public onlyOwner {
        
        tokenReward = token(_address);
    }
    
}