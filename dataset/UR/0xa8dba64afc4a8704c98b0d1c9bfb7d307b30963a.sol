 
contract ShopereumToken is BurnableToken {

  string public name = "Shopereum Token V1.0";
  string public symbol = "xShop";
  uint8 public decimals = 18;

  constructor() public {
    _mint(msg.sender, 600 *1000 * 1000 * (10 ** 18) );
  }
}