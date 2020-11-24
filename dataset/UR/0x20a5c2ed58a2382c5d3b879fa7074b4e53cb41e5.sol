 

pragma solidity ^0.4.26;


 
contract Owned {
    
     
    constructor() public { owner = msg.sender; }
    address owner;

     
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
}

 

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

 

interface ERC20Interface {
    function totalSupply() external constant returns (uint);
    function balanceOf(address tokenOwner) external constant returns (uint balance);
    function allowance(address tokenOwner, address spender) external constant returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 

contract JOBTokenSelfDrop is Owned, SafeMath{

    address tokenContractAddress;
    address ethContributionAddress;
    uint iPricePerToken;
    
     
    function setContractAddress(address tokenAddress) public onlyOwner
    {
        tokenContractAddress = tokenAddress;
    }
    
     
    function getContractAddress() public view returns (address tokenAddress)
    {
        return tokenContractAddress;
    }
    
     
    function setethContributionAddress(address accountAddress) public onlyOwner
    {
        ethContributionAddress = accountAddress;
    }
    
     
    function getethContributionAddress() public view returns (address accountAddress)
    {
        return ethContributionAddress;
    }
    
     
    function setPricePerToken(uint Price) public onlyOwner
    {
        iPricePerToken = Price;
    }
    
     
    function getPricePerToken() public view returns (uint Price)
    {
        return iPricePerToken;
    }
    
     
    function withdrawTokens(uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenContractAddress).transfer(msg.sender, tokens);
    }
    
     
    function () public payable
    {
        if (msg.value > 0) 
        {
            uint tokenCount;
            
            tokenCount = safeDiv(msg.value,iPricePerToken);
            
            if (msg.value <= 1 ether)
            {
                tokenCount = tokenCount + 0;
            }
            else if(msg.value <= 2 ether)
            {
                tokenCount = tokenCount + safeDiv(tokenCount,10);
            }
            else if(msg.value <= 5 ether)
            {
                tokenCount = tokenCount + safeDiv(tokenCount,20);
            }
            else if(msg.value <= 10 ether)
            {
                tokenCount = tokenCount + safeDiv(tokenCount,30);
            }
            else if(msg.value <= 50 ether)
            {
                tokenCount = tokenCount + safeDiv(tokenCount,40);
            }
            else
            {
                tokenCount = tokenCount + safeDiv(tokenCount,50);
            }
            
             
            ERC20Interface(tokenContractAddress).transfer(msg.sender, tokenCount);
            
             
            ethContributionAddress.transfer(msg.value);
        }
        
    }

}