 

pragma solidity 0.5.10;

 
 
 
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

 
contract BlockmmerceICO is ERC20Interface, Owned {
  using SafeMath for uint256;
  string  public symbol; 
  string  public name;
  uint8   public decimals;
  uint256 public fundsRaised;
  address payable public wallet;
  bool    internal Open;
  
  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;
  mapping(address => uint) public pendingInvestments;
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    modifier onlyWhileOpen {
        require(Open);
        _;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
  
     
     
     
    constructor (address payable _wallet) public {
        symbol = "BLM";
        name = "Blockmmerce";
        decimals = 18;
        owner = _wallet;
        wallet = _wallet;
        Open = true;
        balances[address(this)] = totalSupply();
        emit Transfer(address(0), address(this), totalSupply());
    }
    
    function () external payable onlyWhileOpen {
         
        fundsRecord(msg.sender, msg.value);
    }
    
    function fundsRecord(address _beneficiary, uint _weiAmount) internal {
        pendingInvestments[_beneficiary] += _weiAmount;  
    }
    
    function approvedByAdmin(address _beneficiary, uint256 _weiAmount) external onlyOwner{
        require(pendingInvestments[_beneficiary] >= _weiAmount && pendingInvestments[_beneficiary] != 0);
        buyTokens(_beneficiary, _weiAmount);
    }
    
    function buyTokens(address _beneficiary, uint256 _weiAmount) internal{
         
        
        _preValidatePurchase(_beneficiary, _weiAmount);
        
        uint256 _tokens = _getTokenAmount(_weiAmount);
        
        fundsRaised = fundsRaised.add(_weiAmount);

        _processPurchase(_beneficiary, _tokens);
        
        emit TokenPurchase(address(this), _beneficiary, _weiAmount, _tokens);
        
        _forwardFunds(wallet, _weiAmount);
        
        pendingInvestments[_beneficiary] = pendingInvestments[_beneficiary].sub(_weiAmount);  
    }
    
    function rejectedByAdmin(address payable _beneficiary, uint256 _weiAmount) external onlyOwner{
         
         
        require(pendingInvestments[_beneficiary] >= _weiAmount && pendingInvestments[_beneficiary] != 0);
        _forwardFunds(_beneficiary,_weiAmount);
        
         
        pendingInvestments[_beneficiary] = pendingInvestments[_beneficiary].sub(_weiAmount);
    }
    
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) pure internal{
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }
    
    function _getTokenAmount(uint256 _weiAmount) pure internal returns (uint256) {
        uint256 rate = 1000;  
        return _weiAmount.mul(rate);
    }

    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }
    
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        _transfer(_beneficiary, _tokenAmount);
    }
    
    function _forwardFunds(address payable _wallet, uint256 _amount) internal {
        _wallet.transfer(_amount);
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
    
    function freeTokens(address receiver, uint tokenAmount) external onlyOwner {
        require(balances[address(this)] != 0);
        _transfer(receiver,tokenAmount*10**uint(decimals));
    }
    
    
    function stopICO() public onlyOwner{
        Open = false;
        if(balances[address(this)] != 0){   
            _transfer(owner,balances[address(this)]);
        }
    }
    
     
    function totalSupply() public view returns (uint){
       return 1e26;  
    }
    
     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
         
        require(to != address(0));
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

}