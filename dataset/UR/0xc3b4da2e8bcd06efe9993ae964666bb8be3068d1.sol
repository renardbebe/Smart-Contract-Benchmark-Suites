 
    function burn(uint256 value) public whenNotPaused {
        require(!isLock(msg.sender));
        _burn(msg.sender, value);
    }
    
     
    function freeze(uint256 value) public whenNotPaused {
        require(!isLock(msg.sender));
        _freeze(value);
    }
    
         
    function unfreeze(uint256 value) public whenNotPaused {
        require(!isLock(msg.sender));
        _unfreeze(value);
    }
    
}