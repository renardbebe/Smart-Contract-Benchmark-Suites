 
contract DemeToken is ERC20, ERC20Detailed {
    uint8 public constant DECIMALS = 4;
    uint256 public constant INITIAL_SUPPLY = 10000000000 * (10 ** uint256(DECIMALS));

     
    constructor (address owner) public ERC20Detailed("DemeToken", "DEMT", DECIMALS) {
        _mint(owner, INITIAL_SUPPLY);
    }
}
