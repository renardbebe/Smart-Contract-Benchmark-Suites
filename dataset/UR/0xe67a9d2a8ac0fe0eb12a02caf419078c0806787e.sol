 
contract SimpleToken is Context, ERC20, ERC20Detailed {

     
    constructor () public ERC20Detailed("HIPAY", "HI", 18) {
        _mint(_msgSender(), 1000000000 * (10 ** uint256(decimals())));
    }
}
