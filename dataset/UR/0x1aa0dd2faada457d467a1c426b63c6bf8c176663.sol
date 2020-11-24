 
contract SimpleToken is ERC20, ERC20Detailed , ERC20Burnable {

     
    constructor () public ERC20Detailed("TuneStarToken", "TST", 18) {
        _mint(_msgSender(), 1000000000 * (10 ** uint256(decimals())));
    }
}