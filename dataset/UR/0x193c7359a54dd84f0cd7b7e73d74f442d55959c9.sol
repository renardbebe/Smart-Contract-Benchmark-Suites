 
    function transfer(address _to, uint256 _value) public kycVerified(msg.sender) frozenVerified(msg.sender) lockingVerified(msg.sender)  returns (bool) {
        _transfer(msg.sender,_to,_value);
        return true;
    }
    
     
    function multiTransfer(address[] _to,uint[] _value) public kycVerified(msg.sender) frozenVerified(msg.sender) lockingVerified(msg.sender) returns (bool) {
        require(_to.length == _value.length, "Length of Destination should be equal to value");
        for(uint _interator = 0;_interator < _to.length; _interator++ )
        {
            _transfer(msg.sender,_to[_interator],_value[_interator]);
        }
        return true;    
    }
    
     
    function lockUserAddress() public returns(bool){
        lockingEnabled[msg.sender] = true;
        emit LockFunds(msg.sender, true);
    }
    
     
    function unlockUserAddress() public returns(bool){
        lockingEnabled[msg.sender] = false;
        emit LockFunds(msg.sender, false);
    }
}
