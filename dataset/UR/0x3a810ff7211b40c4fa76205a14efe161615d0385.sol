 
contract MainToken is Consts
    , FreezableToken
    , TransferableToken
    , PausableToken
    , MintableToken
    , BurnableToken
    {
    string public constant name = TOKEN_NAME;  
    string public constant symbol = TOKEN_SYMBOL;  
    uint8 public constant decimals = TOKEN_DECIMALS;  

    uint256 public constant INITIAL_SUPPLY = TOKEN_AMOUNT * (10 ** uint256(decimals));

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
}
