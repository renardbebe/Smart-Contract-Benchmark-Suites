 
    constructor () public ERC20Detailed("PET MONDE COIN", "PMC", 18) {
        _mint(msg.sender, 3000000000 * (10 ** uint256(decimals())));
    }
}