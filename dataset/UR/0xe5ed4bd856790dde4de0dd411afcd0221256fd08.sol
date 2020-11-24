 

pragma solidity ^0.4.10;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract SkrillaTokenInterface {
    function transfer(address _to, uint256 _value) public returns (bool);

    function buyTokens() payable public;

    function getCurrentPrice(address _buyer) public constant returns (uint256);

    function tokenSaleBalanceOf(address _owner) public constant returns (uint256 balance);

    function withdraw() public returns (bool);
}

contract TokenSyndicate {
    
    SkrillaTokenInterface private tokenContract;
     
    address public tokenContractAddress;
    uint256 public tokenExchangeRate;
 
     
    uint256 public refundStart;
     
    bool public refundsEnabled;
    bool public tokensPurchased;
     
    bool public syndicateTokensWithdrawn;

     
    uint256 public totalPresale;
    address public owner;

    mapping(address => uint256) public presaleBalances;

    event LogInvest(address indexed _to,  uint256 presale);
    event LogRefund(address indexed _to, uint256 presale);
    event LogTokenPurchase(uint256 eth, uint256 tokens);
    event LogWithdrawTokens(address indexed _to, uint256 tokens);
    
    modifier onlyOwner() { 
        assert(msg.sender == owner);  _; 
    }

    modifier onlyWhenTokensNotPurchased() { 
        assert(!tokensPurchased);  _; 
    }
    modifier onlyWhenTokensPurchased() { 
        assert(tokensPurchased); _; 
    }
    modifier onlyWhenSyndicateTokensWithdrawn() {
        assert(syndicateTokensWithdrawn); _; 
    }
    modifier whenRefundIsPermitted() {
        require(now >= refundStart || refundsEnabled);
        _;
    }
    modifier onlyWhenRefundsNotEnabled() {
        require(!refundsEnabled);
        _;
    }
    function TokenSyndicate(address _tokenContractAddress,
                            address _owner,
                            uint256 _refundStart) {
        tokenContractAddress = _tokenContractAddress;
        owner = _owner;

        assert(tokenContractAddress != address(0));    
        assert(owner != address(0));    

        tokenContract = SkrillaTokenInterface(_tokenContractAddress);
        refundStart = _refundStart;

        totalPresale = 0;
        
        tokensPurchased = false;
        syndicateTokensWithdrawn = false;
        refundsEnabled = false;
    }

     
    function() external payable {
        invest();
    }
     
    function invest() payable public onlyWhenTokensNotPurchased {
        assert(msg.value > 0);

        presaleBalances[msg.sender] = SafeMath.add(presaleBalances[msg.sender], msg.value);
        totalPresale = SafeMath.add(totalPresale, msg.value);        
        LogInvest(msg.sender, msg.value);        
    }

     
    function balanceOf(address _purchaser) external constant returns (uint256 presaleBalance) {
        return presaleBalances[_purchaser];
    }

     
    function enableRefunds() external onlyWhenTokensNotPurchased onlyOwner {
        refundsEnabled = true;
    }
     
    function buyTokens() external onlyWhenRefundsNotEnabled onlyWhenTokensNotPurchased onlyOwner {
        require(this.balance >= totalPresale);

        tokenContract.buyTokens.value(this.balance)();
         
         
        tokenExchangeRate = tokenContract.getCurrentPrice(this);
        
        tokensPurchased = true;

        LogTokenPurchase(totalPresale, tokenContract.tokenSaleBalanceOf(this));
    }

     
    function withdrawSyndicateTokens() external onlyWhenTokensPurchased onlyOwner {
        assert(tokenContract.withdraw());
        syndicateTokensWithdrawn = true;
    }

     

    function withdrawTokens() external onlyWhenSyndicateTokensWithdrawn {
        uint256 tokens = SafeMath.div(SafeMath.mul(presaleBalances[msg.sender], tokenExchangeRate), 1 ether);
        assert(tokens > 0);

        totalPresale = SafeMath.sub(totalPresale, presaleBalances[msg.sender]);
        presaleBalances[msg.sender] = 0;

         
        assert(tokenContract.transfer( msg.sender, tokens));
        LogWithdrawTokens(msg.sender, tokens);
    }

     
    function refund() external whenRefundIsPermitted onlyWhenTokensNotPurchased {
        uint256 totalValue = presaleBalances[msg.sender];
        assert(totalValue > 0);

        presaleBalances[msg.sender] = 0;
        totalPresale = SafeMath.sub(totalPresale, totalValue);
        
        msg.sender.transfer(totalValue);
        LogRefund(msg.sender, totalValue);
    }
}