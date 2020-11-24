 

pragma solidity ^0.4.18;



contract OsherCrowdsaleCore {
    
    function crowdsale( address _address )payable;
    function precrowdsale( address _address )payable;
}

contract OsherCrowdsale {
    
    address public owner;
    
    
   
    bool public crowdSaleStarted;
    bool public crowdSaleClosed;
    bool public  crowdSalePause;
    
    uint public crowdSaleStartTime;
    uint public preicostarted;
    
    uint public deadline;
    
    address public CoreAddress;
    OsherCrowdsaleCore  core;
    
    
    
    
    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }

    
    
    
    function OsherCrowdsale(){
        
        crowdSaleStarted = false;
        crowdSaleClosed = false;
        crowdSalePause = false;
        preicostarted = now;
        owner = msg.sender;
        
    }
    
     
    function () payable {
        
        require ( crowdSaleClosed == false && crowdSalePause == false  );
        
        if ( crowdSaleStarted ) { 
            require ( now < deadline );
            core.crowdsale.value( msg.value )( msg.sender); 
            
        } 
        else
        { core.precrowdsale.value( msg.value )( msg.sender); }
       
    }
    
    
   
     
    function startCrowdsale() onlyOwner  {
        
        crowdSaleStarted = true;
        crowdSaleStartTime = now;
        deadline = now + 60 days;
       
                
    }

     
    function endCrowdsale() onlyOwner  {
        
        
        crowdSaleClosed = true;
    }

     
    function pauseCrowdsale() onlyOwner {
        
        crowdSalePause = true;
        
        
    }

     
    function unpauseCrowdsale() onlyOwner {
        
        crowdSalePause = false;
        
        
    }
    
     
    function setCore( address _core ) onlyOwner {
        
        require ( _core != 0x00 );
        CoreAddress = _core;
        core = OsherCrowdsaleCore( _core );
        
    }
    
    function transferOwnership( address _address ) onlyOwner {
        
        require ( _address!= 0x00 );
        owner =  _address ;
        
    }
    
    
    
    
    
    
    
}