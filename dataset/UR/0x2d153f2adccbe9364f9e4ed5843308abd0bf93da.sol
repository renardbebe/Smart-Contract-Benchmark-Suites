 
    constructor () public ERC20Detailed("IdealCoin", "IDEAL", DECIMALS) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}