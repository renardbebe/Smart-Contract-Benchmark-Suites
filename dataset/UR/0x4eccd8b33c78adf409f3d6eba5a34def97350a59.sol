 
contract EFC is ERC20, ERC20Detailed {
    uint8 public constant DECIMALS = 9;
    uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(DECIMALS));

     
    constructor () public ERC20Detailed("EFFICA", "EFC", DECIMALS) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}
