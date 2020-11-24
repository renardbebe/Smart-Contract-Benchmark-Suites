 

 
 
 
 
 
 

pragma solidity ^0.4.19;

contract Ownable
{
    address public owner;
    
    modifier onlyOwner
    {
        require(msg.sender == owner);
        _;
    }
    
    function Ownable() public
    {
        owner = msg.sender;
    }
}

 
contract EtheremonData
{
    function getMonsterObj(uint64 _objId) constant public returns(uint64 objId, uint32 classId, address trainer, uint32 exp, uint32 createIndex, uint32 lastClaimIndex, uint createTime);
}

 
contract EtheremonTrade
{
    function freeTransferItem(uint64 _objId, address _receiver) external;
}

 
 
 
 
 
 
contract EtheremonDepositContract is Ownable
{
    function sendMon(address tradeAddress, address receiver, uint64 mon) external onlyOwner  
    {
        EtheremonTrade(tradeAddress).freeTransferItem(mon, receiver);
    }
}

 
 
 
 
 
 
 
 
contract EtheremonSwap is Ownable
{
    address public dataAddress = 0xabc1c404424bdf24c19a5cc5ef8f47781d18eb3e;
    address public tradeAddress = 0x4ba72f0f8dad13709ee28a992869e79d0fe47030;
    
    mapping(address => address) public depositAddress;
    mapping(uint64 => address) public monToTrainer;  
    mapping(uint64 => uint64) public listedMonForMon;
    mapping(uint64 => uint32) public listedMonForClass;
    
     
    function changeOwner(address newOwner) onlyOwner external
    {
        owner = newOwner;
    }
    
    function setTradeAddress(address _tradeAddress) onlyOwner external
    {
        tradeAddress = _tradeAddress;
    }
    
     
    function generateDepositAddress() external
    {
        require(depositAddress[msg.sender] == 0);  
        depositAddress[msg.sender] = new EtheremonDepositContract();
    }
    
     
    function withdrawMon(uint64 mon) external
    {
         
        require(depositAddress[msg.sender] != 0);
         
        delist(mon);
         
        EtheremonDepositContract(depositAddress[msg.sender]).sendMon(tradeAddress, msg.sender, mon);
    }
    
     
     
    function emergencyWithdraw(address _tradeAddress, uint64 mon) external
    {
         
        require(depositAddress[msg.sender] != 0);
        delist(mon);
        EtheremonDepositContract(depositAddress[msg.sender]).sendMon(_tradeAddress, msg.sender, mon);
    }
    
     
     
     
    function postMonForMon(uint64 yourMon, uint64 desiredMon) external
    {
         
        checkOwnership(yourMon);
         
        require(desiredMon != 0);
        
        listedMonForMon[yourMon] = desiredMon;
        
        monToTrainer[yourMon] = msg.sender;
    }
    
     
     
     
     
     
    function postMonForClass(uint64 yourMon, uint32 desiredClass) external
    {
         
        checkOwnership(yourMon);
         
        require(desiredClass != 0);
        
        listedMonForClass[yourMon] = desiredClass;
        
        monToTrainer[yourMon] = msg.sender;
    }
    
     
     
     
    function delistMon(uint64 mon) external
    {
         
        require(monToTrainer[mon] == msg.sender);
        delist(mon);
    }
    
     
    function trade(uint64 yourMon, uint64 desiredMon) external
    {
         
         
        
         
        checkOwnership(yourMon);
        
         
        if(listedMonForMon[desiredMon] != yourMon)
        {
             
            uint32 class;
            (,class,,,,,) = EtheremonData(dataAddress).getMonsterObj(yourMon);
            require(listedMonForClass[desiredMon] == class);
        }
        
         
        executeTrade(msg.sender, yourMon, monToTrainer[desiredMon], desiredMon);
        
         
        delist(yourMon);
        delist(desiredMon);
    }
    
     
    function checkOwnership(uint64 mon) private view
    {
        require(depositAddress[msg.sender] != 0);  
        
        address trainer;
        (,,trainer,,,,) = EtheremonData(dataAddress).getMonsterObj(mon);
        require(trainer == depositAddress[msg.sender]);
    }
    
     
     
    function executeTrade(address trainerA, uint64 monA, address trainerB, uint64 monB) private
    {
        EtheremonDepositContract(depositAddress[trainerA]).sendMon(tradeAddress, trainerB, monA);  
        EtheremonDepositContract(depositAddress[trainerB]).sendMon(tradeAddress, trainerA, monB);  
    }
    
     
    function delist(uint64 mon) private
    {
        if(listedMonForMon  [mon] != 0){listedMonForMon  [mon] = 0;}
        if(listedMonForClass[mon] != 0){listedMonForClass[mon] = 0;}
        if(monToTrainer     [mon] != 0){monToTrainer     [mon] = 0;}
    }
}