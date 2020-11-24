 
contract OkheeToken is Context, ERC20, ERC20Detailed, ERC20Burnable {

     
     
    
    constructor () public ERC20Detailed("OKToken", "OKT", 18) {
        _mint(_msgSender(), 50000000000 * (10 ** uint256(decimals())));
    }
}