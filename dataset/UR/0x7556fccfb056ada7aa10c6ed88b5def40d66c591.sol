 

pragma solidity ^0.4.26;
pragma experimental ABIEncoderV2;

interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract OffChainOrFeedPriceFeed{
    
    address owner; 
    mapping(string => uint256) quotes;
    mapping(string => uint256) quoteTimes;
    
    constructor() public {
         owner = msg.sender;
     }
     
    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }
    
    
    function changeOwner(address newOwner) onlyOwner external returns(bool) {
        owner = newOwner;
        return true;
    }
    
    
    function getLastPrice (string symbol) constant returns (uint256){
        return quotes[symbol];
    }
     function getTimeUpdated (string symbol) constant returns (uint256){
        return quoteTimes[symbol];
    }
    function getOwner() constant returns(address){
        return owner;
    }
    
    function updatePrices(string[] symbols, uint256[] prices) public onlyOwner  returns (bool){
        uint256 arrayLength = symbols.length;
        
        for (uint i=0; i<arrayLength; i++) {
            string memory thisQuote = symbols[i];
            quotes[thisQuote] = prices[i];
            quoteTimes[thisQuote] = block.timestamp;
        }
        return true;
    }
    
    
     
    function withdrawETHAndTokens(address tokenAddress) onlyOwner{

        msg.sender.send(address(this).balance);
        ERC20 daiToken = ERC20(tokenAddress);
        uint256 currentTokenBalance = daiToken.balanceOf(this);
        daiToken.transfer(msg.sender, currentTokenBalance);

    }
    
    
}