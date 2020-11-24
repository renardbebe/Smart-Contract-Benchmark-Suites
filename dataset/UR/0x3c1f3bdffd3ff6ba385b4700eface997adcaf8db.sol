 

pragma solidity 0.5.1;

 
 

 
 
 
 
 


 
 
 
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
    function remainder(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a % b;
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


 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

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


 
 
 
 
contract HIPHOP is ERC20Interface, Owned {
    using SafeMath for uint256;
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 public _totalSupply;
    bool    internal Open;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    
    uint256 public hardCap;
    uint256 public softCap;
    uint256 public fundsRaised;
    uint256 internal firststageopeningTime;
    uint256 internal firststageclosingTime;
    uint256 internal secondstageopeningTime;
    uint256 internal secondstageclosingTime;
    uint256 internal laststageopeningTime;
    uint256 internal laststageclosingTime;
    uint256 internal purchasers;
    address payable wallet;
    uint256 internal minTx;
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
    modifier onlyWhileOpen {
        require(Open);
        _;
    }
    
     
     
     
    constructor(address _owner, address payable _wallet) public {
        symbol = "HIPHOP";
        name = "4hiphop";
        decimals = 18;
        _totalSupply = 1e11 ;  
        owner = _owner;
        wallet = _wallet;
        balances[owner] = totalSupply();
        Open = true;
        
        emit Transfer(address(0),owner, totalSupply());
        
        hardCap = 1e7;  
        softCap = 0;    
        _setTimes();
        minTx = 1 ether;
    }
    
    
     
    
    function totalSupply() public view returns (uint){
       return _totalSupply * 1e18;  
    }
    
     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
         
        require(address(to) != address(0));
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
    
     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function _setTimes() internal {
        firststageopeningTime    = 1548979200;  
        firststageclosingTime    = 1551398400;  
        secondstageopeningTime   = 1554076800;  
        secondstageclosingTime   = 1556668800;  
        laststageopeningTime     = 1559347200;  
        laststageclosingTime     = 1561939200;  
        
    }
    
    function burnTokens(address account, uint256 value) public onlyOwner {
        _burn(account, value);
    }
    
    function pause() public onlyOwner {
        Open = false;
    }
    
    function unPause() public onlyOwner {
        Open = true;
    }
    
     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        balances[account] = balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
    
    function () external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _beneficiary) public payable onlyWhileOpen {
        require(msg.value >= minTx);
    
        uint256 weiAmount = msg.value;
    
        _preValidatePurchase(_beneficiary, weiAmount);
        
        uint256 tokens = _getTokenAmount(weiAmount);
        
        tokens = _getBonus(tokens);
        
        fundsRaised = fundsRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(address(this), _beneficiary, weiAmount, tokens);
        purchasers++;
        if(tokens != 0){
            _forwardFunds(msg.value);
        }
        else {
            revert();
        }
    }
    
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal pure{
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }
  
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 rate = _getRate();  
        return _weiAmount.mul(rate);
    }
    
    function _getRate() internal view returns (uint256) {
        uint256 rate;
         
        if(now >= firststageopeningTime && now <= firststageclosingTime) { 
            rate = 1205;  
        } 
         
        else if (now >= secondstageopeningTime && now <= secondstageclosingTime) {
            rate = 240;  
        } 
         
        else if (now >= laststageopeningTime && now <= laststageclosingTime) {
            rate = 120;  
        }
        
        return rate;
    }
    
    function _getBonus(uint256 tokens) internal view returns (uint256) {
        if(purchasers <= 1000){
             
            tokens = tokens.add((tokens.mul(50)).div(100));
        }
        return tokens;
    }
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        _transfer(_beneficiary, _tokenAmount);
    }
        function _transfer(address to, uint tokens) internal returns (bool success) {
         
        require(to != address(0));
        require(balances[address(this)] >= tokens );
        require(balances[to] + tokens >= balances[to]);
        balances[address(this)] = balances[address(this)].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(address(this),to,tokens);
        return true;
    }

    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }
    
    function _forwardFunds(uint256 _amount) internal {
        wallet.transfer(_amount);
    }
    
}