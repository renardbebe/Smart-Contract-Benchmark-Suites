 
    constructor () public ERC20Detailed("Xenoverse", "XENO", DECIMALS) {
        _mint(msg.sender, INIT_SUPPLY);
    }
}