 

pragma solidity ^ 0.4.19;

 
contract GdprConfig {

     
    string public constant TOKEN_NAME = "GDPR Cash";
    string public constant TOKEN_SYMBOL = "GDPR";
    uint8 public constant TOKEN_DECIMALS = 18;

     
    uint256 public constant MIN_TOKEN_UNIT = 10 ** uint256(TOKEN_DECIMALS);
     
    uint256 public constant PURCHASER_MIN_TOKEN_CAP = 500 * MIN_TOKEN_UNIT;
     
    uint256 public constant PURCHASER_MAX_TOKEN_CAP_DAY1 = 10000 * MIN_TOKEN_UNIT;
     
    uint256 public constant PURCHASER_MAX_TOKEN_CAP = 100000 * MIN_TOKEN_UNIT;

     
    uint256 public constant INITIAL_RATE = 7600;  

     
    uint256 public constant TOTAL_SUPPLY_CAP = 200000000 * MIN_TOKEN_UNIT;
     
    uint256 public constant SALE_CAP = 120000000 * MIN_TOKEN_UNIT;
     
    uint256 public constant EXPERTS_POOL_TOKENS = 20000000 * MIN_TOKEN_UNIT;
     
    uint256 public constant MARKETING_POOL_TOKENS = 20000000 * MIN_TOKEN_UNIT;
     
    uint256 public constant TEAM_POOL_TOKENS = 18000000 * MIN_TOKEN_UNIT;
     
    uint256 public constant LEGAL_EXPENSES_TOKENS = 2000000 * MIN_TOKEN_UNIT;
     
    uint256 public constant RESERVE_POOL_TOKENS = 20000000 * MIN_TOKEN_UNIT;

     
    address public constant EXPERTS_POOL_ADDR = 0x289bB02deaF473c6Aa5edc4886A71D85c18F328B;
    address public constant MARKETING_POOL_ADDR = 0x7BFD82C978EDDce94fe12eBF364c6943c7cC2f27;
    address public constant TEAM_POOL_ADDR = 0xB4AfbF5F39895adf213194198c0ba316f801B24d;
    address public constant LEGAL_EXPENSES_ADDR = 0xf72931B08f8Ef3d8811aD682cE24A514105f713c;
    address public constant SALE_FUNDS_ADDR = 0xb8E81a87c6D96ed5f424F0A33F13b046C1f24a24;
    address public constant RESERVE_POOL_ADDR = 0x010aAA10BfB913184C5b2E046143c2ec8A037413;
}


 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}




 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}



 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

 
