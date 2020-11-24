 
    constructor () public ERC20Detailed("RAYA", "RAYA", DECIMALS) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
    
}