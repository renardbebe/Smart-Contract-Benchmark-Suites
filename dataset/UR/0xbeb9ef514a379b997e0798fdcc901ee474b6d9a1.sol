 

pragma solidity ^0.4.8;

 
 
 
contract Assertive {

  function assert(bool assertion) internal {
      if (!assertion) throw;
  }

}

 
 
 
contract SafeMath is Assertive{

    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

}

 
 
 
contract ERC20Protocol {

    function totalSupply() constant returns (uint256 totalSupply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

 
 
 
 
contract ERC20 is ERC20Protocol {

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;

}


 
 
contract MelonToken is ERC20, SafeMath {

     

     
    string public constant name = "Melon Token";
    string public constant symbol = "MLN";
    uint public constant decimals = 18;
    uint public constant THAWING_DURATION = 2 years;  
    uint public constant MAX_TOTAL_TOKEN_AMOUNT_OFFERED_TO_PUBLIC = 1000000 * 10 ** decimals;  
    uint public constant MAX_TOTAL_TOKEN_AMOUNT = 1250000 * 10 ** decimals;  

     
    address public minter;  
    address public melonport;  
    uint public startTime;  
    uint public endTime;  

     
    mapping (address => uint) lockedBalances;

     

    modifier only_minter {
        assert(msg.sender == minter);
        _;
    }

    modifier only_melonport {
        assert(msg.sender == melonport);
        _;
    }

    modifier is_later_than(uint x) {
        assert(now > x);
        _;
    }

    modifier max_total_token_amount_not_reached(uint amount) {
        assert(safeAdd(totalSupply, amount) <= MAX_TOTAL_TOKEN_AMOUNT);
        _;
    }

     

    function lockedBalanceOf(address _owner) constant returns (uint balance) {
        return lockedBalances[_owner];
    }

     

     
     
    function MelonToken(address setMinter, address setMelonport, uint setStartTime, uint setEndTime) {
        minter = setMinter;
        melonport = setMelonport;
        startTime = setStartTime;
        endTime = setEndTime;
    }

     
     
    function mintLiquidToken(address recipient, uint amount)
        external
        only_minter
        max_total_token_amount_not_reached(amount)
    {
        balances[recipient] = safeAdd(balances[recipient], amount);
        totalSupply = safeAdd(totalSupply, amount);
    }

     
     
    function mintIcedToken(address recipient, uint amount)
        external
        only_minter
        max_total_token_amount_not_reached(amount)
    {
        lockedBalances[recipient] = safeAdd(lockedBalances[recipient], amount);
        totalSupply = safeAdd(totalSupply, amount);
    }

     
     
    function unlockBalance(address recipient)
        is_later_than(endTime + THAWING_DURATION)
    {
        balances[recipient] = safeAdd(balances[recipient], lockedBalances[recipient]);
        lockedBalances[recipient] = 0;
    }

     
     
     
    function transfer(address recipient, uint amount)
        is_later_than(endTime)
        returns (bool success)
    {
        return super.transfer(recipient, amount);
    }

     
     
     
    function transferFrom(address sender, address recipient, uint amount)
        is_later_than(endTime)
        returns (bool success)
    {
        return super.transferFrom(sender, recipient, amount);
    }

     
     
     
    function changeMintingAddress(address newAddress) only_melonport { minter = newAddress; }

     
     
    function changeMelonportAddress(address newAddress) only_melonport { melonport = newAddress; }
}


 
 
 
 
contract Contribution is SafeMath {

     

     
    uint public constant ETHER_CAP = 227000 ether;  
    uint public constant MAX_CONTRIBUTION_DURATION = 4 weeks;  
    uint public constant BTCS_ETHER_CAP = ETHER_CAP * 25 / 100;  
     
    uint public constant PRICE_RATE_FIRST = 2200;  
    uint public constant PRICE_RATE_SECOND = 2150;
    uint public constant PRICE_RATE_THIRD = 2100;
    uint public constant PRICE_RATE_FOURTH = 2050;
    uint public constant DIVISOR_PRICE = 1000;  
     
    address public constant FOUNDER_ONE = 0x009beAE06B0c0C536ad1eA43D6f61DCCf0748B1f;
    address public constant FOUNDER_TWO = 0xB1EFca62C555b49E67363B48aE5b8Af3C7E3e656;
    address public constant EXT_COMPANY_ONE = 0x00779e0e4c6083cfd26dE77B4dbc107A7EbB99d2;
    address public constant EXT_COMPANY_TWO = 0x1F06B976136e94704D328D4d23aae7259AaC12a2;
    address public constant EXT_COMPANY_THREE = 0xDD91615Ea8De94bC48231c4ae9488891F1648dc5;
    address public constant ADVISOR_ONE = 0x0001126FC94AE0be2B685b8dE434a99B2552AAc3;
    address public constant ADVISOR_TWO = 0x4f2AF8d2614190Cc80c6E9772B0C367db8D9753C;
    address public constant ADVISOR_THREE = 0x715a70a7c7d76acc8d5874862e381c1940c19cce;
    address public constant ADVISOR_FOUR = 0x8615F13C12c24DFdca0ba32511E2861BE02b93b2;
    address public constant AMBASSADOR_ONE = 0xd3841FB80CE408ca7d0b41D72aA91CA74652AF47;
    address public constant AMBASSADOR_TWO = 0xDb775577538018a689E4Ad2e8eb5a7Ae7c34722B;
    address public constant AMBASSADOR_THREE = 0xaa967e0ce6A1Ff5F9c124D15AD0412F137C99767;
    address public constant AMBASSADOR_FOUR = 0x910B41a6568a645437bC286A5C733f3c501d8c88;
    address public constant AMBASSADOR_FIVE = 0xb1d16BFE840E66E3c81785551832aAACB4cf69f3;
    address public constant AMBASSADOR_SIX = 0x5F6ff16364BfEf546270325695B6e90cc89C497a;
    address public constant AMBASSADOR_SEVEN = 0x58656e8872B0d266c2acCD276cD23F4C0B5fEfb9;
    address public constant SPECIALIST_ONE = 0x8a815e818E617d1f93BE7477D179258aC2d25310;
    address public constant SPECIALIST_TWO = 0x1eba6702ba21cfc1f6c87c726364b60a5e444901;
    address public constant SPECIALIST_THREE = 0x82eae6c30ed9606e2b389ae65395648748c6a17f;
     
    uint public constant MELONPORT_COMPANY_STAKE = 1000;  
    uint public constant FOUNDER_STAKE = 445;  
    uint public constant EXT_COMPANY_STAKE_ONE = 150;  
    uint public constant EXT_COMPANY_STAKE_TWO = 100;  
    uint public constant EXT_COMPANY_STAKE_THREE = 50;  
    uint public constant ADVISOR_STAKE_ONE = 150;  
    uint public constant ADVISOR_STAKE_TWO = 50;  
    uint public constant ADVISOR_STAKE_THREE = 25;  
    uint public constant ADVISOR_STAKE_FOUR = 10;  
    uint public constant AMBASSADOR_STAKE = 5;  
    uint public constant SPECIALIST_STAKE_ONE = 25;  
    uint public constant SPECIALIST_STAKE_TWO = 10;  
    uint public constant SPECIALIST_STAKE_THREE = 5;  
    uint public constant DIVISOR_STAKE = 10000;  

     
    address public melonport;  
    address public btcs;  
    address public signer;  
    uint public startTime;  
    uint public endTime;  
    MelonToken public melonToken;  

     
    uint public etherRaised;  
    bool public halted;  

     

    event TokensBought(address indexed sender, uint eth, uint amount);

     

    modifier is_signer_signature(uint8 v, bytes32 r, bytes32 s) {
        bytes32 hash = sha256(msg.sender);
        assert(ecrecover(hash, v, r, s) == signer);
        _;
    }

    modifier only_melonport {
        assert(msg.sender == melonport);
        _;
    }

    modifier only_btcs {
        assert(msg.sender == btcs);
        _;
    }

    modifier is_not_halted {
        assert(!halted);
        _;
    }

    modifier ether_cap_not_reached {
        assert(safeAdd(etherRaised, msg.value) <= ETHER_CAP);
        _;
    }

    modifier btcs_ether_cap_not_reached {
        assert(safeAdd(etherRaised, msg.value) <= BTCS_ETHER_CAP);
        _;
    }

    modifier is_not_earlier_than(uint x) {
        assert(now >= x);
        _;
    }

    modifier is_earlier_than(uint x) {
        assert(now < x);
        _;
    }

     

     
     
    function priceRate() constant returns (uint) {
         
        if (startTime <= now && now < startTime + 1 weeks)
            return PRICE_RATE_FIRST;
        if (startTime + 1 weeks <= now && now < startTime + 2 weeks)
            return PRICE_RATE_SECOND;
        if (startTime + 2 weeks <= now && now < startTime + 3 weeks)
            return PRICE_RATE_THIRD;
        if (startTime + 3 weeks <= now && now < endTime)
            return PRICE_RATE_FOURTH;
         
        assert(false);
    }

     

     
     
    function Contribution(address setMelonport, address setBTCS, address setSigner, uint setStartTime) {
        melonport = setMelonport;
        btcs = setBTCS;
        signer = setSigner;
        startTime = setStartTime;
        endTime = startTime + MAX_CONTRIBUTION_DURATION;
        melonToken = new MelonToken(this, melonport, startTime, endTime);  
        var maxTotalTokenAmountOfferedToPublic = melonToken.MAX_TOTAL_TOKEN_AMOUNT_OFFERED_TO_PUBLIC();
        uint stakeMultiplier = maxTotalTokenAmountOfferedToPublic / DIVISOR_STAKE;
         
        melonToken.mintLiquidToken(melonport,       MELONPORT_COMPANY_STAKE * stakeMultiplier);
         
        melonToken.mintIcedToken(FOUNDER_ONE,       FOUNDER_STAKE *           stakeMultiplier);
        melonToken.mintIcedToken(FOUNDER_TWO,       FOUNDER_STAKE *           stakeMultiplier);
        melonToken.mintIcedToken(EXT_COMPANY_ONE,   EXT_COMPANY_STAKE_ONE *   stakeMultiplier);
        melonToken.mintIcedToken(EXT_COMPANY_TWO,   EXT_COMPANY_STAKE_TWO *   stakeMultiplier);
        melonToken.mintIcedToken(EXT_COMPANY_THREE, EXT_COMPANY_STAKE_THREE * stakeMultiplier);
        melonToken.mintIcedToken(ADVISOR_ONE,       ADVISOR_STAKE_ONE *       stakeMultiplier);
        melonToken.mintIcedToken(ADVISOR_TWO,       ADVISOR_STAKE_TWO *       stakeMultiplier);
        melonToken.mintIcedToken(ADVISOR_THREE,     ADVISOR_STAKE_THREE *     stakeMultiplier);
        melonToken.mintIcedToken(ADVISOR_FOUR,      ADVISOR_STAKE_FOUR *      stakeMultiplier);
        melonToken.mintIcedToken(AMBASSADOR_ONE,    AMBASSADOR_STAKE *        stakeMultiplier);
        melonToken.mintIcedToken(AMBASSADOR_TWO,    AMBASSADOR_STAKE *        stakeMultiplier);
        melonToken.mintIcedToken(AMBASSADOR_THREE,  AMBASSADOR_STAKE *        stakeMultiplier);
        melonToken.mintIcedToken(AMBASSADOR_FOUR,   AMBASSADOR_STAKE *        stakeMultiplier);
        melonToken.mintIcedToken(AMBASSADOR_FIVE,   AMBASSADOR_STAKE *        stakeMultiplier);
        melonToken.mintIcedToken(AMBASSADOR_SIX,    AMBASSADOR_STAKE *        stakeMultiplier);
        melonToken.mintIcedToken(AMBASSADOR_SEVEN,  AMBASSADOR_STAKE *        stakeMultiplier);
        melonToken.mintIcedToken(SPECIALIST_ONE,    SPECIALIST_STAKE_ONE *    stakeMultiplier);
        melonToken.mintIcedToken(SPECIALIST_TWO,    SPECIALIST_STAKE_TWO *    stakeMultiplier);
        melonToken.mintIcedToken(SPECIALIST_THREE,  SPECIALIST_STAKE_THREE *  stakeMultiplier);
    }

     
     
    function buy(uint8 v, bytes32 r, bytes32 s) payable { buyRecipient(msg.sender, v, r, s); }

     
     
    function buyRecipient(address recipient, uint8 v, bytes32 r, bytes32 s)
        payable
        is_signer_signature(v, r, s)
        is_not_earlier_than(startTime)
        is_earlier_than(endTime)
        is_not_halted
        ether_cap_not_reached
    {
        uint amount = safeMul(msg.value, priceRate()) / DIVISOR_PRICE;
        melonToken.mintLiquidToken(recipient, amount);
        etherRaised = safeAdd(etherRaised, msg.value);
        assert(melonport.send(msg.value));
        TokensBought(recipient, msg.value, amount);
    }

     
     
    function btcsBuyRecipient(address recipient)
        payable
        only_btcs
        is_earlier_than(startTime)
        is_not_halted
        btcs_ether_cap_not_reached
    {
        uint amount = safeMul(msg.value, PRICE_RATE_FIRST) / DIVISOR_PRICE;
        melonToken.mintLiquidToken(recipient, amount);
        etherRaised = safeAdd(etherRaised, msg.value);
        assert(melonport.send(msg.value));
        TokensBought(recipient, msg.value, amount);
    }

     
     
    function halt() only_melonport { halted = true; }

     
     
    function unhalt() only_melonport { halted = false; }

     
     
    function changeMelonportAddress(address newAddress) only_melonport { melonport = newAddress; }
}