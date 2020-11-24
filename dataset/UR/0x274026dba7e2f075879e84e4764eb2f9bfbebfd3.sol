 
contract SimpleToken is ERC20, ERC20Detailed {

     
    constructor () public ERC20Detailed("UltraLink Machine System", "ULMT", 18) {
        _mint(msg.sender, 1000000000 * (10 ** uint256(decimals())));
    }
}

