 

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
contract VibeCoin {
    function transferFrom(address _from, address _to, uint256 _value)
    returns (bool success)
    {}
}


contract VIBEXToken is StandardToken {

     
    string public constant name = "VIBEX Exchange Token";
    string public constant symbol = "VIBEX";
    uint256 public constant decimals = 18;

     
    address public ethFundDeposit = 0xFC1CCdcA6b4670516504409341A31e444FF6f43F;
    address public tokenExchangeAddress = 0xe8ff5c9c75deb346acac493c463c8950be03dfba;
    address public tokenAccountAddress = 0xFC1CCdcA6b4670516504409341A31e444FF6f43F;
     
    VibeCoin public tokenExchange;

     
    enum ContractState { Fundraising, Finalized, Redeeming, Paused }
    ContractState public state;            
    ContractState private savedState;      

     
    uint public startDate = 1502064000;
     
    uint public endDate = 1506038399;
     
     
     
     
     
    uint[5] public deadlines = [1503359999, 1503964799, 1504655999, 1505260799, 1506038399];
	uint[5] public prices = [130, 120, 110, 105, 100];
    
    uint256 public constant ETH_RECEIVED_CAP = 115 * (10**3) * 10**decimals;  
    uint256 public constant ETH_RECEIVED_MIN = 0; 
    uint256 public constant TOKEN_MIN = 1 * 10**decimals;  
    uint256 public constant MIN_ETH_TRANS = 25 * 10**decimals;  

     
    uint256 public totalReceivedEth = 0;

     
     
    mapping (address => uint256) private ethBalances;

     
    event LogCreateVIBEX(address indexed _to, uint256 _value);
    event LogRedeemVIBE(address indexed _to, uint256 _value, uint256 _value2, uint256 _value3);

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

     
    function VIBEXToken()
    {
         
        state = ContractState.Fundraising;
        savedState = ContractState.Fundraising;
        tokenExchange = VibeCoin(tokenExchangeAddress);
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
        
        if(msg.value < MIN_ETH_TRANS && now < deadlines[0]) throw;

         
         
        uint256 checkedReceivedEth = safeAdd(totalReceivedEth, msg.value);
        require(checkedReceivedEth <= ETH_RECEIVED_CAP);

         
         
        uint256 tokens = safeMult(msg.value, getCurrentTokenPrice());
        require(tokens >= TOKEN_MIN);

         
         
        ethBalances[msg.sender] = safeAdd(ethBalances[msg.sender], msg.value);
        totalReceivedEth = checkedReceivedEth;
        totalSupply = safeAdd(totalSupply, tokens);
        balances[msg.sender] += tokens;   
        
         
        ethFundDeposit.transfer(msg.value);

         
        LogCreateVIBEX(msg.sender, tokens);
    }


     
    function getCurrentTokenPrice()
    private
    constant
    returns (uint256 currentPrice)
    {
        for(var i = 0; i < deadlines.length; i++)
            if(now<=deadlines[i])
                return prices[i];
        return prices[prices.length-1]; 
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
        if(!tokenExchange.transferFrom(tokenAccountAddress, msg.sender, numTokens)) throw;

         
        LogRedeemVIBE(msg.sender, numTokens, vibeVal, exchangeRate);
    }




     
    function finalize()
    external
    isFundraising
    minimumReached
    onlyOwner  
    {
        require(now > endDate || totalReceivedEth >= ETH_RECEIVED_CAP);  

         
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