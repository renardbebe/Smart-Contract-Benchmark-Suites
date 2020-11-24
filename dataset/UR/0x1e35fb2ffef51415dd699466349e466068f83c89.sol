 
contract SimpleToken is ERC20, ERC20Detailed, ERC20Burnable {

     
    constructor () public ERC20Detailed("GameConnecT", "GCT", 18) {
        _mint(msg.sender, 30000000000 * (10 ** uint256(decimals())));
    }
}
