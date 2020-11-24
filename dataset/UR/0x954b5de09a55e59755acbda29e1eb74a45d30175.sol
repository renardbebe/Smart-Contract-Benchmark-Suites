 

pragma solidity ^0.4.19;

 
interface Token {

     
     
     

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


 

contract Fluz is Token {

    string public constant name = "FluzFluz";
    string public constant symbol = "FLUZ";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 204780000 * 10**18;

    uint public launched = 0;  
    address public founder = 0x81D5ce5Bf1F4F0a576De11Fd9631e789D72c9BdE;  
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    
    bool public transfersAreLocked = true;

    function Fluz() public {
        balances[founder] = totalSupply;
    }
    
     
    modifier canTransfer() {
        require(msg.sender == founder || !transfersAreLocked);
        _;
    }
    
     
    modifier onlyFounder() {
        require(msg.sender == founder);
        _;
    }

     
    function transfer(address _to, uint256 _value) public canTransfer returns (bool success) {
        if (balances[msg.sender] < _value) {
            return false;
        }
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public canTransfer returns (bool success) {
        if (balances[_from] < _value || allowed[_from][msg.sender] < _value) {
            return false;
        }
        allowed[_from][msg.sender] -= _value;
        balances[_from] -= _value;
        balances[_to] += _value;
        Transfer(_from, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function launch() public onlyFounder {
        launched = block.timestamp;
        founder = 0x0;
    }
    
     
    function changeTransferLock(bool locked) public onlyFounder {
        transfersAreLocked = locked;
    }

    function() public {  
        revert();
    }

}