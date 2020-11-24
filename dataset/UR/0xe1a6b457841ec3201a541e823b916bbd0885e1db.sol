 

pragma solidity ^0.4.2;

 
 
contract Token {
     
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract HumaniqToken is Token {
    function issueTokens(address _for, uint tokenCount) payable returns (bool);
    function changeEmissionContractAddress(address newAddress) returns (bool);
}

 
 
contract HumaniqICO {

     
    HumaniqToken public humaniqToken = HumaniqToken(0x9734c136F5c63531b60D02548Bca73a3d72E024D);

     
    uint constant public CROWDFUNDING_PERIOD = 12 days;
     
    uint constant public CROWDSALE_TARGET = 10000 ether;

     
    address public founder;
    address public multisig;
    uint public startDate = 0;
    uint public icoBalance = 0;
    uint public baseTokenPrice = 666 szabo;  
    uint public discountedPrice = baseTokenPrice;
    bool public isICOActive = false;

     
    mapping (address => uint) public investments;

     
    modifier onlyFounder() {
         
        if (msg.sender != founder) {
            throw;
        }
        _;
    }

    modifier minInvestment() {
         
        if (msg.value < baseTokenPrice) {
            throw;
        }
        _;
    }

    modifier icoActive() {
        if (isICOActive == false) {
            throw;
        }
        _;
    }

    modifier applyBonus() {
        uint icoDuration = now - startDate;
        if (icoDuration >= 248 hours) {
            discountedPrice = baseTokenPrice;
        }
        else if (icoDuration >= 176 hours) {
            discountedPrice = (baseTokenPrice * 100) / 107;
        }
        else if (icoDuration >= 104 hours) {
            discountedPrice = (baseTokenPrice * 100) / 120;
        }
        else if (icoDuration >= 32 hours) {
            discountedPrice = (baseTokenPrice * 100) / 142;
        }
        else if (icoDuration >= 12 hours) {
            discountedPrice = (baseTokenPrice * 100) / 150;
        }
        else {
            discountedPrice = (baseTokenPrice * 100) / 170;
        }
        _;
    }

     
     
    function fund()
        public
        applyBonus
        icoActive
        minInvestment
        payable
        returns (uint)
    {
         
        uint tokenCount = msg.value / discountedPrice;
         
        uint investment = tokenCount * discountedPrice;
         
        if (msg.value > investment && !msg.sender.send(msg.value - investment)) {
            throw;
        }
         
        icoBalance += investment;
        investments[msg.sender] += investment;
         
        if (!multisig.send(investment)) {
             
            throw;
        }
        if (!humaniqToken.issueTokens(msg.sender, tokenCount)) {
             
            throw;
        }
        return tokenCount;
    }

     
     
     
    function fundBTC(address beneficiary, uint _tokenCount)
        external
        applyBonus
        icoActive
        onlyFounder
        returns (uint)
    {
         
        uint investment = _tokenCount * discountedPrice;
         
        icoBalance += investment;
        investments[beneficiary] += investment;
        if (!humaniqToken.issueTokens(beneficiary, _tokenCount)) {
             
            throw;
        }
        return _tokenCount;
    }

     
     
    function finishCrowdsale()
        external
        onlyFounder
        returns (bool)
    {
        if (isICOActive == true) {
            isICOActive = false;
             
            uint founderBonus = ((icoBalance / baseTokenPrice) * 114) / 100;
            if (!humaniqToken.issueTokens(multisig, founderBonus)) {
                 
                throw;
            }
        }
    }

     
     
    function changeBaseTokenPrice(uint valueInWei)
        external
        onlyFounder
        returns (bool)
    {
        baseTokenPrice = valueInWei;
        return true;
    }

     
    function startICO()
        external
        onlyFounder
    {
        if (isICOActive == false && startDate == 0) {
           
          isICOActive = true;
           
          startDate = now;
        }
    }

     
    function HumaniqICO(address _multisig) {
         
        founder = msg.sender;
         
        multisig = _multisig;
    }

     
    function () payable {
        fund();
    }
}