contract ERC20Basic {
    function totalSupply() public view returns(uint256);
    function balanceOf(address who) public view returns(uint256);
    function transfer(address to, uint256 value) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns(uint256);
    function transferFrom(address from, address to, uint256 value) public returns(bool);
    function approve(address spender, uint256 value) public returns(bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract DetailedERC20 is ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    function DetailedERC20(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
}



 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

        mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    function totalSupply() public view returns(uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns(uint256 balance) {
        return balances[_owner];
    }

}



 
contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns(uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns(bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns(bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}



 
contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns(bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner canMint public returns(bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}



 
contract CappedToken is MintableToken {

    uint256 public cap;

    function CappedToken(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }

     
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns(bool) {
        require(totalSupply_.add(_amount) <= cap);

        return super.mint(_to, _amount);
    }

}


 
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        Burn(burner, _value);
    }
}




 
contract GdprCash is DetailedERC20, CappedToken, GdprConfig {

    bool private transfersEnabled = false;
    address public crowdsale = address(0);

     
    event Burn(address indexed burner, uint256 value);

     
    modifier canTransfer() {
        require(transfersEnabled || msg.sender == owner || msg.sender == crowdsale);
        _;
    }

     
    modifier onlyCrowdsale() {
        require(msg.sender == crowdsale);
        _;
    }

     
    function GdprCash() public
    DetailedERC20(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS)
    CappedToken(TOTAL_SUPPLY_CAP) {
    }

     
    function setCrowdsale(address _crowdsaleAddr) external onlyOwner {
        require(crowdsale == address(0));
        require(_crowdsaleAddr != address(0));
        require(!transfersEnabled);
        crowdsale = _crowdsaleAddr;

         
        mint(crowdsale, SALE_CAP);

         
        mint(EXPERTS_POOL_ADDR, EXPERTS_POOL_TOKENS);
        mint(MARKETING_POOL_ADDR, MARKETING_POOL_TOKENS);
        mint(TEAM_POOL_ADDR, TEAM_POOL_TOKENS);
        mint(LEGAL_EXPENSES_ADDR, LEGAL_EXPENSES_TOKENS);
        mint(RESERVE_POOL_ADDR, RESERVE_POOL_TOKENS);

        finishMinting();
    }

     
    function transfer(address _to, uint256 _value)
        public canTransfer returns(bool)
    {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
        public canTransfer returns(bool)
    {
        return super.transferFrom(_from, _to, _value);
    }

     
    function enableTransfers() public onlyCrowdsale {
        transfersEnabled = true;
    }

     
    function burn(uint256 _value) public onlyCrowdsale {
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        Burn(burner, _value);
    }
}





 
contract GdprCrowdsale is Pausable {
    using SafeMath for uint256;

         
        GdprCash public token;

     
    uint256 public startTime;
    uint256 public endTime;

     
    address public wallet;

     
    uint256 public rate;

     
    uint256 public weiRaised = 0;

     
    uint256 public totalPurchased = 0;

     
    mapping(address => uint256) public tokensPurchased;

     
    bool public isFinalized = false;

     
     
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount);

     
    event TokenPresale(
        address indexed purchaser,
        uint256 amount);

     
    event RateChange(uint256 newRate);

     
    event FundWithdrawal(uint256 amount);

     
    event Finalized();

     
    function GdprCrowdsale(
        uint256 _startTime,
        uint256 _endTime,
        address _tokenAddress
    ) public
    {
        require(_endTime > _startTime);
        require(_tokenAddress != address(0));

        startTime = _startTime;
        endTime = _endTime;
        token = GdprCash(_tokenAddress);
        rate = token.INITIAL_RATE();
        wallet = token.SALE_FUNDS_ADDR();
    }

     
    function () public whenNotPaused payable {
        buyTokens(msg.sender, msg.value);
    }

     
    function setStartTime(uint256 _startTime) public onlyOwner {
        require(now < startTime);
        require(_startTime > now);
        require(_startTime < endTime);

        startTime = _startTime;
    }

     
    function setEndTime(uint256 _endTime) public onlyOwner {
        require(now < endTime);
        require(_endTime > now);
        require(_endTime > startTime);

        endTime = _endTime;
    }

     
    function setRate(uint256 _rate) public onlyOwner {
        require(_rate > 0);
        rate = _rate;
        RateChange(rate);
    }

     
    function finalize() public onlyOwner {
        require(now > endTime);
        require(!isFinalized);

        finalization();
        Finalized();

        isFinalized = true;
    }

     
    function hasEnded() public view returns(bool) {
        return now > endTime;
    }

     
    function withdraw(uint256 _amount) public onlyOwner {
        require(this.balance > 0);
        require(_amount <= this.balance);
        uint256 balanceToSend = _amount;
        if (balanceToSend == 0) {
            balanceToSend = this.balance;
        }
        wallet.transfer(balanceToSend);
        FundWithdrawal(balanceToSend);
    }

     
    function addPresaleOrder(address _participant, uint256 _tokenAmount) external onlyOwner {
        require(now < startTime);

         
        tokensPurchased[_participant] = tokensPurchased[_participant].add(_tokenAmount);
        totalPurchased = totalPurchased.add(_tokenAmount);

        token.transfer(_participant, _tokenAmount);

        TokenPresale(
            _participant,
            _tokenAmount
        );
    }

     
    function buyTokens(address _participant, uint256 _weiAmount) internal {
        require(_participant != address(0));
        require(now >= startTime);
        require(now < endTime);
        require(!isFinalized);
        require(_weiAmount != 0);

         
        uint256 tokens = _weiAmount.mul(rate);

         
        tokensPurchased[_participant] = tokensPurchased[_participant].add(tokens);
        totalPurchased = totalPurchased.add(tokens);
         
        weiRaised = weiRaised.add(_weiAmount);

        require(totalPurchased <= token.SALE_CAP());
        require(tokensPurchased[_participant] >= token.PURCHASER_MIN_TOKEN_CAP());

        if (now < startTime + 86400) {
             
            require(tokensPurchased[_participant] <= token.PURCHASER_MAX_TOKEN_CAP_DAY1());
        } else {
            require(tokensPurchased[_participant] <= token.PURCHASER_MAX_TOKEN_CAP());
        }

        token.transfer(_participant, tokens);

        TokenPurchase(
            msg.sender,
            _participant,
            _weiAmount,
            tokens
        );
    }

     
    function finalization() internal {
        withdraw(0);
        burnUnsold();
        token.enableTransfers();
    }

     
    function burnUnsold() internal {
         
        token.burn(token.balanceOf(this));
    }
}