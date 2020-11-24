 

pragma solidity ^0.4.25;

 
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

 
contract PreICO is Ownable {

    ERC20 public token;
    
    ERC20 public authorize;
    
    using SafeMath for uint;

    address public backEndOperator = msg.sender;
    address bounty = 0x0cdb839B52404d49417C8Ded6c3E2157A06CdD37;  

    mapping(address=>bool) public whitelist;

    mapping(address => uint256) public investedEther;

    uint256 public startPreICO = 1543700145; 
    uint256 public endPreICO = 1547510400; 

    uint256 public investors;  
    uint256 public weisRaised;  

    uint256 public hardCap1Stage = 10000000*1e18;  

    uint256 public buyPrice;  
    uint256 public euroPrice;  

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
        euroPrice = usdETH;
        buyPrice = (1e18/euroPrice).div(10);  
    }

     
    function setStartSale(uint256 newStartSale) public onlyOwner {
        startPreICO = newStartSale;
    }

     
    function setEndSale(uint256 newEndSale) public onlyOwner {
        endPreICO = newEndSale;
    }

     
    function setBackEndAddress(address newBackEndOperator) public onlyOwner {
        backEndOperator = newBackEndOperator;
    }

     
    function setBuyPrice(uint256 _dollar) public backEnd {
        euroPrice = _dollar;
        buyPrice = (1e18/euroPrice).div(10);  
        emit UpdateDollar(now, euroPrice);
    }


     

    function isPreICO() public constant returns(bool) {
        return now >= startPreICO && now <= endPreICO;
    }

     
    function () public payable {
        require(authorize.isWhitelisted(msg.sender));
        require(isPreICO());
        require(msg.value >= buyPrice.mul(100));  
        SalePreICO(msg.sender, msg.value);
        require(soldTokens<=hardCap1Stage);
        investedEther[msg.sender] = investedEther[msg.sender].add(msg.value);
    }

     
    function SalePreICO(address _investor, uint256 _value) internal {
        uint256 tokens = _value.mul(1e18).div(buyPrice);
        token.mintFromICO(_investor, tokens);
        soldTokens = soldTokens.add(tokens);

        uint256 tokensBoynty = tokens.div(250);  
        token.mintFromICO(bounty, tokensBoynty);

        weisRaised = weisRaised.add(_value);
    }

     
    function transferEthFromContract(address _to, uint256 amount) public onlyOwner {
        _to.transfer(amount);
    }

   
}