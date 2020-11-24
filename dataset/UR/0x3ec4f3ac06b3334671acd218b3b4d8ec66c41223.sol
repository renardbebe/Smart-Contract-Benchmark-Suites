 

pragma solidity ^0.4.21;

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

contract BasicToken is ERC20Basic {

    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        uint256 _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {

         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

 
contract Ownable {

    address public owner;

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    event OwnerLog(address a);

}

contract Configurable is Ownable {

    address public configurer;

    function Configurable() public {
        configurer = msg.sender;
    }

    modifier onlyConfigurerOrOwner() {
        require(msg.sender == configurer || msg.sender == owner);
        _;
    }

    modifier onlyConfigurer() {
        require(msg.sender == configurer);
        _;
    }
}

contract DLCToken is StandardToken, Configurable {

    string public constant name = "DoubleLand Coin";
    string public constant symbol = "DLC";
    uint32 public constant decimals = 18;

    uint256 public priceOfToken;

    bool tokenBeenInit = false;

    uint public constant percentRate = 100;
    uint public investorsTokensPercent;
    uint public foundersTokensPercent;
    uint public bountyTokensPercent;
    uint public developmentAuditPromotionTokensPercent;

    address public toSaleWallet;
    address public bountyWallet;
    address public foundersWallet;
    address public developmentAuditPromotionWallet;

    address public saleAgent;


    function DLCToken() public {
    }

    modifier notInit() {
        require(!tokenBeenInit);
        _;
    }

    function setSaleAgent(address newSaleAgent) public onlyConfigurerOrOwner{
        saleAgent = newSaleAgent;
    }

    function setPriceOfToken(uint256 newPriceOfToken) public onlyConfigurerOrOwner{
        priceOfToken = newPriceOfToken;
    }

    function setTotalSupply(uint256 _totalSupply) public notInit onlyConfigurer{
        totalSupply = _totalSupply;
    }

    function setFoundersTokensPercent(uint _foundersTokensPercent) public notInit onlyConfigurer{
        foundersTokensPercent = _foundersTokensPercent;
    }

    function setBountyTokensPercent(uint _bountyTokensPercent) public notInit onlyConfigurer{
        bountyTokensPercent = _bountyTokensPercent;
    }

    function setDevelopmentAuditPromotionTokensPercent(uint _developmentAuditPromotionTokensPercent) public notInit onlyConfigurer{
        developmentAuditPromotionTokensPercent = _developmentAuditPromotionTokensPercent;
    }

    function setBountyWallet(address _bountyWallet) public notInit onlyConfigurer{
        bountyWallet = _bountyWallet;
    }

    function setToSaleWallet(address _toSaleWallet) public notInit onlyConfigurer{
        toSaleWallet = _toSaleWallet;
    }

    function setFoundersWallet(address _foundersWallet) public notInit onlyConfigurer{
        foundersWallet = _foundersWallet;
    }

    function setDevelopmentAuditPromotionWallet(address _developmentAuditPromotionWallet) public notInit onlyConfigurer {
        developmentAuditPromotionWallet = _developmentAuditPromotionWallet;
    }

    function init() public notInit onlyConfigurer{
        require(totalSupply > 0);
        require(foundersTokensPercent > 0);
        require(bountyTokensPercent > 0);
        require(developmentAuditPromotionTokensPercent > 0);
        require(foundersWallet != address(0));
        require(bountyWallet != address(0));
        require(developmentAuditPromotionWallet != address(0));
        tokenBeenInit = true;

        investorsTokensPercent = percentRate - (foundersTokensPercent + bountyTokensPercent + developmentAuditPromotionTokensPercent);

        balances[toSaleWallet] = totalSupply.mul(investorsTokensPercent).div(percentRate);
        balances[foundersWallet] = totalSupply.mul(foundersTokensPercent).div(percentRate);
        balances[bountyWallet] = totalSupply.mul(bountyTokensPercent).div(percentRate);
        balances[developmentAuditPromotionWallet] = totalSupply.mul(developmentAuditPromotionTokensPercent).div(percentRate);
    }

    function getRestTokenBalance() public constant returns (uint256) {
        return balances[toSaleWallet];
    }

    function purchase(address beneficiary, uint256 qty) public {
        require(msg.sender == saleAgent || msg.sender == owner);
        require(beneficiary != address(0));
        require(qty > 0);
        require((getRestTokenBalance().sub(qty)) > 0);

        balances[beneficiary] = balances[beneficiary].add(qty);
        balances[toSaleWallet] = balances[toSaleWallet].sub(qty);

        emit Transfer(toSaleWallet, beneficiary, qty);
    }

    function () public payable {
        revert();
    }
}

contract Bonuses {
    using SafeMath for uint256;

    DLCToken public token;

    uint256 public startTime;
    uint256 public endTime;

    mapping(uint => uint256) public bonusOfDay;

    bool public bonusInited = false;

    function initBonuses (string _preset) public {
        require(!bonusInited);
        bonusInited = true;
        bytes32 preset = keccak256(_preset);

        if(preset == keccak256('privatesale')){
            bonusOfDay[0] = 313;
        } else
            if(preset == keccak256('presale')){
                bonusOfDay[0] = 210;
            } else
                if(preset == keccak256('generalsale')){
                    bonusOfDay[0] = 60;
                    bonusOfDay[7] = 38;
                    bonusOfDay[14] = 10;
                }
    }

    function calculateTokensQtyByEther(uint256 amount) public constant returns(uint256) {
        int dayOfStart = int(now.sub(startTime).div(86400).add(1));
        uint currentBonus = 0;
        int i;

        for (i = dayOfStart; i >= 0; i--) {
            if (bonusOfDay[uint(i)] > 0) {
                currentBonus = bonusOfDay[uint(i)];
                break;
            }
        }

        return amount.div(token.priceOfToken()).mul(currentBonus + 100).div(100).mul(1 ether);
    }
}

contract Sale is Configurable, Bonuses{
    using SafeMath for uint256;

    address public multisigWallet;
    uint256 public tokensLimit;
    uint256 public minimalPrice;
    uint256 public tokensTransferred = 0;

    string public bonusPreset;

    uint256 public collected = 0;

    bool public activated = false;
    bool public closed = false;
    bool public saleInited = false;


    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function init(
        string _bonusPreset,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _tokensLimit,
        uint256 _minimalPrice,
        DLCToken _token,
        address _multisigWallet
    ) public onlyConfigurer {
        require(!saleInited);
        require(_endTime >= _startTime);
        require(_tokensLimit > 0);
        require(_multisigWallet != address(0));

        saleInited = true;

        token = _token;
        startTime = _startTime;
        endTime = _endTime;
        tokensLimit = _tokensLimit;
        multisigWallet = _multisigWallet;
        minimalPrice = _minimalPrice;
        bonusPreset = _bonusPreset;

        initBonuses(bonusPreset);
    }

    function activate() public onlyConfigurerOrOwner {
        require(!activated);
        require(!closed);
        activated = true;
    }

    function close() public onlyConfigurerOrOwner {
        activated = true;
        closed = true;
    }

    function setMultisigWallet(address _multisigWallet) public onlyConfigurerOrOwner {
        multisigWallet = _multisigWallet;
    }

    function () external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 amount = msg.value;
        uint256 tokens = calculateTokensQtyByEther({
            amount: amount
            });

        require(tokensTransferred.add(tokens) < tokensLimit);

        tokensTransferred = tokensTransferred.add(tokens);
        collected = collected.add(amount);

        token.purchase(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, amount, tokens);

        forwardFunds();
    }

    function forwardFunds() internal {
        multisigWallet.transfer(msg.value);
    }

    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        bool minimalPriceChecked = msg.value >= minimalPrice;
        return withinPeriod && nonZeroPurchase && minimalPriceChecked && activated && !closed;
    }

    function isStarted() public constant returns (bool) {
        return now > startTime;
    }

    function isEnded() public constant returns (bool) {
        return now > endTime;
    }
}


