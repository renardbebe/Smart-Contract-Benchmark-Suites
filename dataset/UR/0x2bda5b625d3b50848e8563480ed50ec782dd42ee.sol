 

pragma solidity ^0.4.21;

 
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

contract owned {

    address public owner;

    function owned() public {
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

contract saleOwned is owned{
    mapping (address => bool) public saleContract;

    modifier onlySaleOwner {        
        require(msg.sender == owner || true == saleContract[msg.sender]);
        _;
    }

    function addSaleOwner(address saleOwner) onlyOwner public {
        saleContract[saleOwner] = true;
    }

    function delSaleOwner(address saleOwner) onlyOwner public {
        saleContract[saleOwner] = false;
    }
}

 
contract Pausable is saleOwned {
    event Pause();
    event Unpause();

    bool public paused = false;


   
    modifier whenNotPaused() {
        require(false == paused);
        _;
    }

   
    modifier whenPaused {
        require(true == paused);
        _;
    }

   
    function pause() onlyOwner whenNotPaused public returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

   
    function unpause() onlyOwner whenPaused public returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}

 
 
 
contract BaseToken is Pausable{
    using SafeMath for uint256;    
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256))  approvals;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event TransferFrom(address indexed approval, address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint value);

    function BaseToken (
        string tokenName,
        string tokenSymbol
    ) public {
        decimals = 18;
        name = tokenName;
        symbol = tokenSymbol;
    }    
    
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);
        require (balanceOf[_from] >= _value);
        require (balanceOf[_to] + _value > balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) whenNotPaused public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) whenNotPaused public returns (bool) {
        assert(balanceOf[_from] >= _value);
        assert(approvals[_from][msg.sender] >= _value);
        
        approvals[_from][msg.sender] = approvals[_from][msg.sender].sub(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }

    function allowance(address src, address guy) public view returns (uint256) {
        return approvals[src][guy];
    }

    function approve(address guy, uint256 _value) public returns (bool) {
        approvals[msg.sender][guy] = _value;
        
        emit Approval(msg.sender, guy, _value);
        
        return true;
    }
}

 
 
 
contract AdvanceToken is BaseToken {
    string tokenName        = "BetEncore";        
    string tokenSymbol      = "BTEN";             

    struct frozenStruct {
        uint startTime;
        uint endTime;
    }
    
    mapping (address => bool) public frozenAccount;
    mapping (address => frozenStruct) public frozenTime;

    event FrozenFunds(address target, bool frozen, uint startTime, uint endTime);    
    event Burn(address indexed from, uint256 value);
    
    function AdvanceToken() BaseToken(tokenName, tokenSymbol) public {}
    
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (balanceOf[_to] + _value > balanceOf[_to]);  
        require(false == isFrozen(_from));                   
        if(saleContract[_from] == false)                     
            require(false == isFrozen(_to));                 
        balanceOf[_from] = balanceOf[_from].sub(_value);     
        balanceOf[_to] = balanceOf[_to].add(_value);         

        emit Transfer(_from, _to, _value);
    }    

    function mintToken(uint256 mintedAmount) onlyOwner public {
        uint256 mintSupply = mintedAmount.mul(10 ** uint256(decimals));
        balanceOf[msg.sender] = balanceOf[msg.sender].add(mintSupply);
        totalSupply = totalSupply.add(mintSupply);
        emit Transfer(0, this, mintSupply);
        emit Transfer(this, msg.sender, mintSupply);
    }

    function isFrozen(address target) public view returns (bool success) {        
        if(false == frozenAccount[target])
            return false;

        if(frozenTime[target].startTime <= now && now <= frozenTime[target].endTime)
            return true;
        
        return false;
    }

    function freezeAccount(address target, bool freeze, uint startTime, uint endTime) onlySaleOwner public {
        frozenAccount[target] = freeze;
        frozenTime[target].startTime = startTime;
        frozenTime[target].endTime = endTime;
        emit FrozenFunds(target, freeze, startTime, endTime);
    }

    function burn(uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[_from] >= _value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_from, _value);
        return true;
    }
}