 
contract ASTOSCH is ERC20, ERC20Detailed, ERC20Pausable, ERC20Burnable, ERC20Mintable, Ownable {

     
    constructor () public ERC20Detailed("ASTOSCH", "ASC", 8) {
        _mint(msg.sender, 50000000 * (10 ** uint256(decimals())));
    }
}