contract DoubleLandICOtest is Ownable {
    using SafeMath for uint256;

    DLCToken public token;

    Sale[] public sales;

    uint256 public softCap;
    uint256 public hardCap;

    uint public activatedSalesTotalCount = 0;
    uint public maxActivatedSalesTotalCount;

    address public multisigWallet;

    bool public isDeployed = false;

    function createSale(string _bonusPreset, uint256 _startTime, uint256 _endTime,  uint256 _tokensLimit, uint256 _minimalPrice) public onlyOwner{
        require(activatedSalesTotalCount < maxActivatedSalesTotalCount);
        require(getTotalCollected() < hardCap );
        require(token.getRestTokenBalance() >= _tokensLimit);
        require(sales.length == 0 || sales[sales.length - 1].activated());
        Sale newSale = new Sale();

        newSale.init({
            _bonusPreset: _bonusPreset,
            _startTime: _startTime,
            _endTime: _endTime,
            _tokensLimit: _tokensLimit,
            _minimalPrice: _minimalPrice,
            _token: token,
            _multisigWallet: multisigWallet
            });
        newSale.transferOwnership(owner);

        sales.push(newSale);
    }

    function activateLastSale() public onlyOwner {
        require(activatedSalesTotalCount < maxActivatedSalesTotalCount);
        require(!sales[sales.length - 1].activated());
        activatedSalesTotalCount ++;
        sales[sales.length - 1].activate();
        token.setSaleAgent(sales[sales.length - 1]);
    }

    function removeLastSaleOnlyNotActivated() public onlyOwner {
        require(!sales[sales.length - 1].activated());
        delete sales[sales.length - 1];
    }

    function closeAllSales() public onlyOwner {
        for (uint i = 0; i < sales.length; i++) {
            sales[i].close();
        }
    }

    function setGlobalMultisigWallet(address _multisigWallet) public onlyOwner {
        multisigWallet = _multisigWallet;
        for (uint i = 0; i < sales.length; i++) {
            if (!sales[i].closed()) {
                sales[i].setMultisigWallet(multisigWallet);
            }
        }
    }

    function getTotalCollected() public constant returns(uint256) {
        uint256 _totalCollected = 0;
        for (uint i = 0; i < sales.length; i++) {
            _totalCollected = _totalCollected + sales[i].collected();
        }
        return _totalCollected;
    }

    function getCurrentSale() public constant returns(address) {
        return token.saleAgent();
    }

    function deploy() public onlyOwner {
        require(!isDeployed);
        isDeployed = true;

        softCap = 8000 ether;
        hardCap = 40000 ether;
        maxActivatedSalesTotalCount = 5;

        setGlobalMultisigWallet(0xcC6E23E740FBc50e242B6B90f0BcaF64b83BF813);

        token = new DLCToken();
        token.setTotalSupply(1000000000 * 1 ether);
        token.setFoundersTokensPercent(15);
        token.setBountyTokensPercent(1);
        token.setDevelopmentAuditPromotionTokensPercent(10);
        token.setPriceOfToken(0.00013749 * 1 ether);
        token.setToSaleWallet(0xf9D1398a6e2c856fab73B5baaD13D125EDe30006);
        token.setBountyWallet(0xFc6248b06e65686C9aDC5f4F758bBd716BaE80e1);
        token.setFoundersWallet(0xf54315F87480f87Bfa2fCe97aCA036fd90223516);
        token.setDevelopmentAuditPromotionWallet(0x34EEA5f12DeF816Bd86F682eDc6010500dd51976);
        token.transferOwnership(owner);
        token.init();

        createSale({
            _bonusPreset: 'privatesale',
             
            _startTime: 1522342800,  
             
            _endTime:   1524614400,  
            _tokensLimit: 80000000 * 1 ether,
             
             
            _minimalPrice: 0 ether
            });
        activateLastSale();

        createSale({
            _bonusPreset: 'presale',
            _startTime: 1525910400,  
            _endTime:   1527206400,  
            _tokensLimit: 75000000 * 1 ether,
            _minimalPrice: 0.03 ether
            });
    }
}