 
contract SimpleToken is ERC20, ERC20Detailed, ERC20Burnable{
    uint8 public constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 10000000000 * (10 ** uint256(DECIMALS));

     
    constructor () public ERC20Detailed("ITTONION", "ITT", DECIMALS) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}