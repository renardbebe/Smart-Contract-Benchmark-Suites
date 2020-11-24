 
contract FoblToken is ERC20, ERC20Detailed, ERC20Pausable, ERC20Burnable, ERC20Mintable, Ownable {

     
    constructor () public ERC20Detailed("FoblToken", "FOBL", 8) {
        _mint(msg.sender, 10000000000 * (10 ** uint256(decimals())));
    }
}