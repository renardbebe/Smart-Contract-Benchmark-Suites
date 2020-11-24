 

pragma solidity 0.4.15;

 
contract ERC20Token {
    

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);

     
    function totalSupply() constant returns (uint256 totalSupply);

     
    function balanceOf(address owner) constant returns (uint256 balance);

     
    function transfer(address to, uint256 value) returns (bool success);

     
    function transferFrom(address from, address to, uint256 value) returns (bool success);

     
    function approve(address spender, uint256 value) returns (bool success);

     
    function allowance(address owner, address spender) constant returns (uint256 remaining);
}



 
 contract TokenHolder {
    
    
    

    uint256 constant MIN_TOKENS_TO_HOLD = 1000;

     
    struct TokenDeposit {
        uint256 tokens;
        uint256 releaseTime;
    }

     
    event Deposited(address indexed depositor, address indexed beneficiar, uint256 tokens, uint256 releaseTime);

     
    event Claimed(address indexed beneficiar, uint256 tokens);

     
    mapping(address => TokenDeposit[]) deposits;

     
    ERC20Token public tokenContract;

     
    function TokenHolder (address _tokenContract)   {  
        tokenContract = ERC20Token(_tokenContract);
    }

     
    function depositTokens (uint256 tokenCount, address tokenBeneficiar, uint256 depositTime)   {  
        require(tokenCount >= MIN_TOKENS_TO_HOLD);
        require(tokenContract.allowance(msg.sender, address(this)) >= tokenCount);

        if(tokenContract.transferFrom(msg.sender, address(this), tokenCount)) {
            deposits[tokenBeneficiar].push(TokenDeposit(tokenCount, now + depositTime));
            Deposited(msg.sender, tokenBeneficiar, tokenCount, now + depositTime);
        }
    }

     
    function getDepositCount (address beneficiar)   constant   returns (uint count) {  
        return deposits[beneficiar].length;
    }

     
    function getDeposit (address beneficiar, uint idx)   constant   returns (uint256 deposit_dot_tokens, uint256 deposit_dot_releaseTime) {  
TokenDeposit memory deposit;

        require(idx < deposits[beneficiar].length);
        deposit = deposits[beneficiar][idx];
    deposit_dot_tokens = uint256(deposit.tokens);
deposit_dot_releaseTime = uint256(deposit.releaseTime);}

     
    function claimAllTokens ()   {  
        uint256 toPay = 0;

        TokenDeposit[] storage myDeposits = deposits[msg.sender];

        uint idx = 0;
        while(true) {
            if(idx >= myDeposits.length) { break; }
            if(now > myDeposits[idx].releaseTime) {
                toPay += myDeposits[idx].tokens;
                myDeposits[idx] = myDeposits[myDeposits.length - 1];
                myDeposits.length--;
            } else {
                idx++;
            }
        }

        if(toPay > 0) {
            tokenContract.transfer(msg.sender, toPay);
            Claimed(msg.sender, toPay);
        }
    }
}