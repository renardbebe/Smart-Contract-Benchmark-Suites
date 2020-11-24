 
contract Drops is ERC20_Token {                                                      
     
    string constant TOKEN_NAME = "Drops";                                            
    string constant TOKEN_SYMBOL = "DRP";                                            
    uint8  constant TOKEN_DECIMALS = 8;                                              

     
     
     
    constructor(uint256 initialMint_) public {
        name = TOKEN_NAME;                                                           
        symbol = TOKEN_SYMBOL;                                                       
        decimals = TOKEN_DECIMALS;                                                   
        coinOwner = msg.sender;                                                      
        coinSupply = initialMint_.toklets(TOKEN_DECIMALS);                           
        balances[msg.sender] = coinSupply;                                           
    }
}