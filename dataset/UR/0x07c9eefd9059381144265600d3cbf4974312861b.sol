 
contract Hycon is ERC20, ERC20Detailed, ERC20Pausable, ERC20Burnable, ERC20Mintable, Ownable {

     
    constructor () public ERC20Detailed("Hycon", "HYC", 18) {
        _mint(msg.sender, 5000000000 * (10 ** uint256(decimals())));
    }
}