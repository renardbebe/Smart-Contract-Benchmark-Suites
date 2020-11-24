 
contract SimpleToken is ERC20, ERC20Detailed, ERC20Burnable {

     
    constructor () public ERC20Detailed("TouchCon", "TOC", 18) {
        _mint(msg.sender, 250000000 * (10 ** uint256(decimals())));
    }
}