 

pragma solidity 0.4.21;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) 
            return 0;

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

interface Token {
    function transfer(address to, uint256 value) external returns (bool success);
    function burn(uint256 amount) external;
    function balanceOf(address owner) external returns (uint256 balance);
}

contract Crowdsale {
    address public owner;                        
    address public fundRaiser;                   
    uint256 public amountRaisedInWei;            
    uint256 public tokensSold;                   
    uint256 public tokensClaimed;                
    uint256 public icoDeadline;                  
    uint256 public tokensClaimableAfter;         
    uint256 public tokensPerWei;                 
    Token public tokenReward;                    

     
    mapping(address => Participant) public participants;    

     
    struct Participant {
        bool whitelisted;
        uint256 tokens;
        bool tokensClaimed;
    }

    event FundTransfer(address to, uint amount);

    modifier afterIcoDeadline() { if (now >= icoDeadline) _; }
    modifier afterTokensClaimableDeadline() { if (now >= tokensClaimableAfter) _; }
    modifier onlyOwner() { require(msg.sender == owner); _; }

     
    function Crowdsale(
        address fundRaiserAccount,
        uint256 durationOfIcoInDays,
        uint256 durationTokensClaimableAfterInDays,
        uint256 tokensForOneWei,
        address addressOfToken
    ) 
        public 
    {
        owner = msg.sender;
        fundRaiser = fundRaiserAccount;
        icoDeadline = now + durationOfIcoInDays * 1 days;
        tokensClaimableAfter = now + durationTokensClaimableAfterInDays * 1 days;
        tokensPerWei = tokensForOneWei;
        tokenReward = Token(addressOfToken);
    }

     
    function() payable public {
        require(now < icoDeadline);
        require(participants[msg.sender].whitelisted);             
        require(msg.value >= 0.01 ether); 
        uint256 tokensToBuy = SafeMath.mul(msg.value, tokensPerWei);
        require(tokensToBuy <= SafeMath.sub(tokenReward.balanceOf(this), tokensSold));
        participants[msg.sender].tokens = SafeMath.add(participants[msg.sender].tokens, tokensToBuy);      
        amountRaisedInWei = SafeMath.add(amountRaisedInWei, msg.value);
        tokensSold = SafeMath.add(tokensSold, tokensToBuy);
    }
    
      
    function addToWhitelist(address addr) onlyOwner public {
        participants[addr].whitelisted = true;   
    }

      
    function removeFromWhitelist(address addr) onlyOwner public {
        participants[addr].whitelisted = false;   
    }

      
    function addAddressesToWhitelist(address[] addresses) onlyOwner public {
        for (uint i = 0; i < addresses.length; i++) {
            participants[addresses[i]].whitelisted = true;   
        }
    }

      
    function removeAddressesFromWhitelist(address[] addresses) onlyOwner public {
        for (uint i = 0; i < addresses.length; i++) {
            participants[addresses[i]].whitelisted = false;   
        }
    }

     

      
    function withdrawFunds() afterIcoDeadline public {
        require(fundRaiser == msg.sender);
        fundRaiser.transfer(address(this).balance);
        emit FundTransfer(fundRaiser, address(this).balance);        
    }

      
    function burnUnsoldTokens()  onlyOwner afterIcoDeadline public {  
        uint256 tokensUnclaimed = SafeMath.sub(tokensSold, tokensClaimed);
        uint256 unsoldTokens = SafeMath.sub(tokenReward.balanceOf(this), tokensUnclaimed);
        tokenReward.burn(unsoldTokens);
    }    

      
    function transferUnsoldTokens(address toAddress) onlyOwner afterIcoDeadline public {
        uint256 tokensUnclaimed = SafeMath.sub(tokensSold, tokensClaimed);
        uint256 unsoldTokens = SafeMath.sub(tokenReward.balanceOf(this), tokensUnclaimed);
        tokenReward.transfer(toAddress, unsoldTokens);
    }

     

      
    function withdrawTokens() afterTokensClaimableDeadline public {
        require(participants[msg.sender].whitelisted);                
        require(!participants[msg.sender].tokensClaimed);        
        participants[msg.sender].tokensClaimed = true;
        uint256 tokens = participants[msg.sender].tokens;
        tokenReward.transfer(msg.sender, tokens); 
        tokensClaimed = SafeMath.add(tokensClaimed, tokens);
    }
}