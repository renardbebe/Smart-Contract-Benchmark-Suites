 

pragma solidity 0.4.23;
 
 
 
 
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


 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint tokens, address token, bytes data) public;
}

 
 
 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
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

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
 
 
 
contract ERC20 is ERC20Interface{
    using SafeMath for uint; 

     
     
     
    uint internal supply;
    mapping (address => uint) internal balances;
    mapping (address => mapping (address => uint)) internal allowed;

     
     
     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  


     
     
     
    constructor(uint _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) 
    public {
        balances[msg.sender] = _initialAmount;                
        supply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
        emit Transfer(address(0), msg.sender, _initialAmount);     
    }


     
     
     
     
    function transfer(address _to, uint _amount) 
    public 
    returns (bool success) {
        require(_to != address(0));          
        require(_to != address(this));
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint _amount) 
    public 
    returns (bool success) {
        require(_to != address(0)); 
        require(_to != address(this)); 
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

     
     
     
     
    function approve(address _spender, uint _amount) 
    public 
    returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }


     
     
     
     
    function approveAndCall(address _spender, uint _amount, bytes _data) 
    public 
    returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _amount, this, _data);
        return true;
    }

     
     
     
     
    function burn(uint _amount) 
    public 
    returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        supply = supply.sub(_amount);
        emit LogBurn(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
        return true;
    }

     
     
     
     
    function burnFrom(address _from, uint _amount) 
    public 
    returns (bool success) {
        balances[_from] = balances[_from].sub(_amount);                          
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);              
        supply = supply.sub(_amount);                               
        emit LogBurn(_from, _amount);
        emit Transfer(_from, address(0), _amount);
        return true;
    }

     
     
     
    function totalSupply()
    public 
    view 
    returns (uint tokenSupply) { 
        return supply; 
    }

     
     
     
    function balanceOf(address _tokenHolder) 
    public 
    view 
    returns (uint balance) {
        return balances[_tokenHolder];
    }

     
     
     
    function allowance(address _tokenHolder, address _spender) 
    public 
    view 
    returns (uint remaining) {
        return allowed[_tokenHolder][_spender];
    }


     
     
     
     
    function () 
    public 
    payable {
        revert();
    }

     
     
     
    event LogBurn(address indexed _burner, uint indexed _amountBurned); 
}

 
 
 
 
 
 
contract TokenSwap { 
  using SafeMath for uint256; 


   
   
   
  address public oldTokenAddress;
  ERC20 public newToken; 

   
   
   
  uint256 public scalingFactor = 36;           
  uint256 public tenDecimalPlaces = 10**10; 


   
   
   
  uint256 public oldCirculatingSupply;       


   
   
   
  uint256 public totalSupply = 18000000000000000 * tenDecimalPlaces;       
  uint256 public circulatingSupply = 10123464384447336 * tenDecimalPlaces;    
  uint256 public foundationSupply = totalSupply - circulatingSupply;       

   
   
   
  uint256 public tokensRedeemed = 0;     


   
   
   
  constructor(address _myBitFoundation, address _oldTokenAddress)
  public { 
    oldTokenAddress = _oldTokenAddress; 
    oldCirculatingSupply = ERC20Interface(oldTokenAddress).totalSupply(); 
    assert ((circulatingSupply.div(oldCirculatingSupply.mul(tenDecimalPlaces))) == scalingFactor);
    assert (oldCirculatingSupply.mul(scalingFactor.mul(tenDecimalPlaces)) == circulatingSupply); 
    newToken = new ERC20(totalSupply, "MyBit", 18, "MYB"); 
    newToken.transfer(_myBitFoundation, foundationSupply);
  }

   
   
   
   
  function swap(uint256 _amount) 
  public 
  noMint
  returns (bool){ 
    require(ERC20Interface(oldTokenAddress).transferFrom(msg.sender, this, _amount));
    uint256 newTokenAmount = _amount.mul(scalingFactor).mul(tenDecimalPlaces);    
    assert(tokensRedeemed.add(newTokenAmount) <= circulatingSupply);        
    tokensRedeemed = tokensRedeemed.add(newTokenAmount);
    require(newToken.transfer(msg.sender, newTokenAmount));
    emit LogTokenSwap(msg.sender, _amount, block.timestamp);
    return true;
  }

   
   
   
   
  function receiveApproval(address _from, uint256 _amount, address _token, bytes _data)
  public 
  noMint
  returns (bool){ 
    require(_token == oldTokenAddress);
    require(ERC20Interface(oldTokenAddress).transferFrom(_from, this, _amount));
    uint256 newTokenAmount = _amount.mul(scalingFactor).mul(tenDecimalPlaces);    
    assert(tokensRedeemed.add(newTokenAmount) <= circulatingSupply);     
    tokensRedeemed = tokensRedeemed.add(newTokenAmount);
    require(newToken.transfer(_from, newTokenAmount));
    emit LogTokenSwap(_from, _amount, block.timestamp);
    return true;
  }

   
   
   
  event LogTokenSwap(address indexed _sender, uint256 indexed _amount, uint256 indexed _timestamp); 


   
   
   


   
   
   
   
  modifier noMint { 
    require(oldCirculatingSupply == ERC20Interface(oldTokenAddress).totalSupply());
    _;
  }

}