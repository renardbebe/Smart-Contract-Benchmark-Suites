 
contract KeyboardToken is ERC20, ERC20Detailed  {

    uint8 public constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 2200000000 * (10 ** uint256(DECIMALS));
     
    constructor () public ERC20Detailed("REBIT AI Keyboard Token", "KEYT", 18) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}