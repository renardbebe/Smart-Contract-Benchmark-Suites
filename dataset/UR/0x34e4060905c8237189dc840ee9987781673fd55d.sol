 
    constructor(uint256 initialSupply)
    ERC20Detailed("GG Coin", "GGC", 18)
    public {
         
        _mint(msg.sender, initialSupply);
    }

     
    function transfer(address to, uint256 value)
    public
    returns (bool) {
    
        require(!paused() || isOwner(), "Must either be unpaused or invoked by owner");

         
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function bulkTransfer(address[] memory recipients, uint256[] memory values)
    public
    onlyOwner {
        
         
        require(recipients.length == values.length, "There must be exactly one value for each recipient");

         
        for(uint256 rxIndex = 0; rxIndex<recipients.length; rxIndex++) {

             
            _transfer(msg.sender, recipients[rxIndex], values[rxIndex]);
        }
    }

     
    function bulkTransferValue(address[] memory recipients, uint256 value)
    public
    onlyOwner {
        
         
        for(uint256 rxIndex = 0; rxIndex<recipients.length; rxIndex++) {

             
            _transfer(msg.sender, recipients[rxIndex], value);
        }
    }

   
     
    function removePauser(address pauser)
    public
    onlyOwner {
        
         
        _removePauser(pauser);
    }

     
    function acceptOwnership()
    public {

         
        if(isPauser(_owner))
            _removePauser(_owner);

         
        if(!isPauser(msg.sender))
            _addPauser(msg.sender);

         
        super.acceptOwnership();
    }
}