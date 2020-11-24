 

 


pragma solidity ^0.4.24;


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
        public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}


contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

   
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

   
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

   
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
      public
      returns (bool)
    {
        allowed[msg.sender][_spender] = (
            allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

   
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract GRADtoken is StandardToken {
    string public constant name = "Gradus";
    string public constant symbol = "GRAD";
    uint32 public constant decimals = 18;
    uint256 public totalSupply;
    uint256 public tokenBuyRate = 10000;
    
    mapping(address => bool   ) isInvestor;
    address[] public arrInvestors;
    
    address public CrowdsaleAddress;
    bool public lockTransfers = false;

    event Mint (address indexed to, uint256  amount);
    event Burn(address indexed burner, uint256 value);
    
    constructor(address _CrowdsaleAddress) public {
        CrowdsaleAddress = _CrowdsaleAddress;
    }
  
    modifier onlyOwner() {
         
        require(msg.sender == CrowdsaleAddress);
        _;
    }   

    function setTokenBuyRate(uint256 _newValue) public onlyOwner {
        tokenBuyRate = _newValue;
    }

    function addInvestor(address _newInvestor) internal {
        if (!isInvestor[_newInvestor]){
            isInvestor[_newInvestor] = true;
            arrInvestors.push(_newInvestor);
        }  
    }

    function getInvestorAddress(uint256 _num) public view returns(address) {
        return arrInvestors[_num];
    }

    function getInvestorsCount() public view returns(uint256) {
        return arrInvestors.length;
    }

      
    function transfer(address _to, uint256 _value) public returns(bool){
        if (msg.sender != CrowdsaleAddress){
            require(!lockTransfers, "Transfers are prohibited");
        }
        addInvestor(_to);
        return super.transfer(_to,_value);
    }

      
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool){
        if (msg.sender != CrowdsaleAddress){
            require(!lockTransfers, "Transfers are prohibited");
        }
        addInvestor(_to);
        return super.transferFrom(_from,_to,_value);
    }
     
    function mint(address _to, uint256 _value) public onlyOwner returns (bool){
        balances[_to] = balances[_to].add(_value);
        totalSupply = totalSupply.add(_value);
        addInvestor(_to);
        emit Mint(_to, _value);
        emit Transfer(address(0), _to, _value);
        return true;
    }
    
    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        balances[_who] = balances[_who].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
    
    function lockTransfer(bool _lock) public onlyOwner {
        lockTransfers = _lock;
    }

     
    function ReturnToken(uint256 _amount) public payable {
        require (_amount > 0);
        require (msg.sender != address(0));
        
        uint256 weiAmount = _amount.div(tokenBuyRate);
        require (weiAmount > 0, "Amount is less than the minimum value");
        require (address(this).balance >= weiAmount, "Contract balance is empty");
        _burn(msg.sender, _amount);
        msg.sender.transfer(weiAmount);
    }

    function() external payable {
         
    }  

}

contract Ownable {
    address public owner;
    address candidate;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        candidate = newOwner;
    }

    function confirmOwnership() public {
        require(candidate == msg.sender);
        owner = candidate;
        delete candidate;
    }

}

