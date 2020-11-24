 

pragma solidity ^0.4.18;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        assert(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        assert(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        assert(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        assert(b > 0);
        c = a / b;
        assert(a == b * c + a % b);
    }
}

contract ownable {
    address public owner;

    function ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }

    function isOwner(address _owner) internal view returns (bool) {
        return owner == _owner;
    }
}

contract Pausable is ownable {
    bool public paused = false;
    
    event Pause();
    event Unpause();
    
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    modifier whenPaused() {
        require(paused);
        _;
    }
    
    function pause() onlyOwner whenNotPaused public returns (bool success) {
        paused = true;
        Pause();
        return true;
    }
  
    function unpause() onlyOwner whenPaused public returns (bool success) {
        paused = false;
        Unpause();
        return true;
    }
}

contract Lockable is Pausable {
    mapping (address => bool) public locked;
    
    event Lockup(address indexed target);
    event UnLockup(address indexed target);
    
    function lockup(address _target) onlyOwner public returns (bool success) {
        require(!isOwner(_target));
        locked[_target] = true;
        Lockup(_target);
        return true;
    }

    function unlockup(address _target) onlyOwner public returns (bool success) {
        require(!isOwner(_target));
        delete locked[_target];
        UnLockup(_target);
        return true;
    }
    
    function isLockup(address _target) internal view returns (bool) {
        if(true == locked[_target])
            return true;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
     
    event Burn(address indexed from, uint256 value);

     
    function TokenERC20 (
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(SafeMath.add(balanceOf[_to], _value) > balanceOf[_to]);

         
        uint previousBalances = SafeMath.add(balanceOf[_from], balanceOf[_to]);
         
        balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value);
         
        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);

        Transfer(_from, _to, _value);
         
        assert(SafeMath.add(balanceOf[_from], balanceOf[_to]) == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = SafeMath.sub(allowance[_from][msg.sender], _value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);                                
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);     
        totalSupply = SafeMath.sub(totalSupply, _value);                         
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                         
        require(_value <= allowance[_from][msg.sender]);             
        balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value);   
        allowance[_from][msg.sender] = SafeMath.sub(allowance[_from][msg.sender], _value);  
        totalSupply = SafeMath.sub(totalSupply, _value);             
        Burn(_from, _value);
        return true;
    }
}

contract ValueToken is Lockable, TokenERC20 {
    uint256 public sellPrice;
    uint256 public buyPrice;
    uint256 public minAmount;
    uint256 public soldToken;

    uint internal constant MIN_ETHER        = 1*1e16;  
    uint internal constant EXCHANGE_RATE    = 10000;   

    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);
    event LogWithdrawContractToken(address indexed owner, uint value);
    event LogFallbackTracer(address indexed owner, uint value);

     
    function ValueToken (
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {
        
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                  
        require (balanceOf[_from] >= _value);                  
        require (balanceOf[_to] + _value >= balanceOf[_to]);   
        require(!frozenAccount[_from]);                        
        require(!frozenAccount[_to]);                          
        require(!isLockup(_from));
        require(!isLockup(_to));

        balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value);    
        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);        
        Transfer(_from, _to, _value);
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] = SafeMath.add(balanceOf[target], mintedAmount);
        totalSupply = SafeMath.add(totalSupply, mintedAmount);
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        require(!isOwner(target));
        require(!frozenAccount[target]);

        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function withdrawContractToken(uint _value) onlyOwner public returns (bool success) {
        _transfer(this, msg.sender, _value);
        LogWithdrawContractToken(msg.sender, _value);
        return true;
    }
    
    function getContractBalanceOf() public constant returns(uint blance) {
        blance = balanceOf[this];
    }
    
     
    function () payable public {
        require(MIN_ETHER <= msg.value);
        uint amount = msg.value;
        uint token = amount.mul(EXCHANGE_RATE);
        require(token > 0);
        _transfer(this, msg.sender, amount);
        LogFallbackTracer(msg.sender, amount);
    }
}