 

pragma solidity ^0.4.23;

 
contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

 
contract OneStageMainSale is Ownable {

    ERC20 public token;
    
    ERC20 public authorize;
    
    using SafeMath for uint;

    address public backEndOperator = msg.sender;
    address team = 0x7eDE8260e573d3A3dDfc058f19309DF5a1f7397E;  
    address bounty = 0x0cdb839B52404d49417C8Ded6c3E2157A06CdD37;  
    address reserve = 0xC032D3fCA001b73e8cC3be0B75772329395caA49;  

    mapping(address=>bool) public whitelist;

    mapping(address => uint256) public investedEther;

    uint256 public start1StageSale = 1539561601;  
    uint256 public end1StageSale = 1542326399;  

    uint256 public investors;  
    uint256 public weisRaised;  

    uint256 public softCap1Stage = 1000000*1e18;  
    uint256 public hardCap1Stage = 1700000*1e18;  

    uint256 public buyPrice;  
    uint256 public dollarPrice;  

    uint256 public soldTokens;  

    event Authorized(address wlCandidate, uint timestamp);
    event Revoked(address wlCandidate, uint timestamp);
    event UpdateDollar(uint256 time, uint256 _rate);

    modifier backEnd() {
        require(msg.sender == backEndOperator || msg.sender == owner);
        _;
    }

     
    constructor(ERC20 _token, ERC20 _authorize, uint256 usdETH) public {
        token = _token;
        authorize = _authorize;
        dollarPrice = usdETH;
        buyPrice = (1e17/dollarPrice)*26;  
    }

     
    function setStartOneSale(uint256 newStart1Sale) public onlyOwner {
        start1StageSale = newStart1Sale;
    }

     
    function setEndOneSale(uint256 newEnd1Sale) public onlyOwner {
        end1StageSale = newEnd1Sale;
    }

     
    function setBackEndAddress(address newBackEndOperator) public onlyOwner {
        backEndOperator = newBackEndOperator;
    }

     
    function setBuyPrice(uint256 _dollar) public backEnd {
        dollarPrice = _dollar;
        buyPrice = (1e17/dollarPrice)*26;  
        emit UpdateDollar(now, dollarPrice);
    }


     

    function isOneStageSale() public constant returns(bool) {
        return now >= start1StageSale && now <= end1StageSale;
    }

     
    function () public payable {
        require(authorize.isWhitelisted(msg.sender));
        require(isOneStageSale());
        require(msg.value >= 19*buyPrice);  
        SaleOneStage(msg.sender, msg.value);
        require(soldTokens<=hardCap1Stage);
        investedEther[msg.sender] = investedEther[msg.sender].add(msg.value);
    }

     
    function SaleOneStage(address _investor, uint256 _value) internal {
        uint256 tokens = _value.mul(1e18).div(buyPrice);
        uint256 tokensByDate = tokens.div(10);
        uint256 bonusSumTokens = tokens.mul(bonusSum(tokens)).div(100);
        tokens = tokens.add(tokensByDate).add(bonusSumTokens);  
        token.mintFromICO(_investor, tokens);
        soldTokens = soldTokens.add(tokens);

        uint256 tokensTeam = tokens.mul(11).div(20);  
        token.mintFromICO(team, tokensTeam);

        uint256 tokensBoynty = tokens.div(30);  
        token.mintFromICO(bounty, tokensBoynty);

        uint256 tokensReserve = tokens.div(12);   
        token.mintFromICO(reserve, tokensReserve);

        weisRaised = weisRaised.add(_value);
    }

    function bonusSum(uint256 _amount) pure private returns(uint256) {
        if (_amount > 76923*1e18) {  
            return 10;
        } else if (_amount > 19230*1e18) {  
            return 7;
        } else if (_amount > 7692*1e18) {  
            return 5;
        } else if (_amount > 1923*1e18) {  
            return 3;
        } else {
            return 0;
        }
    }

     
    function transferEthFromContract(address _to, uint256 amount) public onlyOwner {
        _to.transfer(amount);
    }

     
    function refund1ICO() public {
        require(soldTokens < softCap1Stage && now > end1StageSale);
        uint rate = investedEther[msg.sender];
        require(investedEther[msg.sender] >= 0);
        investedEther[msg.sender] = 0;
        msg.sender.transfer(rate);
        weisRaised = weisRaised.sub(rate);
    }
}