 
contract BIZA is ERC20, ERC20Detailed, ERC20Burnable {
  uint8 public constant DECIMALS = 8;
  uint256 public constant INITIAL_SUPPLY = 8800000000 * (10 ** uint256(DECIMALS));

   
  constructor() public ERC20Detailed("BIZ Auto", "BIZA", DECIMALS) {
    _mint(msg.sender, INITIAL_SUPPLY);
  }

}
