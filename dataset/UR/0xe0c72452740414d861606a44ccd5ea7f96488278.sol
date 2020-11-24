 

pragma solidity ^0.4.10;

 
 
 
 
 
 
 
 
 

 
 
 
contract TokenConfig {
    string public constant symbol = "ETT";
    string public constant name = "EncryptoTel Token";
    uint8 public constant decimals = 8;   
    uint256 public constant TOTALSUPPLY = 7766398700000000;
}


 
 
 
 
contract ERC20Interface {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) 
        returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant 
        returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, 
        uint256 _value);
}


 
 
 
contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() {
        if (msg.sender != newOwner) throw;
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


 
 
 
contract WavesEthereumSwap is Owned, ERC20Interface {
    event WavesTransfer(address indexed _from, string wavesAddress,
        uint256 amount);

    function moveToWaves(string wavesAddress, uint256 amount) {
        if (!transfer(owner, amount)) throw;
        WavesTransfer(msg.sender, wavesAddress, amount);
    }
}


 
 
 
 
contract EncryptoTelToken is TokenConfig, WavesEthereumSwap {

     
     
     
    mapping(address => uint256) balances;

     
     
     
    mapping(address => mapping (address => uint256)) allowed;

     
     
     
    function EncryptoTelToken() Owned() TokenConfig() {
        totalSupply = TOTALSUPPLY;
        balances[owner] = TOTALSUPPLY;
    }

     
     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
    function transfer(
        address _to, 
        uint256 _amount
    ) returns (bool success) {
        if (balances[msg.sender] >= _amount              
            && _amount > 0                               
            && balances[_to] + _amount > balances[_to]   
        ) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
     
    function approve(
        address _spender,
        uint256 _amount
    ) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success) {
        if (balances[_from] >= _amount                   
            && allowed[_from][msg.sender] >= _amount     
            && _amount > 0                               
            && balances[_to] + _amount > balances[_to]   
        ) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
    function allowance(
        address _owner, 
        address _spender
    ) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
    function transferAnyERC20Token(
        address tokenAddress, 
        uint256 amount
    ) onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, amount);
    }
    
     
     
     
    function () {
        throw;
    }
}