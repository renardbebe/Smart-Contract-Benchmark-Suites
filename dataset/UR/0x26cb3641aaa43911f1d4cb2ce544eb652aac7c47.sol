 

pragma solidity ^0.4.19;
 
contract ERC20Basic
{
    uint256 public totalSupply;

    function balanceOf(address who) public constant returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic
{
    function allowance(address owner, address spender) public constant returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
 
contract Ownable
{
     
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public
    {
        owner = msg.sender;
    }

     
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public
    {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
 


 
library SafeMath
{
    function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}



 
contract SafeBasicToken is ERC20Basic
{
     
    using SafeMath for uint256;

     
    mapping(address => uint256) balances;

     
    mapping(address => bool) public admin;

     
    mapping(address => bool) public receivable;

     
    bool public locked;


     
    modifier onlyPayloadSize(uint size)
    {
        assert(msg.data.length >= size + 4);
        _;
    }

     
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool)
    {
        require(_to != address(0));
        require(!locked || admin[msg.sender] == true || receivable[_to] == true);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }


     
    function balanceOf(address _owner) public constant returns (uint256)
    {
        return balances[_owner];
    }
}


 
contract SafeStandardToken is ERC20, SafeBasicToken
{
     
    mapping(address => mapping(address => uint256)) allowed;


     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }


     
    function approve(address _spender, uint256 _value) public returns (bool)
    {
        require(_value == 0 || allowed[msg.sender][_spender] == 0);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success)
    {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success)
    {
        uint oldValue = allowed[msg.sender][_spender];

        if (_subtractedValue > oldValue)
            allowed[msg.sender][_spender] = 0;
        else
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool)
    {
        require(_to != address(0));
        uint256 _allowance = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
}



 
contract CrystalToken is SafeStandardToken, Ownable
{
    using SafeMath for uint256;

    string public constant name = "CrystalToken";
    string public constant symbol = "CYL";
    uint256 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 28000000 * (10 ** uint256(decimals));

     
    struct Round
    {
        uint256 startTime;                       
        uint256 endTime;                         
        uint256 availableTokens;                 
        uint256 maxPerUser;                      
        uint256 rate;                            
        mapping(address => uint256) balances;    
    }

     
    Round[5] rounds;

     
    address public wallet;

     
    uint256 public weiRaised;

     
    uint256 public runningRound;

     
    function CrystalToken(address _walletAddress) public
    {
        wallet = _walletAddress;
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;

        rounds[0] = Round(1519052400, 1519138800,  250000 * (10 ** 18), 200 * (10 ** 18), 2000);     
        rounds[1] = Round(1519398000, 1519484400, 1250000 * (10 ** 18), 400 * (10 ** 18), 1333);     
        rounds[2] = Round(1519657200, 1519743600, 1500000 * (10 ** 18), 1000 * (10 ** 18), 1000);    
        rounds[3] = Round(1519830000, 1519916400, 2000000 * (10 ** 18), 1000 * (10 ** 18), 800);     
        rounds[4] = Round(1520262000, 1520348400, 2000000 * (10 ** 18), 2000 * (10 ** 18), 667);     

         
        admin[msg.sender] = true;

         
        locked = true;

         
        runningRound = uint256(0);
    }


     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


     
    event RateChanged(address indexed owner, uint round, uint256 old_rate, uint256 new_rate);


     
     
    function() public payable
    {
         
        address beneficiary = msg.sender;

         
        require(beneficiary != 0x0);

         
        uint256 weiAmount = msg.value;
        require(weiAmount != 0);

         
        uint256 roundIndex = runningRound;

         
        require(roundIndex != uint256(100));

         
        Round storage round = rounds[roundIndex];

         
        uint256 tokens = weiAmount.mul(round.rate);
        uint256 maxPerUser = round.maxPerUser;
        uint256 remaining = maxPerUser - round.balances[beneficiary];
        if(remaining < tokens)
            tokens = remaining;

         
        require(areTokensBuyable(roundIndex, tokens));

         
        round.availableTokens = round.availableTokens.sub(tokens);

         
        round.balances[msg.sender] = round.balances[msg.sender].add(tokens);

         
        balances[owner] = balances[owner].sub(tokens);
        balances[beneficiary] = balances[beneficiary].add(tokens);
        Transfer(owner, beneficiary, tokens);

         
        TokenPurchase(beneficiary, beneficiary, weiAmount, tokens);

         
        weiRaised = weiRaised.add(weiAmount);

         
        wallet.transfer(msg.value);
    }


     
    function areTokensBuyable(uint _roundIndex, uint256 _tokens) internal constant returns (bool)
    {
        uint256 current_time = block.timestamp;
        Round storage round = rounds[_roundIndex];

        return (
        _tokens > 0 &&                                               
        round.availableTokens >= _tokens &&                          
        current_time >= round.startTime &&                           
        current_time <= round.endTime                                
        );
    }



     
    function tokenBalance() constant public returns (uint256)
    {
        return balanceOf(owner);
    }


    event Burn(address burner, uint256 value);


     
    function burn(uint256 _value) public onlyOwner
    {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }



     
    function mint(uint256 _value) public onlyOwner
    {
        totalSupply = totalSupply.add(_value);
        balances[msg.sender] = balances[msg.sender].add(_value);
    }



     
     
    function setTokensLocked(bool _value) onlyOwner public
    {
        locked = _value;
    }

     
    function setRound(uint256 _roundIndex) public onlyOwner
    {
        runningRound = _roundIndex;
    }

    function setAdmin(address _addr, bool _value) onlyOwner public
    {
        admin[_addr] = _value;
    }

    function setReceivable(address _addr, bool _value) onlyOwner public
    {
        receivable[_addr] = _value;
    }

    function setRoundStart(uint _round, uint256 _value) onlyOwner public
    {
        require(_round >= 0 && _round < rounds.length);
        rounds[_round].startTime = _value;
    }

    function setRoundEnd(uint _round, uint256 _value) onlyOwner public
    {
        require(_round >= 0 && _round < rounds.length);
        rounds[_round].endTime = _value;
    }

    function setRoundAvailableToken(uint _round, uint256 _value) onlyOwner public
    {
        require(_round >= 0 && _round < rounds.length);
        rounds[_round].availableTokens = _value;
    }

    function setRoundMaxPerUser(uint _round, uint256 _value) onlyOwner public
    {
        require(_round >= 0 && _round < rounds.length);
        rounds[_round].maxPerUser = _value;
    }

    function setRoundRate(uint _round, uint256 _round_usd_cents, uint256 _ethvalue_usd) onlyOwner public
    {
        require(_round >= 0 && _round < rounds.length);
        uint256 rate = _ethvalue_usd * 100 / _round_usd_cents;
        uint256 oldRate = rounds[_round].rate;
        rounds[_round].rate = rate;
        RateChanged(msg.sender, _round, oldRate, rounds[_round].rate);
    }
     


     
     
    function getRoundUserBalance(uint _round, address _user) public constant returns (uint256)
    {
        require(_round >= 0 && _round < rounds.length);
        return rounds[_round].balances[_user];
    }

    function getRoundStart(uint _round) public constant returns (uint256)
    {
        require(_round >= 0 && _round < rounds.length);
        return rounds[_round].startTime;
    }

    function getRoundEnd(uint _round) public constant returns (uint256)
    {
        require(_round >= 0 && _round < rounds.length);
        return rounds[_round].endTime;
    }

    function getRoundAvailableToken(uint _round) public constant returns (uint256)
    {
        require(_round >= 0 && _round < rounds.length);
        return rounds[_round].availableTokens;
    }

    function getRoundMaxPerUser(uint _round) public constant returns (uint256)
    {
        require(_round >= 0 && _round < rounds.length);
        return rounds[_round].maxPerUser;
    }

    function getRoundRate(uint _round) public constant returns (uint256)
    {
        require(_round >= 0 && _round < rounds.length);
        return rounds[_round].rate;
    }
     
}