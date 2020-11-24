 

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

contract SSTXCOIN {
    
    using SafeMath for uint256;

    string public name      = "Speed Shopper Token";                                     
    string public symbol    = "SSTX";                                                    
    uint256 public decimals = 18;                                                        
    uint256 private _totalSupply = 500000000;                                            
    uint256 public totalSupply  = _totalSupply.mul(10 ** uint256(decimals));             
    
    
     
    mapping (address => uint256) public balances;
    
     
    mapping (address => mapping (address => uint256)) public allowance;


     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    constructor() public {
        balances[0xa6052FB9334942A7e3B21c55f95af973B6b12918] = totalSupply;
    }
    
     
    function transfer(address _to, uint256 _value) public  returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value);
        require(balances[_to].add(_value) >= balances[_to]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
     
    function balanceOf(address _address) public view returns (uint256 balance) {
         
        return balances[_address];
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success) {
        require(_from != address(0) && _to != address(0));
        require(balances[_from] >= _value);
        require(balances[_to].add(_value) >= balances[_to]);
        require(allowance[_from][msg.sender] >= _value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
     
    function approve(address _spender, uint256 _value) public  returns (bool success) {
        require(_spender != address(0));
        require(_value <= balances[msg.sender]);
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


}

contract SpeedShopper is SSTXCOIN {
    
    using SafeMath for uint256;
    
     
    
     
    bool public stopped = false;
    uint public minEth  = 0.2 ether;

     
    address public owner;
    
     
    address public wallet;
    
     
    uint256 public tokenPerEth = 2500;
    
     
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

     
    constructor() public {
        
        wallet = 0xa6052FB9334942A7e3B21c55f95af973B6b12918;
        owner = 0xa6052FB9334942A7e3B21c55f95af973B6b12918;
    }
    
    function() payable public   {
         
        revert();
    }

     
    function participate() payable public isRunning validAddress  {
        
         
        require(msg.value > minEth);
         
        require(now >= ico.icoStartDate && now <= ico.icoEndDate );

         
        uint tokens = msg.value * tokenPerEth;
         
        uint bonus  = ( tokens.mul(ico.icoBonus) ).div(100);
         
        uint total  = tokens + bonus;

         
        require(ico.icoFund >= total);
         
        require(balanceOf(address(this)) >= total);
        
         
        require(balanceOf(msg.sender).add(total) >= balanceOf(msg.sender));
        
         
        ico.icoFund      = ico.icoFund.sub(total);
        ico.icoSold      = ico.icoSold.add(total);
        
         
      
        transfer(msg.sender, total);
        
         
        wallet.transfer( msg.value );
        
    }
    
     
    function setStage(uint256 _stage, uint256 _startDate, uint256 _endDate, uint256 _fund, uint256 _bonus) external isOwner returns(bool) {
        
         
         
         
         
         
        require(now < _startDate);
         
        require(_startDate < _endDate);
         
        require(balanceOf(msg.sender) >= _fund);
        
         
        uint tokens = _fund;
        
         
        ico.icoStage        = _stage;
        ico.icoStartDate    = _startDate;
        ico.icoEndDate      = _endDate;
        ico.icoFund         = tokens;
        ico.icoBonus        = _bonus;
        ico.icoSold         = 0;
        
         
         
        
        transferFrom(msg.sender, address(this), tokens);
        
        return true;
    }
    
     
    function setWithdrawalWallet(address _newWallet) external isOwner {
        
         
        require( _newWallet != wallet );
         
        require( _newWallet != address(0) );
        
         
        wallet = _newWallet;
        
    }

     
    function withdrawTokens(address _address, uint256 _value) external isOwner validAddress {
        
         
        require(_address != address(0) && _address != address(this));
        
         
        uint256 tokens = _value * 10 ** uint256(18);
        
         
        require(balanceOf(address(this)) > tokens);
        
         
        require(balanceOf(_address) < balanceOf(_address).add(tokens));
        
         
        transfer(_address, tokens);
        
    }
    
     
    function pauseICO() external isOwner isRunning {
        stopped = true;
    }
    
     
    function resumeICO() external isOwner isStopped {
        stopped = false;
    }
    
}