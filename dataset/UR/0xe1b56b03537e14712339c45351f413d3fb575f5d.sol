 

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

contract ZenswapContribution is Ownable {
    
    address public beneficiary;
    uint256 public amountTokensPerEth = 200000000;
    uint256 public amountEthRaised = 0;
    uint256 public availableTokens;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    
    
     
    constructor() public {
        
        beneficiary = msg.sender;
        tokenReward = token(0x0D1C63E12fDE9e5cADA3E272576183AbA9cfedA2);
    }

     
    function () payable public {
        
        uint256 amount = msg.value;
        uint256 tokens = amount * amountTokensPerEth;
        require(availableTokens >= amount);
        
        balanceOf[msg.sender] += amount;
        availableTokens -= tokens;
        amountEthRaised += amount;
        tokenReward.transfer(msg.sender, tokens);
        beneficiary.transfer(amount);
    }

     
    function withdrawAvailableToken(address _address, uint amount) public onlyOwner {
        require(availableTokens >= amount);
        availableTokens -= amount;
        tokenReward.transfer(_address, amount);
    }
    
     
    function setTokensPerEth(uint value) public onlyOwner {
        
        amountTokensPerEth = value;
    }
    
    
    function setTokenReward(address _address, uint amount) public onlyOwner {
        
        tokenReward = token(_address);
        availableTokens = amount;
    }
    
    
    function setAvailableToken(uint value) public onlyOwner {
        
        availableTokens = value;
    }
    
    
    
}