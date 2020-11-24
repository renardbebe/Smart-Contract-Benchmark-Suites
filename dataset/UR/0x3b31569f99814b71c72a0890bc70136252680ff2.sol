 
contract SimpleToken is Context, ERC20, ERC20Detailed {

     
    constructor () public ERC20Detailed("SimpleToken", "RCSC", 18) {
        _mint(_msgSender(), 100000000000 * (10 ** uint256(decimals())));
    }
}