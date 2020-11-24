 
contract SmartRhino is ERC20, ERC20Detailed {

     
    constructor () public ERC20Detailed("SmartRhino", "RNO", 18) {
        _mint(msg.sender, 3000000000 * (10 ** uint256(decimals())));
    }
}

