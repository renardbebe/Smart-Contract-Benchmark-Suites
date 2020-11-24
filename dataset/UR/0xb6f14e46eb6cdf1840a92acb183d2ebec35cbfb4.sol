 
contract BraceToken is Context, ERC20, ERC20Detailed, ERC20Mintable, ERC20Pausable, ERC20Burnable {

     
    constructor () public ERC20Detailed("BRACE", "BRACE", 8) {
        _mint(_msgSender(), 0 * (10 ** uint256(decimals())));
    }
}