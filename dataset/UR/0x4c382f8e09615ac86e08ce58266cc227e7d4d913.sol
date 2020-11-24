 

pragma solidity ^0.4.13;

contract ERC20 {

    function totalSupply() constant returns (uint totalSupply);

    function balanceOf(address _owner) constant returns (uint balance);

    function transfer(address _to, uint _value) returns (bool success);

    function transferFrom(address _from, address _to, uint _value) returns (bool success);

    function approve(address _spender, uint _value) returns (bool success);

    function allowance(address _owner, address _spender) constant returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);

    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

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

contract SkrillaToken is ERC20 {
    using SafeMath for uint;

    string public constant name = "Skrilla";
    string public constant symbol = "SKR";
    uint8 public constant decimals = 6;
    uint256 public totalSupply;
     
     
    uint256 internal constant SUBUNIT_MULTIPLIER = 10 ** uint256(decimals);

     
    mapping (address => uint256) tokenSaleBalances;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => uint256) whiteList;

     
    uint256 internal constant SALE_CAP = 600 * 10**6 * SUBUNIT_MULTIPLIER;
    uint256 internal constant TEAM_TOKENS = 100 * 10**6 * SUBUNIT_MULTIPLIER;
    uint256 internal constant GROWTH_TOKENS = 300 * 10**6 * SUBUNIT_MULTIPLIER;
    uint256 internal constant TOTAL_SUPPLY_CAP  = SALE_CAP + TEAM_TOKENS + GROWTH_TOKENS;

    address internal withdrawAddress;

     
    uint256 public ethRaised;
    
    address internal owner;
    address internal growth;
    address internal team;

    uint256[7] public saleStageStartDates;

     
    uint16[6] public tokens = [3000,2500,0,2400,2200,2000];


    function tokenSaleBalanceOf(address _owner) public constant returns (uint256 balance) {
        balance = tokenSaleBalances[_owner];
    }

    function getPreSaleStart() public constant returns (uint256) {
        return saleStageStartDates[0];
    }

    function getPreSaleEnd() public constant returns (uint256) {
        return saleStageStartDates[2];
    }

    function getSaleStart() public constant returns (uint256) {
        return saleStageStartDates[3];
    }

    function getSaleEnd() public constant returns (uint256) {
        return saleStageStartDates[6];
    }

     
    function getCurrentPrice(address _buyer) public constant returns (uint256) {
        uint256 price = whiteList[_buyer];

        if (price > 0) {
            return SUBUNIT_MULTIPLIER.mul(price);
        } else {
            uint256 stage = getStage();
            return SUBUNIT_MULTIPLIER.mul(tokens[stage]);
        }
    }

    function inPreSalePeriod() public constant returns (bool) {
        return (now >= getPreSaleStart() && now <= getPreSaleEnd());
    }

    function inSalePeriod() public constant returns (bool) {
        return (now >= getSaleStart() && now <= getSaleEnd());
         
    }

     
    function SkrillaToken(uint256 _preSaleStart, uint256 _saleStart, address _team, address _growth, address _withdrawAddress) {

        owner = msg.sender;

        require(owner != _team && owner != _growth);
        require(_team != _growth);
         
        require(SALE_CAP / SUBUNIT_MULTIPLIER == 600 * 10**6);
        require(GROWTH_TOKENS / SUBUNIT_MULTIPLIER == 300 * 10**6);
        require(TEAM_TOKENS / SUBUNIT_MULTIPLIER == 100 * 10**6);

        team = _team;
        growth = _growth;
        withdrawAddress = _withdrawAddress;

        tokenSaleBalances[team] = TEAM_TOKENS ;
        tokenSaleBalances[growth] = GROWTH_TOKENS ;

        totalSupply = (TEAM_TOKENS + GROWTH_TOKENS);

        if (_preSaleStart == 0) {
            _preSaleStart = 1508533200;  
        }

        if (_saleStart == 0) {
            _saleStart = 1510002000;  
        }

        uint256 preSaleEnd = _preSaleStart.add(3 days);
        require(_saleStart > preSaleEnd);

        saleStageStartDates[0] = _preSaleStart;
        saleStageStartDates[1] = _preSaleStart.add(1 days);
        saleStageStartDates[2] = preSaleEnd;
        saleStageStartDates[3] = _saleStart;
        saleStageStartDates[4] = _saleStart.add(1 days);
        saleStageStartDates[5] = _saleStart.add(7 days);
        saleStageStartDates[6] = _saleStart.add(14 days);

        ethRaised = 0;
    }

     
     
    function withdraw() public returns (bool) {
        require(now > getSaleEnd() + 14 days);

        uint256 tokenSaleBalance = tokenSaleBalances[msg.sender];
        balances[msg.sender] = balances[msg.sender].add(tokenSaleBalance);
        delete tokenSaleBalances[msg.sender];
        Withdraw(msg.sender, tokenSaleBalance);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        balance = balances[_owner];
    }

    function totalSupply() public constant returns (uint256) {
         
        return totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value >= balances[_to]);

        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(_from,_to, _value);
        return true;
    }

    function approve(address _spender, uint256 _amount) public returns (bool success) {
         
         
         
        require(allowed[msg.sender][_spender] == 0 || _amount == 0);

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function addToWhitelist(address _buyer, uint256 _price) public onlyOwner {
        require(_price < 10000);
        whiteList[_buyer] = _price;
    }

    function removeFromWhitelist(address _buyer) public onlyOwner {
        delete whiteList[_buyer];
    }

     
    function() payable {
        buyTokens();
    }

     
    function buyTokens() public payable saleHasNotClosed {
         
        require(msg.value > 0);
        require(ethRaised.add(msg.value) <= 150000 ether);

         
        require(inPreSalePeriod() || inSalePeriod() || (whiteList[msg.sender] > 0));

        if (inPreSalePeriod()) {
            require(msg.value >= 10 ether || whiteList[msg.sender] > 0);
        }

         
        uint256 price = getCurrentPrice(msg.sender);
        require (price > 0);

        uint256 tokenAmount = price.mul(msg.value);
        tokenAmount = tokenAmount.div(1 ether);

        require (tokenAmount > 0);
        require (totalSupply.add(tokenAmount) <= TOTAL_SUPPLY_CAP);

        totalSupply = totalSupply.add(tokenAmount);
        ethRaised = ethRaised.add(msg.value);
        tokenSaleBalances[msg.sender] = tokenSaleBalances[msg.sender].add(tokenAmount);

         
        Transfer(address(0), msg.sender, tokenAmount);
        TokenPurchase(msg.sender, msg.value, tokenAmount);
    }

     
    function transferEth() public onlyOwner {
        require(now > getSaleEnd() + 14 days);
        withdrawAddress.transfer(this.balance);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier saleHasNotClosed()  {
         
        require(now <= getSaleEnd());
        _;
    }

    function getStage() public constant returns (uint256) {
        for (uint256 i = 1; i < saleStageStartDates.length; i++) {
            if (now < saleStageStartDates[i]) {
                return i - 1;
            }
        }

        return saleStageStartDates.length - 1;
    }

    event TokenPurchase(address indexed _purchaser, uint256 _value, uint256 _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Withdraw(address indexed _owner, uint256 _value);
}