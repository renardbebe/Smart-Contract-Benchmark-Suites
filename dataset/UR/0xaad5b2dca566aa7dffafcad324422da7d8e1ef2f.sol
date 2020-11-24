 
contract CALLIA is ERC20, ERC20Detailed {

     
    constructor () public ERC20Detailed("CALLIA", "CAL", 18) {
        _mint(msg.sender, 20000000000 * (10 ** uint256(decimals())));
    }
}