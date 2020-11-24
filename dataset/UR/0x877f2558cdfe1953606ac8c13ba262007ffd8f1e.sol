 
contract OASChain is ERC20, ERC20Detailed {

     
    constructor () public ERC20Detailed("OAS Chain", "OAS", 18) {
        _mint(msg.sender, 6500000000 * (10 ** uint256(decimals())));
    }
}

