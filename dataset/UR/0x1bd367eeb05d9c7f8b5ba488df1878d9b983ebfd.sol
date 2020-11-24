 

pragma solidity ^0.4.19;

interface token {
    function transfer(address receiver, uint amount);
}

contract Crowdsale {
    address public beneficiary;
    uint public amountRaised;
    token public tokenReward;
    uint256 public soldTokensCounter;
    uint public price = 0.000109890 ether;
    bool public crowdsaleClosed = false;
    bool public adminVer = false;
    mapping(address => uint256) public balanceOf;


    event FundTransfer(address backer, uint amount, uint price, bool isContribution);

     
    function Crowdsale() {
        beneficiary = msg.sender;
        tokenReward = token(0x12AC8d8F0F48b7954bcdA736AF0576a12Dc8C387);
    }

    modifier onlyOwner {
        require(msg.sender == beneficiary);
        _;
    }

     
    function checkAdmin() onlyOwner {
        adminVer = true;
    }

     
    function getUnsoldTokens(uint val_) onlyOwner {
        tokenReward.transfer(beneficiary, val_);
    }

     
    function getUnsoldTokensWithDecimals(uint val_, uint dec_) onlyOwner {
        val_ = val_ * 10 ** dec_;
        tokenReward.transfer(beneficiary, val_);
    }

     
    function closeCrowdsale(bool closeType) onlyOwner {
        crowdsaleClosed = closeType;
    }

     
    function () payable {
        require(!crowdsaleClosed);                                                          
        uint amount = msg.value;                                                            
        balanceOf[msg.sender] += amount;                                                    
        amountRaised += amount;                                                             
        uint sendTokens = (amount / price) * 10 ** uint256(18);                             
        tokenReward.transfer(msg.sender, sendTokens);                                       
        soldTokensCounter += sendTokens;                                                    
        FundTransfer(msg.sender, amount, price, true);                                      
        if (beneficiary.send(amount)) { FundTransfer(beneficiary, amount, price, false); }  
    }
}