 
    constructor () public ERC20Detailed("Gold n Art", "GNA", DECIMALS) {
        _mint(msg.sender, INIT_SUPPLY);
    }
}