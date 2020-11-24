 
contract HUMToken is MintableToken, BurnableToken, Blacklisted {

  string public constant name = "Humanscape";  
  string public constant symbol = "HUM";  
  uint8 public constant decimals = 18;  

  uint256 public constant INITIAL_SUPPLY = 1250 * 1000 * 1000 * (10 ** uint256(decimals));  

  bool public isUnlocked = false;
  
   
  constructor(address _wallet) public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[_wallet] = INITIAL_SUPPLY;
    emit Transfer(address(0), _wallet, INITIAL_SUPPLY);
  }

  modifier onlyTransferable() {
    require(isUnlocked || owners[msg.sender] != 0);
    _;
  }

  function transferFrom(address _from, address _to, uint256 _value) public onlyTransferable notBlacklisted returns (bool) {
      return super.transferFrom(_from, _to, _value);
  }

  function transfer(address _to, uint256 _value) public onlyTransferable notBlacklisted returns (bool) {
      return super.transfer(_to, _value);
  }
  
  function unlockTransfer() public onlyOwner {
      isUnlocked = true;
  }
  
  function lockTransfer() public onlyOwner {
      isUnlocked = false;
  }

}
