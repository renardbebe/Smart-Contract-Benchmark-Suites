 
contract Public_Utility_Benefit is Context, ERC20, ERC20Detailed, ERC20Burnable {
     
    constructor () public ERC20Detailed("Public Utility Benefit", "PUB", 18) {
        _mint(_msgSender(), 1000000000 * (10 ** uint256(decimals())));
    }
}