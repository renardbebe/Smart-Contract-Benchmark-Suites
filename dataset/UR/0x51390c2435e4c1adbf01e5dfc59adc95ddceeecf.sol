 

pragma solidity ^0.4.24;
 
library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
         
        uint c = a / b;
         
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract ERC20Basic {
    uint public totalSupply;
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) balances;

   
    function transfer(address _to, uint _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

   
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint);

    function transferFrom(address from, address to, uint value) public returns (bool);

    function approve(address spender, uint value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint value);
}


 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint)) allowed;

   
    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(_to != address(0));

        uint _allowance = allowed[_from][msg.sender];

         
        require (_value <= _allowance);
        require(_value > 0);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

   
    function approve(address _spender, uint _value) public returns (bool) {

         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

   
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

   
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

 
contract GOENTEST is StandardToken {

    string public constant name = "goentesttoken";
    string public constant symbol = "GOENTEST";
     
     
    uint public constant decimals = 18;  

    uint public constant INITIAL_SUPPLY =  10000000000 * (10 ** decimals);  

     
    constructor() public { 
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }
}

 
contract lockStorehouseToken is ERC20 {
    using SafeMath for uint;
    
    GOENTEST   tokenReward;
    
    address private beneficial;
    uint    private lockMonth;
    uint    private startTime;
    uint    private releaseSupply;
    bool    private released = false;
    uint    private per;
    uint    private releasedCount = 0;
    uint    public  limitMaxSupply;  
    uint    public  oldBalance;
    uint    private constant decimals = 18;
    
    constructor(
        address _tokenReward,
        address _beneficial,
        uint    _per,
        uint    _startTime,
        uint    _lockMonth,
        uint    _limitMaxSupply
    ) public {
        tokenReward     = GOENTEST(_tokenReward);
        beneficial      = _beneficial;
        per             = _per;
        startTime       = _startTime;
        lockMonth       = _lockMonth;
        limitMaxSupply  = _limitMaxSupply * (10 ** decimals);
        
         
         
         
         
         
         
         
    }
    
    mapping(address => uint) balances;
    
    function approve(address _spender, uint _value) public returns (bool){}
    
    function allowance(address _owner, address _spender) public view returns (uint){}
    
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(_to != address(0));
        require (_value > 0);
        require(_value <= balances[_from]);
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function getBeneficialAddress() public constant returns (address){
        return beneficial;
    }
    
    function getBalance() public constant returns(uint){
        return tokenReward.balanceOf(this);
    }
    
    modifier checkBalance {
        if(!released){
            oldBalance = getBalance();
            if(oldBalance > limitMaxSupply){
                oldBalance = limitMaxSupply;
            }
        }
        _;
    }
    
    function release() checkBalance public returns(bool) {
         
         
        uint cliffTime;
        uint monthUnit;
        
        released = true;
         
        releaseSupply = SafeMath.mul(SafeMath.div(oldBalance, 1000), per);
        
         
        if(SafeMath.mul(releasedCount, releaseSupply) <= oldBalance){
             
             
             
                
             
            
             
             
             
             
             

             
             
             
            monthUnit = SafeMath.mul(lockMonth, 30 days);
            cliffTime = SafeMath.add(startTime, monthUnit);
        
            if(now > cliffTime){
                
                tokenReward.transfer(beneficial, releaseSupply);
                
                releasedCount++;

                startTime = now;
                
                return true;
            
            }
        } else {
            return false;
        }
        
    }
    
    function () private payable {
    }
}