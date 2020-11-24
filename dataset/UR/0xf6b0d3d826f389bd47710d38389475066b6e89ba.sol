 
    constructor () public ERC20Detailed("TRIGO", "TRG", 7) {
        _mint(_msgSender(), 500000000 * (10 ** uint256(decimals())));
    }
}