 

pragma solidity ^0.4.24;

 
 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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


 
 
contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


 
 
contract ERC20Token{
     
    function totalSupply() public view returns (uint256 supply);

     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
 
contract GTLToken is ERC20Token, owned {
    using SafeMath for uint256;

     
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 _totalSupply;

     
    mapping (address => uint256) public balances;
     
    mapping (address => mapping (address => uint256)) public allowance;

     
    struct FreezeAccountInfo {
        uint256 freezeStartTime;
        uint256 freezePeriod;
        uint256 freezeTotal;
    }



     
    mapping (address => FreezeAccountInfo) public freezeAccount;

     
    event IssueAndFreeze(address indexed to, uint256 _value, uint256 _freezePeriod);

     
    constructor(string _tokenName, string _tokenSymbol, uint256 _initialSupply) public {
        _totalSupply = _initialSupply * 10 ** uint256(decimals);   
        balances[msg.sender] = _totalSupply;                 
        name = _tokenName;                                    
        symbol = _tokenSymbol;                                
    }

     
     
     
    function totalSupply() public view returns (uint256 supply) {
        return _totalSupply;
    }

     
     
     
     
    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    }

     
     
     
     
     
    function issueAndFreeze(address _to, uint _value, uint _freezePeriod) onlyOwner public {
        _transfer(msg.sender, _to, _value);

        freezeAccount[_to] = FreezeAccountInfo({
            freezeStartTime : now,
            freezePeriod : _freezePeriod,
            freezeTotal : _value
        });

        emit IssueAndFreeze(_to, _value, _freezePeriod);
    }

     
     
     
     
    function getFreezeInfo(address _target) public view returns(
        uint _freezeStartTime, 
        uint _freezePeriod, 
        uint _freezeTotal, 
        uint _freezeDeadline) {
            
        FreezeAccountInfo storage targetFreezeInfo = freezeAccount[_target];
        uint freezeDeadline = targetFreezeInfo.freezeStartTime.add(targetFreezeInfo.freezePeriod.mul(1 minutes));
        return (
            targetFreezeInfo.freezeStartTime, 
            targetFreezeInfo.freezePeriod,
            targetFreezeInfo.freezeTotal,
            freezeDeadline
        );
    }

     
     
     
     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balances[_from] >= _value);
         
        require(balances[_to].add(_value) > balances[_to]);

        uint256 freezeStartTime;
        uint256 freezePeriod;
        uint256 freezeTotal;
        uint256 freezeDeadline;

         
        (freezeStartTime,freezePeriod,freezeTotal,freezeDeadline) = getFreezeInfo(_from);

         
        uint256 freeTotalFrom = balances[_from].sub(freezeTotal);

         
         
         
        require(freezeStartTime == 0 || freezeDeadline < now || freeTotalFrom >= _value); 

         
        uint previousBalances = balances[_from].add(balances[_to]);
         
        balances[_from] = balances[_from].sub(_value);
         
        balances[_to] = balances[_to].add(_value);

         
        emit Transfer(_from, _to, _value);
         
        assert(balances[_from].add(balances[_to]) == previousBalances);
    }

     
     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

     
     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowance[_owner][_spender];
    }
}