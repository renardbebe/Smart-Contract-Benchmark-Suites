 
contract LOAPROTOCOL is ERC20, ERC20Detailed,ERC20Burnable {


    constructor () public ERC20Detailed("LOAPROTOCOL", "LOA", 18) {
        _mint(msg.sender, 2000000000 * (10 ** uint256(decimals())));
    }
}
