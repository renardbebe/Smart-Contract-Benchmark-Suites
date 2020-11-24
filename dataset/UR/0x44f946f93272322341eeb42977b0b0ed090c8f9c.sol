 
contract ULMC is ERC20, ERC20Detailed {

     
    constructor () public ERC20Detailed("UltraLink Machine System Ecological Rights Token", "ULMC", 18) {
        _mint(msg.sender, 10000000000 * (10 ** uint256(decimals())));
    }
}