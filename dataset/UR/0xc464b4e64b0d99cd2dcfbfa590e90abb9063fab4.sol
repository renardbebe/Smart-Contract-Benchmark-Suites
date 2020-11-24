 
    constructor () public ERC20Detailed("Stargame Token", "STRG", 8) {
        _mint(_msgSender(), 2100000000 * (10 ** uint256(decimals())));
    }
}
