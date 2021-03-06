 

pragma solidity >=0.4.17;

contract Migrations {
    address public owner;

    event TransferOwnership(address oldaddr, address newaddr);

    modifier onlyOwner() { require(msg.sender == owner); _; }

    function Migrations() public {
        owner = msg.sender;
    }

    function transferOwnership(address _new) onlyOwner public {
        address oldaddr = owner;
        owner = _new;
        emit TransferOwnership(oldaddr, owner);
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






interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract BezantERC20Base {
    using SafeMath for uint256;

         
                       string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function BezantERC20Base(string tokenName) public {
        uint256 initialSupply = 1000000000;
         
        totalSupply = initialSupply.mul(1 ether);   
        balanceOf[msg.sender] = totalSupply;                     
        name = tokenName;                                        
        symbol = 'BZNT';                                    
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
         
        uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);
         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);             
        totalSupply = totalSupply.sub(_value);                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] = balanceOf[_from].sub(_value);                          
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);              
        totalSupply = totalSupply.sub(_value);                               
        emit Burn(_from, _value);
        return true;
    }
}

contract BezantToken is Migrations, BezantERC20Base {

    bool public isUseContractFreeze;

    address public managementContractAddress;

    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);

    function BezantToken(string tokenName) BezantERC20Base(tokenName) onlyOwner public {}

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    function freezeAccountForOwner(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function setManagementContractAddress(bool _isUse, address _from) onlyOwner public {
        isUseContractFreeze = _isUse;
        managementContractAddress = _from;
    }

    function freezeAccountForContract(address target, bool freeze) public {
        require(isUseContractFreeze);
        require(managementContractAddress == msg.sender);
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
}