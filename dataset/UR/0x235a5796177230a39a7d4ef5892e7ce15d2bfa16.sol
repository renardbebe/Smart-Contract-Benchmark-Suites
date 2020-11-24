 

pragma solidity ^0.4.13;
contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }
}

contract Token {
    uint256 public totalSupply;

    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract StandardToken is Token, SafeMath {

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }

    function transfer(address _to, uint256 _value)
    returns (bool success)
    {
        if (balances[msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] = safeSubtract(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value)
    returns (bool success)
    {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
            balances[_to] = safeAdd(balances[_to], _value);
            balances[_from] = safeSubtract(balances[_from], _value);
            allowed[_from][msg.sender] = safeSubtract(allowed[_from][msg.sender], _value);
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value)
    onlyPayloadSize(2)
    returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
    constant
    onlyPayloadSize(2)
    returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
}
contract PrivateCityTokens {
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
}


contract PCXToken is StandardToken {

     
	string public name = "PRIVATE CITY TOKENS EXCHANGE";
	string public symbol = "PCTX";
    uint256 public constant decimals = 18;

     
    address public ethFundDeposit = 0xFEfC687c084E6A77322519BEc3A9107640905445;
    address public tokenExchangeAddress = 0x0d2d64c2c4ba21d08252661c3ca159982579b640;
    address public tokenAccountAddress = 0xFEfC687c084E6A77322519BEc3A9107640905445;
     
    PrivateCityTokens public tokenExchange;

     
    enum ContractState { Fundraising, Finalized, Redeeming, Paused }
    ContractState public state;            
    ContractState private savedState;      

     
    uint public startDate = 1506521932;
     
    uint public endDate = 1506635111;
    
    uint256 public constant ETH_RECEIVED_MIN = 0; 
    uint256 public constant TOKEN_MIN = 1 * 10**decimals;  

     
    uint256 public totalReceivedEth = 0;

     
     
    mapping (address => uint256) private ethBalances;
	

    modifier isFinalized() {
        require(state == ContractState.Finalized);
        _;
    }

    modifier isFundraising() {
        require(state == ContractState.Fundraising);
        _;
    }

    modifier isRedeeming() {
        require(state == ContractState.Redeeming);
        _;
    }

    modifier isPaused() {
        require(state == ContractState.Paused);
        _;
    }

    modifier notPaused() {
        require(state != ContractState.Paused);
        _;
    }

    modifier isFundraisingIgnorePaused() {
        require(state == ContractState.Fundraising || (state == ContractState.Paused && savedState == ContractState.Fundraising));
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == ethFundDeposit);
        _;
    }

    modifier minimumReached() {
        require(totalReceivedEth >= ETH_RECEIVED_MIN);
        _;
    }

     
    function PCXToken()
    {
         
        state = ContractState.Fundraising;
        savedState = ContractState.Fundraising;
        tokenExchange = PrivateCityTokens(tokenExchangeAddress);
        totalSupply = 0;
    }

     
    function transfer(address _to, uint256 _value)
    isFinalized  
    onlyPayloadSize(2)
    returns (bool success)
    {
        return super.transfer(_to, _value);
    }


     
    function transferFrom(address _from, address _to, uint256 _value)
    isFinalized  
    onlyPayloadSize(3)
    returns (bool success)
    {
        return super.transferFrom(_from, _to, _value);
    }
    
     
    function ()
    payable
    external
    isFundraising
    {
        require(now >= startDate);
        require(now <= endDate);
        require(msg.value > 0);
        

         
         
        uint256 checkedReceivedEth = safeAdd(totalReceivedEth, msg.value);

         
         
        uint256 tokens = safeMult(msg.value, getCurrentTokenPrice());
        require(tokens >= TOKEN_MIN);

         
         
        ethBalances[msg.sender] = safeAdd(ethBalances[msg.sender], msg.value);
        totalReceivedEth = checkedReceivedEth;
        totalSupply = safeAdd(totalSupply, tokens);
        balances[msg.sender] += tokens;   
        
         
        ethFundDeposit.transfer(msg.value);

    }


     
    function getCurrentTokenPrice()
    private
    constant
    returns (uint256 currentPrice)
    {
        return 100; 
    }


     
    function redeemTokens()
    external
    isRedeeming
    {
        uint256 vibeVal = balances[msg.sender];
        require(vibeVal >= TOKEN_MIN);  

         
         
        balances[msg.sender]=0;
        
        uint256 exchangeRate = ((160200000* 10**decimals)/totalSupply);
        uint256 numTokens = safeMult(exchangeRate, vibeVal);  
        if(!tokenExchange.transferFrom(tokenAccountAddress, msg.sender, numTokens)) revert();

    }




     
    function finalize()
    external
    isFundraising
    minimumReached
    onlyOwner  
    {
         
        state = ContractState.Finalized;
        savedState = ContractState.Finalized;
    }


     
    function startRedeeming()
    external
    isFinalized  
    onlyOwner    
    {
         
        state = ContractState.Redeeming;
        savedState = ContractState.Redeeming;
    }


     
    function pause()
    external
    notPaused    
    onlyOwner    
    {
         
        savedState = state;
        state = ContractState.Paused;
    }


     
    function proceed()
    external
    isPaused
    onlyOwner    
    {
         
        state = savedState;
    }

}