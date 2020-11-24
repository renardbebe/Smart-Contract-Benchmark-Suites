 
contract HarvestQCoin is ERC20, ERC20Detailed, ERC20Burnable {

     
    constructor () public ERC20Detailed("HarvestQCoin", "HVC", 18) {
        _mint(msg.sender, 3000000000 * (10 ** uint256(decimals())));
    }
}