contract Dividend {
     
    using SafeMath for uint256;

    uint256 public receivedDividends;
    address public crowdsaleAddress;
    GRADtoken public token;
    CrowdSale public crowdSaleContract;
    mapping (address => uint256) public divmap;
    event PayDividends(address indexed investor, uint256 amount);

    constructor(address _crowdsaleAddress, address _tokenAddress) public {
        crowdsaleAddress = _crowdsaleAddress;
        token = GRADtoken(_tokenAddress);
        crowdSaleContract = CrowdSale(crowdsaleAddress);
    }

    modifier onlyOwner() {
         
        require(msg.sender == crowdsaleAddress);
        _;
    }  

         
    function _CalcDiv() internal {
        uint256 myAround = 1 ether;
        uint256 i;
        uint256 k;
        address invAddress;
        receivedDividends = receivedDividends.add(msg.value);

        if (receivedDividends >= crowdSaleContract.hardCapDividends()){
            uint256 lengthArrInvesotrs = token.getInvestorsCount();
            crowdSaleContract.lockTransfer(true); 
            k = receivedDividends.mul(myAround).div(token.totalSupply());
            uint256 myProfit;
            
            for (i = 0;  i < lengthArrInvesotrs; i++) {
                invAddress = token.getInvestorAddress(i);
                myProfit = token.balanceOf(invAddress).mul(k).div(myAround);
                divmap[invAddress] = divmap[invAddress].add(myProfit);
            }
            crowdSaleContract.lockTransfer(false); 
            receivedDividends = 0;
        }
    }
    
     
    function Pay() public {
        uint256 dividends = divmap[msg.sender];
        require (dividends > 0);
        require (dividends <= address(this).balance);
        divmap[msg.sender] = 0;
        msg.sender.transfer(dividends);
        emit PayDividends(msg.sender, dividends);
    } 
    
    function killContract(address _profitOwner) public onlyOwner {
        selfdestruct(_profitOwner);
    }

     
    function () external payable {
        _CalcDiv();
    }  

}


     
contract CrowdSale is Ownable{
    using SafeMath for uint256;

     
    address myAddress = this;
    
    GRADtoken public token = new GRADtoken(myAddress);
    Dividend public dividendContract = new Dividend(myAddress, address(token));
    
     
    address public wallet = 0x0;

     
    uint256 public tokenSaleRate; 

     
    uint256 public hardCapDividends;
    
     
    uint256 public currentFunds = 0;
    uint256 public hardCapCrowdSale = 0;
    bool private isSaleActive;

     
    event TokenSale(address indexed _to, uint256 value, uint256 amount);

    constructor() public {
         
        tokenSaleRate = 10000;

         
        hardCapCrowdSale = 10 * (1 ether);
        hardCapDividends = 10 * (1 ether);

         
        wallet = msg.sender;
    }


    modifier restricted(){
        require(msg.sender == owner || msg.sender == address(dividendContract));
        _;
    }

    function setNewDividendContract(address _newContract) public onlyOwner {
        dividendContract = Dividend(_newContract);
    }


     
    function setHardCapCrowdSale(uint256 _newValue) public onlyOwner {
        hardCapCrowdSale = _newValue.mul(1 ether);
        currentFunds = 0;
    }


     
    function setHardCapDividends(uint256 _newValue) public onlyOwner {
        hardCapDividends = _newValue.mul(1 ether);
    }
    
    function setTokenBuyRate(uint256 _newValue) public onlyOwner {
        token.setTokenBuyRate(_newValue);
    }

    function setProfitAddress(address _newWallet) public onlyOwner {
        require(_newWallet != address(0),"Invalid address");
        wallet = _newWallet;
    }

     
    function _saleTokens() internal {
        require(msg.value >= 10**16, "Minimum value is 0.01 ether");
        require(hardCapCrowdSale >= currentFunds.add(msg.value), "Upper limit on fund raising exceeded");      
        require(msg.sender != address(0), "Address sender is empty");
        require(wallet != address(0),"Enter address profit wallet");
        require(isSaleActive, "Set saleStatus in true");

        uint256 weiAmount = msg.value;

         
        uint256 tokens = weiAmount.mul(tokenSaleRate);

        token.mint(msg.sender, tokens);
        emit TokenSale(msg.sender, weiAmount, tokens);
        currentFunds = currentFunds.add(msg.value);
        wallet.transfer(msg.value);
    }

  
    function lockTransfer(bool _lock) public restricted {
         
        token.lockTransfer(_lock);
    }

   
    function disableSale() onlyOwner() public returns (bool) {
        require(isSaleActive == true);
        isSaleActive = false;
        return true;
    }

   
    function enableSale()  onlyOwner() public returns (bool) {
        require(isSaleActive == false);
        isSaleActive = true;
        return true;
    }

   
    function saleStatus() public view returns (bool){
        return isSaleActive;
    }

     
    function killDividentContract(uint256 _kod) public onlyOwner {
        require(_kod == 666);
        dividendContract.killContract(wallet);
    }

   
    function () external payable {
        _saleTokens();
    }

}