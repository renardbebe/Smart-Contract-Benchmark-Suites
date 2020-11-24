 
    constructor () public ERC20Detailed("LARISSA", "LRS", 18) {
        _mint(msg.sender, 10000000000 * (10 ** uint256(decimals())));
    }
}