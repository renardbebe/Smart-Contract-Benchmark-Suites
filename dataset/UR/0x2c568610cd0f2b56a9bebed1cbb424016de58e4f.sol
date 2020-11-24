 

pragma solidity 0.4.24;

 
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

contract TIZACOIN {
    
    using SafeMath for uint256;

    string public name      = "TIZACOIN";                                    
    string public symbol    = "TIZA";                                        
    uint256 public decimals = 18;                                            
    uint256 public totalSupply  = 50000000 * (10 ** uint256(decimals));      

     
    mapping (address => uint256) public balances;
    
     
    mapping (address => mapping (address => uint256)) public allowance;

     
    bool public stopped = false;

     
    address public owner;
    
     
    address public wallet = 0xAFe8D7B071298DD6170b94dcC5B5822Bf4f94980;
    
     
    uint256 public tokenPerEth = 5000;

     
    struct icoData {
        uint256 icoStage;
        uint256 icoStartDate;
        uint256 icoEndDate;
        uint256 icoFund;
        uint256 icoBonus;
        uint256 icoSold;
    }
    
     
    icoData public ico;

     
    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }

     
    modifier isRunning {
        assert (!stopped);
        _;
    }

     
    modifier isStopped {
        assert (stopped);
        _;
    }

     
    modifier validAddress {
        assert(0x0 != msg.sender);
        _;
    }

     
    constructor(address _owner) public {
        require( _owner != address(0), "Invalid owner address." );
        owner = _owner;
        balances[owner] = totalSupply;
        emit Transfer(0x0, owner, totalSupply);
    }
    
     
    function balanceOf(address _address) public view returns (uint256 balance) {
         
        return balances[_address];
    }

     
    function transfer(address _to, uint256 _value) public isRunning validAddress returns (bool success) {
        require(_to != address(0), "Invalid receive address.");
        require(balances[msg.sender] >= _value, "Insufficient amount.");
        require(balances[_to].add(_value) >= balances[_to], "Invalid token input.");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public isRunning validAddress returns (bool success) {
        require(_from != address(0) && _to != address(0), "Invalid address.");
        require(balances[_from] >= _value, "Insufficient balance.");
        require(balances[_to].add(_value) >= balances[_to], "Invalid token input.");
        require(allowance[_from][msg.sender] >= _value, "Allowed amount less then token amount.");
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
     
    function approve(address _spender, uint256 _value) public isRunning validAddress returns (bool success) {
        require(_spender != address(0), "Invalid address.");
        require(_value <= balances[msg.sender], "Insufficient balance.");
        require(_value == 0 || allowance[msg.sender][_spender] == 0, "Invalid token input.");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function setStage(uint256 _stage, uint256 _startDate, uint256 _endDate, uint256 _fund, uint256 _bonus) external isOwner returns(bool) {
        
         
        require(now < _startDate, "ICO Start time must be greater then current time.");
         
        require(now > ico.icoEndDate, "ICO end time must be greater then current time.");
         
        require(_stage > ico.icoStage, "Invalid stage number.");
         
        require(_startDate < _endDate, "End time must be greater then start time.");
         
        require(balances[msg.sender] >= _fund, "Insufficient amount to set stage.");
        
         
        uint tokens = _fund * (10 ** uint256(decimals));
        
         
        ico.icoStage        = _stage;
        ico.icoStartDate    = _startDate;
        ico.icoEndDate      = _endDate;
        ico.icoFund         = tokens;
        ico.icoBonus        = _bonus;
        ico.icoSold         = 0;
        
         
        transfer( address(this), tokens );
        
        return true;
    }
    
     
    function setWithdrawalWallet(address _newWallet) external isOwner {
        
         
        require( _newWallet != wallet, "New wallet address can not be same as old address." );
         
        require( _newWallet != address(0), "New wallet address can not be empty." );
        
         
        wallet = _newWallet;
        
    }

     
    function() payable public isRunning validAddress  {
        
         
        require(now >= ico.icoStartDate && now <= ico.icoEndDate, "ICO not active." );

         
        uint tokens = msg.value * tokenPerEth;
         
        uint bonus  = ( tokens.mul(ico.icoBonus) ).div(100);
         
        uint total  = tokens + bonus;

         
        require(ico.icoFund >= total, "ICO doesn't have sufficient balance.");
         
        require(balances[address(this)] >= total, "Contact doesn't have sufficient balance.");
         
        require(balances[msg.sender].add(total) >= balances[msg.sender], "Invalid token input.");
        
         
        ico.icoFund      = ico.icoFund.sub(total);
        ico.icoSold      = ico.icoSold.add(total);
        
         
        _sendTokens(address(this), msg.sender, total);
        
         
        wallet.transfer( msg.value );
        
    }
    
     
    function withdrawTokens(address _address, uint256 _value) external isOwner validAddress {
        
         
        require(_address != address(0) && _address != address(this), "Withdrawal address is not valid.");
        
         
        uint256 tokens = _value * 10 ** uint256(decimals);
        
         
        require(balances[address(this)] > tokens, "Contact doesn't have sufficient balance.");
        
         
        require(balances[_address] < balances[_address].add(tokens), "Invalid token input.");
        
         
        _sendTokens(address(this), _address, tokens);
        
    }
    
    function _sendTokens(address _from, address _to, uint256 _tokens) internal {
        
          
        balances[_from] = balances[_from].sub(_tokens);
         
        balances[_to] = balances[_to].add(_tokens);
         
        emit Transfer(_from, _to, _tokens);
        
    }

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}