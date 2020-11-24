 
contract MOJI is Context, ERC20, ERC20Detailed {

     
    constructor () public ERC20Detailed("MOJI", "MJ", 18) {
        _mint(_msgSender(), 10000000000 * (10 ** uint256(decimals())));
    }
}
