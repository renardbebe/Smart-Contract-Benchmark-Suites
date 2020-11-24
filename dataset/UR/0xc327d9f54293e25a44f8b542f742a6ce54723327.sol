 

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

contract Token {

     
    function totalSupply() constant returns (uint256 supply) {}
    

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}



    event Transfer(address indexed _from, address indexed _to, uint256 _value);

}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }


    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }


    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract ERC20 is StandardToken {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract Plumix is ERC20 { 

     

    using SafeMath for uint256;
    string public name;                   
    uint8 public decimals;                
    string public symbol;                 
    uint256 public unitsOneEthCanBuy;      
    uint256 public minSales;                  
    uint256 public totalEthInWei;         
    address internal fundsWallet;           
    uint256 public airDropBal;
    uint256 public icoSales;
    uint256 public icoSalesBal;
    uint256 public icoSalesCount;
    bool public distributionClosed;

    
    modifier canDistr() {
        require(!distributionClosed);
        _;
    }
    
    address owner = msg.sender;
    
     modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    
    event Airdrop(address indexed _owner, uint _amount, uint _balance);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event DistrClosed();
    event DistrStarted();
    event Burn(address indexed burner, uint256 value);
    
    
    function endDistribution() onlyOwner canDistr public returns (bool) {
        distributionClosed = true;
        emit DistrClosed();
        return true;
    }
    
    function startDistribution() onlyOwner public returns (bool) {
        distributionClosed = false;
        emit DistrStarted();
        return true;
    }
    

    function Plumix() {
        balances[msg.sender] = 10000000000e18;               
        totalSupply = 10000000000e18;                        
        airDropBal = 1500000000e18;
        icoSales = 5000000000e18;
        icoSalesBal = 5000000000e18;
        name = "Plumix";                                   
        decimals = 18;                                               
        symbol = "PLXT";                                             
        unitsOneEthCanBuy = 10000000;
        minSales = 1 ether / 100;  
        icoSalesCount = 0;
        fundsWallet = msg.sender;                                   
        distributionClosed = true;
        
    }

    function() public canDistr payable{
        totalEthInWei = totalEthInWei.add(msg.value);
        uint256 amount = msg.value.mul(unitsOneEthCanBuy);
        require(msg.value >= minSales);
        require(amount <= icoSalesBal);
        

        balances[fundsWallet] = balances[fundsWallet].sub(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);

        Transfer(fundsWallet, msg.sender, amount);  

        
        fundsWallet.transfer(msg.value);
        
        icoSalesCount = icoSalesCount.add(amount);
        icoSalesBal = icoSalesBal.sub(amount);
        if (icoSalesCount >= icoSales) {
            distributionClosed = true;
        }
    }

    function transferMul(address _to, uint256 _value) internal returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            require( _value <= airDropBal );
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            airDropBal = airDropBal.sub(_value);
            emit Transfer(msg.sender, _to, _value);
            emit Airdrop(msg.sender, _value, balances[msg.sender]);
            return true;
        } else { return false; }
    }
    
    function payAirdrop(address[] _addresses, uint256 _value) public onlyOwner {        
        for (uint i = 0; i < _addresses.length; i++) transferMul(_addresses[i], _value);
    }
 
    
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);


        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
    }
    
     
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
         
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }

}