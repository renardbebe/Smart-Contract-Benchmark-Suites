 

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
        } else { 
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { 
            return false;
        }
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

 
contract FolioNinjaToken is ERC20, SafeMath {
     
    string public constant name = "folio.ninja";
    string public constant symbol = "FLN";
    uint public constant decimals = 18;
    uint public constant MAX_TOTAL_TOKEN_AMOUNT = 12632000 * 10 ** decimals;

     
    address public minter;  
    address public FOUNDATION_WALLET;  
    uint public startTime;  
    uint public endTime;  

     
    modifier only_minter {
        assert(msg.sender == minter);
        _;
    }

    modifier only_foundation {
        assert(msg.sender == FOUNDATION_WALLET);
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

     
    function FolioNinjaToken(address setMinter, address setFoundation, uint setStartTime, uint setEndTime) {
        minter = setMinter;
        FOUNDATION_WALLET = setFoundation;
        startTime = setStartTime;
        endTime = setEndTime;
    }

     
     
    function mintToken(address recipient, uint amount)
        external
        only_minter
        max_total_token_amount_not_reached(amount)
    {
        balances[recipient] = safeAdd(balances[recipient], amount);
        totalSupply = safeAdd(totalSupply, amount);
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

     
     
     
    function changeMintingAddress(address newMintingAddress) only_foundation { minter = newMintingAddress; }

     
     
    function changeFoundationAddress(address newFoundationAddress) only_foundation { FOUNDATION_WALLET = newFoundationAddress; }
}

 
contract Contribution is SafeMath {
     

     
    uint public constant ETHER_CAP = 25000 ether;  
    uint public constant MAX_CONTRIBUTION_DURATION = 8 weeks;  

     
    uint public constant PRICE_RATE_FIRST = 480;
    uint public constant PRICE_RATE_SECOND = 460;
    uint public constant PRICE_RATE_THIRD = 440;
    uint public constant PRICE_RATE_FOURTH = 400;

     
    uint public constant FOUNDATION_TOKENS = 632000 ether;

     
    address public FOUNDATION_WALLET;  
    address public DEV_WALLET;  

    uint public startTime;  
    uint public endTime;  

    FolioNinjaToken public folioToken;  

     
    uint public etherRaised;  
    bool public halted;  

     
    event TokensBought(address indexed sender, uint eth, uint amount);

     
    modifier only_foundation {
        assert(msg.sender == FOUNDATION_WALLET);
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

     
    function Contribution(address setDevWallet, address setFoundationWallet, uint setStartTime) {
        DEV_WALLET = setDevWallet;
        FOUNDATION_WALLET = setFoundationWallet;
        startTime = setStartTime;
        endTime = startTime + MAX_CONTRIBUTION_DURATION;
        folioToken = new FolioNinjaToken(this, FOUNDATION_WALLET, startTime, endTime);  

         
        folioToken.mintToken(FOUNDATION_WALLET, FOUNDATION_TOKENS);
    }

     
     
    function () payable { buyRecipient(msg.sender); }

     
     
    function buyRecipient(address recipient)
        payable
        is_not_earlier_than(startTime)
        is_earlier_than(endTime)
        is_not_halted
        ether_cap_not_reached
    {
        uint amount = safeMul(msg.value, priceRate());
        folioToken.mintToken(recipient, amount);
        etherRaised = safeAdd(etherRaised, msg.value);
        assert(DEV_WALLET.send(msg.value));
        TokensBought(recipient, msg.value, amount);
    }

     
     
    function halt() only_foundation { halted = true; }

     
     
    function unhalt() only_foundation { halted = false; }

     
     
    function changeFoundationAddress(address newFoundationAddress) only_foundation { FOUNDATION_WALLET = newFoundationAddress; }

     
     
    function changeDevAddress(address newDevAddress) only_foundation { DEV_WALLET = newDevAddress; }
}