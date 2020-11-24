 
contract Krypto is ERC20, ERC20Detailed, ERC20Mintable, ERC20Burnable, ERC20Pausable {

     

    constructor () public ERC20Detailed("Krypto Currency Token", "KPTX", 18) {
        _mint(msg.sender, 108000000 * (10 ** uint256(decimals())));
    }
}