 
    constructor () public ERC20Detailed("HAMA token", "HAMA", DECIMALS) {
        
         
         
        owner = msg.sender;
         
    }
    
     
     
         
         
         
         
         
         
         
         
         
         
         
         
        
         
         
         
        
         
        
         
         
         
        
         
         
         
     

     
    function getTimeTimeLength() view public returns(uint256) {
        return timeMintList.length;
    }

     
    function getTimeTimeMint(uint index) view public returns(address, uint256, uint256) {
        return (timeMintList[index].beneficiary, timeMintList[index].releaseTime, timeMintList[index].value);
    }

     
    function insertTimeMintTimeTable(address _beneficiary, uint256 index, uint256 _value) onlyOwner canMint public returns (bool){
        require(_beneficiary != address(0));
        require(index >= 0 && index < TIME_TABLE.length, "insertTimeMint: index out of range");
        return insertTimeMint(_beneficiary, TIME_TABLE[index], _value);
    }
    
     
    function insertTimeMint(address _beneficiary, uint256 _releaseTime, uint256 _value) onlyOwner canMint public returns (bool){
        require(_beneficiary != address(0));
        require(_releaseTime > block.timestamp, "TokenTimelock: release time is before current time");
        TimeMint memory item = TimeMint({
            beneficiary: _beneficiary,
            releaseTime: _releaseTime,
            value: _value
        });
        timeMintList.push(item);
        return true;
    }
    
     
    function removeTimeMint(uint index) onlyOwner canMint public returns (bool){
        require(index >= 0 && index < timeMintList.length, "removeTimeMint: index out of range.");
        timeMintList[index] = timeMintList[timeMintList.length-1];
        delete timeMintList[timeMintList.length-1];
        timeMintList.length--;
        return true;
    }
    
  
    function releaseTimeMintToken() onlyOwner canMint public returns (bool) {
        require(timeMintList.length > 0);
        uint i = 0;
        while (i < timeMintList.length) {
            if (block.timestamp >= timeMintList[i].releaseTime) {            
                if (_mintForTime(timeMintList[i])) {                         
                    timeMintList[i] = timeMintList[timeMintList.length-1];   
                    delete timeMintList[timeMintList.length-1];
                    timeMintList.length--;
                    continue;    
                }
            }
            i++;     
        }
    }
    
    function _mintForTime(TimeMint memory item) onlyOwner canMint private returns (bool) {
        require(block.timestamp >= item.releaseTime, "TokenTimelock: current time is before release time");
        _mint(item.beneficiary, item.value);
         
        return true;
    }
    
     
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingAvail = false;
         
        return true;
    }

}