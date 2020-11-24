 
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function sendEther(uint _value) public onlyOwner {
        msg.sender.transfer(_value);
    }

     
    function name() public pure returns (string memory) {
        return NAME;
    }
     
    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }
     
    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

}