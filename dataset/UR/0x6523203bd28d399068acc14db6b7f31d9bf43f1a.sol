 
contract BalloonCoin is Context, ERC20, ERC20Detailed {
    uint8 public constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(DECIMALS));
     
    constructor () public ERC20Detailed("Balloon", "BALO", 18) {
        _mint(_msgSender(), INITIAL_SUPPLY);
    }
}
