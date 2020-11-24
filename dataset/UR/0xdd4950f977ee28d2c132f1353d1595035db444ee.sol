 

pragma solidity ^0.4.24;
 

interface JIincInterfaceForForwarder {
    function deposit(address _addr) external payable returns (bool);
    function migrationReceiver_setup() external returns (bool);
}

contract JIincForwarder {
    string public name = "JIincForwarder";
    JIincInterfaceForForwarder private currentCorpBank_;
    address private newCorpBank_;
    bool needsBank_ = true;
    
    constructor() 
        public
    {
         
    }
    
    function()
        public
        payable
    {
         
         
        currentCorpBank_.deposit.value(address(this).balance)(address(currentCorpBank_));
    }
    
    function deposit()
        public 
        payable
        returns(bool)
    {
        require(msg.value > 0, "Forwarder Deposit failed - zero deposits not allowed");
        require(needsBank_ == false, "Forwarder Deposit failed - no registered bank");
        if (currentCorpBank_.deposit.value(msg.value)(msg.sender) == true)
            return(true);
        else
            return(false);
    }
 
 
 
 
    function status()
        public
        view
        returns(address, address, bool)
    {
        return(address(currentCorpBank_), address(newCorpBank_), needsBank_);
    }

    function startMigration(address _newCorpBank)
        external
        returns(bool)
    {
         
        require(msg.sender == address(currentCorpBank_), "Forwarder startMigration failed - msg.sender must be current corp bank");
        
         
         
        if(JIincInterfaceForForwarder(_newCorpBank).migrationReceiver_setup() == true)
        {
             
            newCorpBank_ = _newCorpBank;
            return (true);
        } else 
            return (false);
    }
    
    function cancelMigration()
        external
        returns(bool)
    {
         
         
        require(msg.sender == address(currentCorpBank_), "Forwarder cancelMigration failed - msg.sender must be current corp bank");
        
         
        newCorpBank_ = address(0x0);
        
        return (true);
    }
    
    function finishMigration()
        external
        returns(bool)
    {
         
        require(msg.sender == newCorpBank_, "Forwarder finishMigration failed - msg.sender must be new corp bank");

         
        currentCorpBank_ = (JIincInterfaceForForwarder(newCorpBank_));
        
         
        newCorpBank_ = address(0x0);
        
        return (true);
    }
 
 
 
 
    function setup(address _firstCorpBank)
        external
    {
        require(needsBank_ == true, "Forwarder setup failed - corp bank already registered");
        currentCorpBank_ = JIincInterfaceForForwarder(_firstCorpBank);
        needsBank_ = false;
    }
}