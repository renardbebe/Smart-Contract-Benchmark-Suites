 

pragma solidity "0.5.1";

 
 
 
 
 
 
 
 
 

 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 
 
 
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
 
 
 
contract EDE is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint private _teamsTokens;
    uint private _reserveTokens;
    uint256 public fundsRaised;
    uint private maximumCap;
    address payable wallet;
    address [] holders;

    uint256 private presaleopeningtime;
    uint256 private firstsaleopeningtime;
    uint256 private secondsaleopeningtime;
    uint256 private secondsaleclosingtime;

	string public HardCap;
	string public SoftCap;


    mapping(address => uint) balances;
    mapping(address => bool) whitelist;
    mapping(address => mapping(address => uint)) allowed;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    modifier onlyWhileOpen {
        require((now >= presaleopeningtime && now <= secondsaleclosingtime) && fundsRaised != maximumCap);  
        _;
    }

     
     
     
    constructor() public {
        symbol = "EDE";
        name = "eden.best";
        decimals = 0;
        _totalSupply = 45e7;
        balances[address(this)] = 3375e5 * 10**uint(decimals);  
        emit Transfer(address(0),address(this), 3375e5 * 10**uint(decimals));
        balances[address(0x687abe81c44c982394EED1b0Fc6911e5338A6421)] = 66150000 * 10**uint(decimals);  
        emit Transfer(address(0),address(0x687abe81c44c982394EED1b0Fc6911e5338A6421), 66150000 * 10**uint(decimals));
        balances[address(0xd903846cF43aC9046CAE50C36ac1Aa18e630A1bB)] = 45000000 * 10**uint(decimals);  
        emit Transfer(address(0),address(0xd903846cF43aC9046CAE50C36ac1Aa18e630A1bB), 45000000 * 10**uint(decimals));
        balances[address(0x7341459eCdABC42C7493D923F5bb0992616d30A7)] = 1350000 * 10**uint(decimals);  
        emit Transfer(address(0),address(0x7341459eCdABC42C7493D923F5bb0992616d30A7), 1350000 * 10**uint(decimals));
        owner = address(0xEfA2CcE041aEB143678F8f310F3977F3EB61251E);
        wallet = address(0xEfA2CcE041aEB143678F8f310F3977F3EB61251E);
		    HardCap = "16875 ETH";
        SoftCap = "300 ETH";
        maximumCap = 16875000000000000000000;  
        presaleopeningtime = 1554120000;  
        firstsaleopeningtime = 1555329601;  
        secondsaleopeningtime = 1559304001;  
        secondsaleclosingtime = 1561896001;  
    }

     
     
     
    function () external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _beneficiary) public payable onlyWhileOpen {
        _preValidatePurchase(_beneficiary, msg.value);
        _continueTokenPurchase(_beneficiary, msg.value);
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view{
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        require(_weiAmount >= 50000000000000000 && _weiAmount <= 1000000000000000000000);  
        require(whitelist[_beneficiary]);
    }

    function _insertWhitelist(address[] memory _beneficiary) public onlyOwner{
        for(uint256 i = 0; i< _beneficiary.length; i++)
        {
            if(whitelist[_beneficiary[i]] == false)
                whitelist[_beneficiary[i]] = true;
        }
    }

    function _continueTokenPurchase(address _beneficiary, uint256 _weiAmount) internal{
        uint256 _tokens = _getTokenAmount(_weiAmount).div(1e18);
        uint256 bonus = _calculateBonus();
        _tokens = _tokens.add((_tokens.mul(bonus.mul(100))).div(10000));

        fundsRaised = fundsRaised.add(_weiAmount);

        _processPurchase(_beneficiary, _tokens);

        wallet.transfer(_weiAmount);
        emit TokenPurchase(address(this), _beneficiary, _weiAmount, _tokens);
    }

    function _getTokenAmount(uint256 _weiAmount) internal pure returns (uint256) {
        uint256 rate = 2e4;  
        return _weiAmount.mul(rate);
    }

    function _calculateBonus() internal view returns (uint256){
        if(now >= presaleopeningtime && now < firstsaleopeningtime){
            return 30;
        } else if(now >=firstsaleopeningtime && now <secondsaleopeningtime){
            return 20;
        } else if(now >= secondsaleopeningtime && now <secondsaleclosingtime){
            return 0;
        }
    }

    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        _transfer(_beneficiary, _tokenAmount);
    }

     

    function totalSupply() public view returns (uint){
       return _totalSupply* 10**uint(decimals);
    }
     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
         
        require(to != address(0));
        require(whitelist[to]);
        require(balances[msg.sender] >= tokens );
        require(balances[to] + tokens >= balances[to]);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        if(balances[to] == 0)
            holders.push(to);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender,to,tokens);
        return true;
    }

     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success){
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
    }

     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success){
        require(tokens <= allowed[from][msg.sender]);  
        require(balances[from] >= tokens);
        require(whitelist[to]);
        balances[from] = balances[from].sub(tokens);
        if(balances[to] == 0)
            holders.push(to);
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        emit Transfer(from,to,tokens);
        return true;
    }
     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function _transfer(address to, uint tokens) internal returns (bool success) {
         
        require(to != address(0));
        require(balances[address(this)] >= tokens );
        require(balances[to] + tokens >= balances[to]);
        balances[address(this)] = balances[address(this)].sub(tokens);
        if(balances[to] == 0)
            holders.push(to);
        balances[to] = balances[to].add(tokens);
        emit Transfer(address(this),to,tokens);
        return true;
    }

    function _hardCapNotReached() external onlyOwner {
        uint eightyPercent = (balances[address(this)].mul(80)).div(100);  
        uint twentyPercent = balances[address(this)].sub(eightyPercent);  
        uint share = eightyPercent.div(holders.length);

        for(uint i = 0; i<holders.length; i++ ){
            address holder = holders[i];
            balances[holder] = balances[holder].add(share);
            emit Transfer(address(this),holder,share);
        }

        balances[address(0x687abe81c44c982394EED1b0Fc6911e5338A6421)] = twentyPercent;
        emit Transfer(address(this),address(0x687abe81c44c982394EED1b0Fc6911e5338A6421),twentyPercent);

        balances[address(this)] = 0;



    }
}