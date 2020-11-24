 

pragma solidity ^0.4.15;
 

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
}
 
contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) allowed;
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        uint256 _allowance = allowed[_from][msg.sender];
         
         
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
     
    function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract UnikoinGold is StandardToken {

     
    string public constant name = "UnikoinGold";
    string public constant symbol = "UKG";
    uint8 public constant decimals = 18;
    string public version = "1.0";

    uint256 public constant EXP_18 = 18;
    uint256 public constant TOTAL_COMMUNITY_ALLOCATION = 200 * (10**6) * 10**EXP_18;   
    uint256 public constant UKG_FUND = 800 * (10**6) * 10**EXP_18;                     
    uint256 public constant TOTAL_TOKENS = 1000 * (10**6) * 10**EXP_18;                

    event CreateUKGEvent(address indexed _to, uint256 _value);   

    function UnikoinGold(address _tokenDistributionContract, address _ukgFund){
        require(_tokenDistributionContract != 0);   
        require(_ukgFund != 0);                     
        require(TOTAL_TOKENS == TOTAL_COMMUNITY_ALLOCATION.add(UKG_FUND));   

        totalSupply = TOTAL_COMMUNITY_ALLOCATION.add(UKG_FUND);   

        balances[_tokenDistributionContract] = TOTAL_COMMUNITY_ALLOCATION;        
        Transfer(0x0, _tokenDistributionContract, TOTAL_COMMUNITY_ALLOCATION);    
        CreateUKGEvent(_tokenDistributionContract, TOTAL_COMMUNITY_ALLOCATION);   

        balances[_ukgFund] = UKG_FUND;        
        Transfer(0x0, _ukgFund, UKG_FUND);    
        CreateUKGEvent(_ukgFund, UKG_FUND);   
    }
}