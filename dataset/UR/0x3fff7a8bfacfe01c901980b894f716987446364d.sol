 

pragma solidity ^ 0.4.15;
 
contract GodzSwapGodzEtherCompliance{
     
    address public owner;
    
     
    struct GodzBuyAccounts
    {
        uint256 amount; 
        address account; 
        uint sendGodz; 
    }

     
    mapping(uint=>GodzBuyAccounts) public accountsHolding;
    
     
    uint public indexAccount = 0;

     
    address public swapContract; 


     
     
         
    function GodzSwapGodzEtherCompliance()
    {
         
        owner = msg.sender;
    }

     
     
         
    function setHolderInformation(address _swapContract)
    {    
         
        if (msg.sender==owner)
        {
             
            swapContract = _swapContract;
        }
    }

     
     
     
    function SaveAccountBuyingGodz(address account, uint256 amount) public returns (bool success) 
    {
         
        if (msg.sender==swapContract)
        {
             
            indexAccount += 1;
             
            accountsHolding[indexAccount].account = account;
            accountsHolding[indexAccount].amount = amount;
            accountsHolding[indexAccount].sendGodz = 0;
             
             
            return true;
        }
        else
        {
            return false;
        }
    }

     
     
     
    function setSendGodz(uint index) public 
    {
        if (owner == msg.sender)
        {
            accountsHolding[index].sendGodz = 1;
        }
    }

     
     
     
    function getAccountInformation(uint index) public returns (address account, uint256 amount, uint sendGodz)
    {
         
        return (accountsHolding[index].account, accountsHolding[index].amount, accountsHolding[index].sendGodz);
    }
}