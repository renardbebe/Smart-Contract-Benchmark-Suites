 

pragma solidity 0.4.19;

contract carnitaAsada{
    address addressManager;  
    address  bitsoAddress;  
    carnita [] carnitas;  
    uint256 lastCarnita;  
    bool public halted = false;  
    uint256 currentPeople;  
    uint256 priceCarnita;  
    uint toPaycarnita;  
    
    struct carnita{
        uint256 maxPeople;  
        bool active;  
        uint256 raised;  
        uint256 min;  
        address[] participants;  
        
    }
    
    function carnitaAsada(address _manager, address _bitso) public{
        addressManager= _manager;
        bitsoAddress= _bitso;
        lastCarnita=0;
        priceCarnita= 0.015 ether;
        currentPeople= 8;
        toPaycarnita=0.012 ether;
        
         
        carnita memory temp;
        temp.maxPeople=currentPeople;
        temp.active=true;
        temp.raised=0;
        temp.min=priceCarnita;
        carnitas.push(temp);
       
    }
    
     
    modifier onlyManager() {
        require(msg.sender ==  addressManager);
        _;
    }
     
    modifier onContractRunning() {
        require( halted == false);
        _;
    }
     
    modifier onContractStopped() {
      require( halted == true);
        _;
    }

   
     
    function rand() internal constant returns (uint32 res){
        return uint32(block.number^now)%uint32(carnitas[lastCarnita].participants.length);
    }
    
     
    function recoverAllEth() onlyManager public {
        addressManager.transfer(this.balance);
    }
    
     

    function  halt() onlyManager  onContractRunning public{
         halted = true;
    }

    function  unhalt() onlyManager onContractStopped public {
        halted = false;
    }
    
     
    function newManager(address _newManager) onlyManager public{
        addressManager= _newManager;
    }
     
    function getManager() public constant returns (address _manager){
        return addressManager;
    }
     
    function newBitsoAddress(address _newAddress) onlyManager public{
        addressManager= _newAddress;
    }
     
    function getBitsoAddress() public constant returns (address _bitsoAddress){
        return bitsoAddress;
    }
     
    function getPrice() public constant returns(uint256 _price){
        return priceCarnita;
    }
    
    
    function setPrice(uint256 _newPriceCarnita) onlyManager public{
        priceCarnita=_newPriceCarnita;
        carnitas[lastCarnita].min=priceCarnita;
    }
    
     
    function getPaycarnita() public constant returns(uint256 _Paycarnita){
        return toPaycarnita;
    }
    
    
    function setPaycarnita(uint256 _newPaycarnita) onlyManager public{
        toPaycarnita=_newPaycarnita;
    }
    
     
    function getMaxParticipants() public constant returns(uint256 _max){
        return currentPeople;
    }
     
    function setMaxParticipants(uint256 _newMax) onlyManager public{
        currentPeople=_newMax;
        carnitas[lastCarnita].maxPeople=currentPeople;
    }
    
   
     
    function seeCurrentParticipants()public constant returns(uint256 _participants){
        return carnitas[lastCarnita].participants.length;
    }
     
    function addParticipant(address _buyer, uint256 _value) internal {
        require(_value == priceCarnita || _buyer== addressManager);
         
    function () onContractRunning payable  public {
                 addParticipant(msg.sender, msg.value);           
            }
    
    
    
    
    
    
}