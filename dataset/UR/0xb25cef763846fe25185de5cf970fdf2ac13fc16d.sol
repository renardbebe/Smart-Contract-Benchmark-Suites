 

pragma solidity ^0.4.19;

interface token {
    function transfer(address receiver, uint amount);
}

contract Crowdsale {
    address public beneficiary;
    uint public amountRaised;
    token public tokenReward;
    uint256 public soldTokensCounter;
    uint public price;
    uint public saleStage = 1;
    bool public crowdsaleClosed = false;
    bool public adminVer = false;
    mapping(address => uint256) public balanceOf;

    event FundTransfer(address backer, uint amount, uint price, bool isContribution);

     
    function Crowdsale() {
        beneficiary = msg.sender;
        tokenReward = token(0x745Fa4002332C020f6a05B3FE04BCCf060e36dD3);
    }

    modifier onlyOwner {
        require(msg.sender == beneficiary);
        _;
    }

     
    function checkAdmin() onlyOwner {
        adminVer = true;
    }

     
    function changeStage(uint stage) onlyOwner {
        saleStage = stage;
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

     
    function getPrice() returns (uint) {
        if (saleStage == 4) {
            return 0.0002000 ether;
        } else if (saleStage == 3) {
            return 0.0001667 ether;
        } else if (saleStage == 2) {
            return 0.0001429 ether;
        }
        return 0.000125 ether;
    }

     
    function () payable {
        require(!crowdsaleClosed);                                                         
        price = getPrice();                                                                 
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