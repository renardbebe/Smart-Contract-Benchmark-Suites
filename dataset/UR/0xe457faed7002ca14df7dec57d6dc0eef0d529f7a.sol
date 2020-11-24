 

pragma solidity 0.4.25;

 
 
 
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


 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

}

 
contract ArconexICO is ERC20Interface, Owned {
  using SafeMath for uint256;
  string  public symbol; 
  string  public name;
  uint8   public decimals;
  uint256 public fundsRaised;
  uint256 public reserveTokens;
  string  public TokenPrice;
  uint256 public saleTokens;
  uint    internal _totalSupply;
  uint internal _totalRemaining;
  address public wallet;
  bool internal distributionFinished;
  
  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;
  mapping(address => bool) zeroInvestors;
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
    modifier canDistribut {
        require(!distributionFinished);
        _;
    }
  
     
     
     
    constructor (address _owner, address _wallet) public {
        symbol = "ACX";
        name = " Arconex";
        decimals = 18;
        owner = _owner;
        wallet = _wallet;
        _totalSupply = 200000000;  
        _allocateTokens();
         
        balances[owner] = reserveTokens;
        emit Transfer(address(0),owner, reserveTokens); 
         
        _totalRemaining = saleTokens;
        distributionFinished = false;
    }

    function _allocateTokens() internal {
        reserveTokens         = (_totalSupply.mul(5)).div(100) *10 **uint(decimals);   
        saleTokens            = (_totalSupply.mul(95)).div(100) *10 **uint(decimals);  
        TokenPrice            = "0.0000004 ETH";
    }
    
    function () external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _beneficiary) public payable canDistribut {
    
        uint256 weiAmount = msg.value;
    
        _preValidatePurchase(_beneficiary, weiAmount);
        
        uint256 tokens = _getTokenAmount(_beneficiary, weiAmount);
        
        fundsRaised = fundsRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(this, _beneficiary, weiAmount, tokens);

        _forwardFunds(msg.value);
    }
    
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) view internal{
        require(_beneficiary != address(0));
        if(_weiAmount == 0){
            require(!(zeroInvestors[_beneficiary]));
        }
    }
  
    function _getTokenAmount(address _beneficiary, uint256 _weiAmount) internal returns (uint256) {
        if(_weiAmount == 0){
            zeroInvestors[_beneficiary] = true;
            return 50e18; 
        }
        else{
            uint256 rate = 2500000;  
            return _weiAmount.mul(rate);
        }
    }
    
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        if(_totalRemaining != 0 && _totalRemaining >= _tokenAmount) {
            balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
            emit Transfer(address(0),_beneficiary, _tokenAmount);
            _totalRemaining = _totalRemaining.sub(_tokenAmount);
        }
        
        if(_totalRemaining <= 0) {
            distributionFinished = true;
        }
    }

    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }
    
    function _forwardFunds(uint256 _amount) internal {
        wallet.transfer(_amount);
    }
    
     
    function totalSupply() public constant returns (uint){
       return _totalSupply* 10**uint(decimals);
    }
    
     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
         
        require(to != 0x0);
        require(balances[msg.sender] >= tokens );
        require(balances[to] + tokens >= balances[to]);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
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
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        emit Transfer(from,to,tokens);
        return true;
    }
     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

}