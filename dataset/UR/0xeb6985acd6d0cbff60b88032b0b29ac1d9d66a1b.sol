 
    constructor(address tokensOwner) public ERC20Detailed("Bitbook Gambling", "BXK", 18) {
        _mint(tokensOwner, 750 * 10 ** 6 * (10 ** uint256(decimals())));   
    }
}


