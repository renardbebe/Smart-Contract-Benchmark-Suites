 
contract FKLToken is ERC20, ERC20Detailed {

    uint8 public constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 1000000 * (10 ** uint256(DECIMALS));

     
    constructor () public ERC20Detailed("Konstantin Lagutin Fund", "FKL", DECIMALS) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}