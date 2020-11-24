 
contract SimpleToken is Context, ERC20, ERC20Detailed, ERC20Burnable {
    uint8 dec = 18;
    uint256 val = 10000000000000000000000000000;
     
    constructor () public ERC20Detailed("dappcoin", "DAC", dec) {
        _mint(_msgSender(), val );
    }
}