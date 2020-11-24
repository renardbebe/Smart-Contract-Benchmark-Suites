 

pragma solidity ^0.4.18;
 
 
 
 
 
contract ERC20 {
     
    uint256 public totalSupply;
 
     
    function balanceOf(address _owner) public constant returns (uint256 balance);
 
     
    function transfer(address _to, uint256 _value) public returns (bool success);
    
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
     
    function approve(address _spender, uint256 _value) public returns (bool success);
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
  
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
     
    event TransferOfPower(address indexed _from, address indexed _to);
}
interface TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract COSAuth {
    address      public  owner;
    constructor () public {
         owner = msg.sender;
    }
    
    modifier auth {
        require(isAuthorized(msg.sender) == true);
        _;
    }
    
    function isAuthorized(address src) internal view returns (bool) {
        if(src == owner){
            return true;
        } else {
            return false;
        }
    }
}

contract COSStop is COSAuth{

    bool public stopped;

    modifier stoppable {
        require(stopped == false);
        _;
    }
    function stop() auth internal {
        stopped = true;
    }
    function start() auth internal {
        stopped = false;
    }
}

contract Freezeable is COSAuth{

     
    mapping(address => bool) _freezeList;

     
    event Freezed(address indexed freezedAddr);
    event UnFreezed(address indexed unfreezedAddr);

     
    function freeze(address addr) auth public returns (bool) {
      require(true != _freezeList[addr]);

      _freezeList[addr] = true;

      emit Freezed(addr);
      return true;
    }

    function unfreeze(address addr) auth public returns (bool) {
      require(true == _freezeList[addr]);

      _freezeList[addr] = false;

      emit UnFreezed(addr);
      return true;
    }

    modifier whenNotFreezed(address addr) {
        require(true != _freezeList[addr]);
        _;
    }

    function isFreezing(address addr) public view returns (bool) {
        if (true == _freezeList[addr]) {
            return true;
        } else {
            return false;
        }
    }
}

contract COSTokenBase is ERC20, COSStop, Freezeable{
     
    string public name;
    string public symbol;
    uint8  public decimals = 18;
     
     
     
    mapping (address => uint256) balances;
     
    mapping (address => mapping (address => uint256)) allowances;
     
    mapping (address => string)                  public  register_map;
     
    event Burn(address indexed from, uint256 value);
    event LogRegister (address indexed user, string key);
    event LogStop   ();
     
    constructor(uint256 _initialSupply, string _tokenName, string _tokenSymbol, uint8 _decimals) public {
        name = _tokenName;                                    
        symbol = _tokenSymbol;                                
        decimals = _decimals;
         
        totalSupply = _initialSupply * 10 ** uint256(decimals);   
        balances[owner] = totalSupply;                 
    }
    function balanceOf(address _owner) public view returns(uint256) {
        return balances[_owner];
    }
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }
     
    function _transfer(address _from, address _to, uint _value) whenNotFreezed(_from) internal returns(bool) {
         
        require(_to != 0x0);
         
        require(balances[_from] >= _value);
         
        require(balances[_to] + _value > balances[_to]);
         
        uint previousBalances = balances[_from] + balances[_to];
         
        balances[_from] -= _value;
         
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balances[_from] + balances[_to] == previousBalances);
        return true;
    }
     
    function transfer(address _to, uint256 _value) stoppable public returns(bool) {
        return _transfer(msg.sender, _to, _value);
    }
     
    function transferFrom(address _from, address _to, uint256 _value) stoppable public returns(bool) {
        require(_value <= allowances[_from][msg.sender]);      
        allowances[_from][msg.sender] -= _value;
        return _transfer(_from, _to, _value);
    }
     
    function approve(address _spender, uint256 _value) stoppable public returns(bool) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) stoppable public returns(bool) {
        if (approve(_spender, _value)) {
            TokenRecipient spender = TokenRecipient(_spender);
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
        return false;
    }
     
    function burn(uint256 _value) stoppable public returns(bool)  {
        require(balances[msg.sender] >= _value);    
        balances[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }
    
     
    function mint(uint256 _value) auth stoppable public returns(bool){
        require(balances[msg.sender] + _value > balances[msg.sender]);
        require(totalSupply + _value > totalSupply);
        balances[msg.sender] += _value;
        totalSupply += _value;
        return true;
    }
    
     
    function burnFrom(address _from, uint256 _value) stoppable public returns(bool) {
        require(balances[_from] >= _value);                 
        require(_value <= allowances[_from][msg.sender]);     
        balances[_from] -= _value;                          
        allowances[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
     
    function transferOfPower(address _to) auth stoppable public returns (bool) {
        require(msg.sender == owner);
        uint value = balances[msg.sender];
        _transfer(msg.sender, _to, value);
        owner = _to;
        emit TransferOfPower(msg.sender, _to);
        return true;
    }
     
    function increaseApproval(address _spender, uint _addedValue) stoppable public returns (bool) {
         
        require(allowances[msg.sender][_spender] + _addedValue > allowances[msg.sender][_spender]);
        allowances[msg.sender][_spender] += _addedValue;
        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }
    function decreaseApproval(address _spender, uint _subtractedValue) stoppable public returns (bool) {
        uint oldValue = allowances[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowances[msg.sender][_spender] = 0;
        } else {
            allowances[msg.sender][_spender] = oldValue - _subtractedValue;
        }
        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }
}
contract COSToken is COSTokenBase {
    
    constructor() COSTokenBase(10000000000, "Contentos", "COS", 18) public {
    }
    
    function finish() public{
        stop();
        emit LogStop();
    }
    
    function register(string key) public {
        require(bytes(key).length <= 64);
        require(balances[msg.sender] > 0);
        register_map[msg.sender] = key;
        emit LogRegister(msg.sender, key);
    }
}