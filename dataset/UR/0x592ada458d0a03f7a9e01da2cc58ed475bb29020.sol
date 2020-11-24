 

pragma solidity ^0.4.18;
interface token {
    function transfer(address receiver, uint amount) public;                                     
    function getBalanceOf(address _owner) public constant returns (uint256 balance);             
}
contract Presale {
    address public beneficiary;                      
    uint public fundingLimit;                        
    uint public amountRaised;                        
    uint public deadline;                            
    uint public tokensPerEther;                      
    uint public minFinnRequired;                     
    uint public startTime;                           
    token public tokenReward;                        
    
    mapping(address => uint256) public balanceOf;    
    event FundTransfer(address backer, uint amount, bool isContribution);    
     
    function Presale(
        address ifSuccessfulSendTo,
        uint fundingLimitInEthers,
        uint durationInMinutes,
        uint tokensPerEthereum,
        uint minFinneyRequired,
        uint presaleStartTime,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = ifSuccessfulSendTo;
        fundingLimit = fundingLimitInEthers * 1 ether;
        deadline = presaleStartTime + durationInMinutes * 1 minutes;
        tokensPerEther = tokensPerEthereum;
        minFinnRequired = minFinneyRequired * 1 finney;
        startTime = presaleStartTime;
        tokenReward = token(addressOfTokenUsedAsReward);
    }
     
    function () payable public {
        require(startTime <= now);
        require(amountRaised < fundingLimit);
        require(msg.value >= minFinnRequired);
        
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount * tokensPerEther);
        FundTransfer(msg.sender, amount, true);
    }
     
    function withdrawFundBeneficiary() public {
        require(now >= deadline);
        require(beneficiary == msg.sender);
        uint remaining = tokenReward.getBalanceOf(this);
        if(remaining > 0) {
            tokenReward.transfer(beneficiary, remaining);
        }
        if (beneficiary.send(amountRaised)) {
            FundTransfer(beneficiary, amountRaised, false);
        } else {
            revert();
        }
    }
}