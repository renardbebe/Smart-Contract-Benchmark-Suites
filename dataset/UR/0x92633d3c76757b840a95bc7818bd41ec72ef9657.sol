 
    constructor () public ERC20Detailed("Univerge Investor Group", "UIG", DECIMALS) {
        _mint(msg.sender, INIT_SUPPLY);
    }
}