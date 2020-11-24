 
    function burn(uint256 value) public onlyOwner{
        _burn(msg.sender, value);
    }
}