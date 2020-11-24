 

pragma solidity ^0.4.25;

 
contract RocketCash
{
    uint constant public start = 1541678400; 
     
    address constant public administrationFund = 0x97a121027a529B96f1a71135457Ab8e353060811; 
    mapping (address => uint) public invested; 
    mapping (address => uint) private lastInvestmentTime; 
    mapping (address => uint) private collected; 
    uint public investedTotal; 
    uint public investorsCount; 

    event investment(address addr, uint amount, uint invested); 
    event withdraw(address addr, uint amount, uint invested); 

    function () external payable 
    {
        if (msg.value > 0 ether) 
        {
            if (start < now) 
            {
                if (invested[msg.sender] != 0)  
                {
                    collected[msg.sender] = availableDividends(msg.sender); 
                     
                }
                 

                lastInvestmentTime[msg.sender] = now; 
            }
            else 
            {
                lastInvestmentTime[msg.sender] = start; 
            }

            if (invested[msg.sender] == 0) investorsCount++; 
            investedTotal += msg.value; 

            invested[msg.sender] += msg.value; 

            administrationFund.transfer(msg.value * 15 / 100); 

            emit investment(msg.sender, msg.value, invested[msg.sender]); 
        }
        else 
         
        {
            uint withdrawalAmount = availableWithdraw(msg.sender);

            if (withdrawalAmount != 0) 
            {
                emit withdraw(msg.sender, withdrawalAmount, invested[msg.sender]); 

                msg.sender.transfer(withdrawalAmount); 

                lastInvestmentTime[msg.sender] = 0; 
                invested[msg.sender]           = 0; 
                collected[msg.sender]          = 0; 
            }
             
        }
    }

    function availableWithdraw (address investor) public view returns (uint) 
    {
        if (start < now) 
        {
            if (invested[investor] != 0) 
            {
                uint dividends = availableDividends(investor); 
                uint canReturn = invested[investor] - invested[investor] * 15 / 100; 

                if (canReturn < dividends) 
                {
                    return dividends;
                }
                else 
                {
                    return canReturn;
                }
            }
            else 
            {
                return 0;
            }
        }
        else 
        {
            return 0;
        }
    }

    function availableDividends (address investor) private view returns (uint) 
    {
        return collected[investor] + dailyDividends(investor) * (now - lastInvestmentTime[investor]) / 1 days; 
    }

    function dailyDividends (address investor) public view returns (uint) 
    {
        if (invested[investor] < 1 ether) 
        {
            return invested[investor] * 222 / 10000; 
        }
        else if (1 ether <= invested[investor] && invested[investor] < 5 ether) 
        {
            return invested[investor] * 255 / 10000; 
        }
        else 
        {
            return invested[investor] * 288 / 10000; 
        }
    }
}