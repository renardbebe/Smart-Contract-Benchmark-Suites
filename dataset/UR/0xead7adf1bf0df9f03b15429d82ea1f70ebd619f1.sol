 

pragma solidity ^0.4.13;
contract token { 
   function mintToken(address target, uint256 mintedAmount);
}

contract owned { 
    address public owner;
    
    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract Crowdsale is owned {
    address public beneficiary;
    
    uint256 public preICOLimit;
    uint256 public totalLimit;
    
    uint256 public pricePreICO;
    uint256 public priceICO;

    bool preICOClosed = false;
    bool ICOClosed = false;

    bool preICOWithdrawn = false;
    bool ICOWithdrawn = false;

    bool public preICOActive = false;
    bool public ICOActive = false;

    uint256 public preICORaised; 
    uint256 public ICORaised; 
    uint256 public totalRaised; 

    token public tokenReward;

    event FundTransfer(address backer, uint256 amount, bool isContribution);

    mapping(address => uint256) public balanceOf;

    function Crowdsale() {
        preICOLimit = 5000000 * 1 ether;
        totalLimit = 45000000 * 1 ether;  
        pricePreICO = 375;
        priceICO = 250;
    }

    function init(address beneficiaryAddress, token tokenAddress)  onlyOwner {
        beneficiary = beneficiaryAddress;
        tokenReward = token(tokenAddress);
    }

    function () payable {
        require (preICOActive || ICOActive);
        uint256 amount = msg.value;

        require (amount >= 0.05 * 1 ether);  

         
         
         
        if(preICOActive)
        {
    	    tokenReward.mintToken(msg.sender, amount * pricePreICO);
            preICORaised += amount;
        }
        if(ICOActive)
        {
    	    tokenReward.mintToken(msg.sender, amount * priceICO);
            ICORaised += amount;
        }

        balanceOf[msg.sender] += amount;
        totalRaised += amount;
        FundTransfer(msg.sender, amount, true);

        if(preICORaised >= preICOLimit)
        {
            preICOActive = false;
            preICOClosed = true;
        }
        
        if(totalRaised >= totalLimit)
        {
            preICOActive = false;
            ICOActive = false;
            preICOClosed = true;
            ICOClosed = true;
        }
    }
    
    function startPreICO() onlyOwner {
        require(!preICOClosed);
        require(!preICOActive);
        require(!ICOClosed);
        require(!ICOActive);
        
        preICOActive = true;
    }
    function stopPreICO() onlyOwner {
        require(preICOActive);
        
        preICOActive = false;
        preICOClosed = true;
    }
    function startICO() onlyOwner {
        require(preICOClosed);
        require(!ICOClosed);
        require(!ICOActive);
        
        ICOActive = true;
    }
    function stopICO() onlyOwner {
        require(ICOActive);
        
        ICOActive = false;
        ICOClosed = true;
    }


     
    function withdrawFunds() onlyOwner {
	require ((!preICOWithdrawn && preICOClosed) || (!ICOWithdrawn && ICOClosed));

             
            if(!preICOWithdrawn && preICOClosed)
            {
                if (beneficiary.send(preICORaised)) {
                    preICOWithdrawn = true;
                    FundTransfer(beneficiary, preICORaised, false);
                }
            }
             
            if(!ICOWithdrawn && ICOClosed)
            {
                if (beneficiary.send(ICORaised)) {
                    ICOWithdrawn = true;
                    FundTransfer(beneficiary, ICORaised, false);
                }
            }
    }
}