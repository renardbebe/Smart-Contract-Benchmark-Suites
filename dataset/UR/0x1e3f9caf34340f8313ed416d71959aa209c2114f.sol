 
contract GenieKRW is Context, ERC20, ERC20Detailed, ERC20Burnable {
     
    constructor () public ERC20Detailed("GenieKRW", "GKRW", 18) {
        _mint(_msgSender(), 10000000000 * (10 ** uint256(decimals())));
    }
}