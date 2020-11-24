 

pragma solidity ^0.4.24;
contract OWN 
{
    address public owner;
    address internal newOwner;
    constructor() 
    public
    payable
    {
        owner = msg.sender;
    }
    
    modifier onlyOwner 
    {
        require(owner == msg.sender);
        _;
    }
    function changeOwner(address _owner)
    onlyOwner 
    public
    {
        require(_owner != 0);
        newOwner = _owner;
    }
    function confirmOwner()
    public 
     { 
        require(newOwner == msg.sender);
        owner = newOwner;
        delete newOwner;
    }
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
    uint256 c = a / b;
    return c;
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
contract ERC20 
{
    string  public constant name     = "DRIVER ETHEREUM";
    string  public constant symbol   = "DRETH";
    uint8   public constant decimals =  6;
    uint256 public  totalSupply;  
    
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    mapping (address => mapping(address => uint256)) public allowance;
    mapping (address => uint256) public balanceOf;
    function balanceOf(address who)
    public constant
    returns (uint)
    {
        return balanceOf[who];
    }
    function approve(address _spender, uint _value)
    public
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
    function allowance(address _owner, address _spender) 
    public constant 
    returns (uint remaining) 
    {
        return allowance[_owner][_spender];
    }
    modifier onlyPayloadSize(uint size) 
    {
        require(msg.data.length >= size + 4);
        _;
    }
}
contract DRIVER is OWN, ERC20
{
    using SafeMath for uint256;
    
    uint256 public   Price = 800000000;  
    uint256 internal Minn  = 10000000000000000;  
    uint256 internal Maxx  = 10000000000000000000;  
    uint256 internal Bank;  

    function () 
    payable public 
    {
        require(msg.value>0);
        require(msg.value >= Minn);
        require(msg.value <= Maxx);
        mintTokens(msg.sender, msg.value);
    }

    function mintTokens(address _who, uint256 _value) 
    internal 
        {
        require(_value >= Minn);
        require(_value <= Maxx);
        uint256 tokens = _value / (Price*10/8);  
        require(tokens > 0); 
        require(balanceOf[_who] + tokens > balanceOf[_who]);
        totalSupply += tokens;  
        balanceOf[_who] += tokens;  
        uint256 perc = _value.div(100);
        Bank += perc.mul(87);   
        Price = Bank.div(totalSupply);  
        uint256 minus = _value % (Price*10/8);  
        require(minus > 0);
        chart_call();  
        emit Transfer(this, _who, tokens);
        _value=0; tokens=0;
        owner.transfer(perc.mul(6));  
        _who.transfer(minus);  
        minus=0; 
    }    

    mapping (uint256 => uint256) public chartPrice; 
    mapping (uint256 => uint256) public chartVolume; 
    uint256 public BlockTime=0; 
    function chart_call() 
    internal
    {
        uint256 cm = (now.div(1800)); 
        if(cm > BlockTime)
        { 
            BlockTime = cm;
            chartPrice[BlockTime]  = Price;
            chartVolume[BlockTime] = totalSupply;
        }
    }
    function transfer (address _to, uint _value) 
    public onlyPayloadSize(2 * 32) 
    returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);
        if(_to != address(this))  
        { 
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);  
        }
        else  
        {
        balanceOf[msg.sender] -= _value;
        uint256 change = _value.mul(Price);
        require(address(this).balance >= change);
		if(totalSupply > _value){
        uint256 plus = ( address(this).balance - Bank ).div(totalSupply);    
        Bank -= change; 
        totalSupply -= _value;
        Bank += (plus.mul(_value));  
        Price = Bank.div(totalSupply);  
        chart_call();
        emit Transfer(msg.sender, _to, _value);
        }
        if(totalSupply == _value){  
        Price = address(this).balance/totalSupply;
        Price = (Price.mul(102)).div(100);  
        totalSupply=0;
        Bank=0;
        chart_call();
        emit Transfer(msg.sender, _to, _value);
        owner.transfer(address(this).balance - change);
        }
        msg.sender.transfer(change);
        }
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) 
    public onlyPayloadSize(3 * 32)
    returns (bool success)
    {
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        if(_to != address(this))   
        {
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        }
        else  
        {
        balanceOf[_from] -= _value;
        uint256 change = _value.mul(Price);
        require(address(this).balance >= change);
        if(totalSupply > _value){ 
        uint256 plus = ( address(this).balance - Bank ).div(totalSupply);    
        Bank -= change; 
        totalSupply -= _value;
        Bank += (plus.mul(_value));  
        Price = Bank.div(totalSupply);  
        chart_call();
        emit Transfer(_from, _to, _value);
        allowance[_from][msg.sender] -= _value;
        }
        if(totalSupply == _value){  
        Price = address(this).balance/totalSupply;
        Price = (Price.mul(102)).div(100);  
        totalSupply=0; 
        Bank=0; 
        chart_call();
        emit Transfer(_from, _to, _value);
        allowance[_from][msg.sender] -= _value;
        owner.transfer(address(this).balance - change);
        }
        _from.transfer(change);
        }
        return true;
    }
    function money() 
    public view 
    returns (uint) 
    {
        return address(this).balance;
    }
}