 

pragma solidity ^0.4.11;

contract Risk
{
    address owner;
    mapping (address => uint8 []) playerCountries;
    address[178] ownerofCountry;  
    address[] playerList;
    uint256 totalmoney=0;
    uint256 lastR=3;
    address lastgameendWinner=address(0);   
    uint8 winnerLimit=20;
    
    address[10] winnerloser;  

    function Risk() 
    {
        owner = msg.sender;
    }
    
    function buyCountry(uint8 countryID) payable returns(bool)
    {
        assert(ownerofCountry[countryID]==0);  
        assert(msg.value == 10 finney);  
        
        totalmoney +=msg.value;
        playerCountries[msg.sender].push(countryID);
        ownerofCountry[countryID]=msg.sender;
        playerList.push(msg.sender);
        
        return true;
    }
    
    function attackCountry(uint8 countryID)
    {
        assert(playerCountries[msg.sender].length!=0);  
        assert(ownerofCountry[countryID]!=address(0));  
        assert(msg.sender!=ownerofCountry[countryID]);  
        
        address attacker = msg.sender;
        address defender = ownerofCountry[countryID];
        
        uint a=playerCountries[attacker].length;
        uint b=playerCountries[defender].length;

        for(uint256 i=9;i>=6;i--)
            winnerloser[i]=winnerloser[i-1];
        for(i=4;i>=1;i--)
            winnerloser[i]=winnerloser[i-1];
        
        uint256 loopcount=0;
        lastR=uint256(block.blockhash(block.number-1))%(a+b);
        if(lastR<a)  
        {
            loopcount=playerCountries[defender].length;
            for (i=0;i<loopcount;i++)
            {
                playerCountries[attacker].push(playerCountries[defender][i]);
                ownerofCountry[playerCountries[defender][i]]=attacker;
            }
            playerCountries[defender].length=0;
            winnerloser[0]=attacker;
            winnerloser[5]=defender;
        }
        else  
        {
            loopcount=playerCountries[attacker].length;
            for (i=0;i<loopcount;i++)
            {
                playerCountries[defender].push(playerCountries[attacker][i]);
                ownerofCountry[playerCountries[attacker][i]]=defender;
            }
            playerCountries[attacker].length=0;
            winnerloser[0]=defender;
            winnerloser[5]=attacker;
        }
        isGameEnd();
    }
    function isGameEnd()
    {
        uint256 loopcount=playerList.length;
        address winner=owner;
        
         
        bool del=false;
        for (uint8 i=0; i<loopcount;i++)
        {
            if(playerCountries[playerList[i]].length>=winnerLimit)  
            {
                winner=playerList[i];
                del=true;
                
                break;
            }
        }
         
        if(del)
        {
            winner.transfer(totalmoney/10*9);  
            owner.transfer(totalmoney/10);
            totalmoney=0;
            lastgameendWinner=winner;
            for (i=0;i<178;i++)
            {
                playerCountries[ownerofCountry[i]].length=0;
                ownerofCountry[i]=0;
            }
            playerList.length=0;
            for(i=0;i<10;i++)
                winnerloser[i]=address(0);
        }
    }
    function setwinnerLimit (uint8 x)
    {
        assert(msg.sender==owner);
        winnerLimit=x;
    }
    function getCountryOwnershipList() constant returns (address[178])
    {
        return ownerofCountry;
    }
    function getTotalBet()constant returns (uint256)
    {
        return totalmoney;
    }
    function getaddr(address ax, uint8 bx) constant returns(address)
    {
        return playerCountries[ax][bx];
    }
    function len(address ax) constant returns(uint)
    {
        return playerCountries[ax].length;
    }
    function lastrandom() constant returns(uint256)
    {
        return lastR;
    }
    function getwinnerloser() constant returns(address[10])
    {
        return winnerloser;
    }
    function lastgamewinner() constant returns(address)
    {
        return lastgameendWinner;
    }
    
}