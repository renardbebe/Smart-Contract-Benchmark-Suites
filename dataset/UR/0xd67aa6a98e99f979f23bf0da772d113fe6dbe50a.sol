 

pragma solidity ^0.4.21;

interface token {
    function transfer(address receiver, uint amount)external;
}

contract Crowdsale {
    address public beneficiary;
    uint public amountRaised;
	uint public allAmountRaised;
    uint public deadline;
    uint public price;
	uint public limitTransfer;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool crowdsaleClosed = false;
	bool public crowdsalePaused = false;

    event FundTransfer(address backer, uint amount, bool isContribution);
    
    modifier onlyOwner {
        require(msg.sender == beneficiary);
        _;
    }
	
	 
    function Crowdsale(
        address ifSuccessfulSendTo,
        uint durationInMinutes,
        uint etherCostOfEachToken,
		uint limitAfterSendToBeneficiary,
        address addressOfTokenUsedAsReward
    )public {
        beneficiary = ifSuccessfulSendTo;
        deadline = now + durationInMinutes * 1 minutes;
        price = etherCostOfEachToken;
        tokenReward = token(addressOfTokenUsedAsReward);
		limitTransfer = limitAfterSendToBeneficiary;
    }
	
	 
    function changeDeadline(uint durationInMinutes) public onlyOwner 
	{
		crowdsaleClosed = false;
        deadline = now + durationInMinutes * 1 minutes;
    }
	
	 
    function changePrice(uint _price) public onlyOwner 
	{
        price = _price;
    }
	
	 
    function pauseCrowdsale()public onlyOwner 
	{
        crowdsaleClosed = true;
		crowdsalePaused = true;
    }
	
	 
    function runCrowdsale()public onlyOwner 
	{
		require(now <= deadline);
        crowdsaleClosed = false;
		crowdsalePaused = false;
    }

     
    function sendToBeneficiary()public onlyOwner 
	{
        if (beneficiary.send(amountRaised)) 
		{
			amountRaised = 0;
			emit FundTransfer(beneficiary, amountRaised, false);
		}
    }
	
	 
    function () public payable 
	{
        require(!crowdsaleClosed);
		require(now <= deadline);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised    += amount;
		allAmountRaised += amount;
        tokenReward.transfer(msg.sender, amount / price);
        emit FundTransfer(msg.sender, amount, true);
		
		if (amountRaised >= limitTransfer)
		{
			if (beneficiary.send(amountRaised)) 
			{
                amountRaised = 0;
				emit FundTransfer(beneficiary, amountRaised, false);
            }
		}
    }
}