 
contract CorionXToken is StandardToken, Ownable  {

    string public name = 'CorionX utility token';
    string public symbol = 'CORX';
    uint8 public decimals = 8;
    uint public INITIAL_SUPPLY = 40000000000000000;

 
constructor() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
}

 
    function kill() onlyOwner public {
        selfdestruct(owner);
    }
}