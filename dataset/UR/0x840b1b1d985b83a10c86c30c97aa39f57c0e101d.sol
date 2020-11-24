 

pragma solidity ^0.4.18;

contract ERC20Interface {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Yum is ERC20Interface {
    uint256 public constant INITIAL_SUPPLY = 3000000 * (10 ** uint256(decimals));
    string public constant symbol = "YUM";
    string public constant name = "YUM Token";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = INITIAL_SUPPLY;
    
     
    address constant owner = 0x045da370c3c0A1A55501F3B78Becc78a084CC488;

     
    struct Account {
         
        uint256 balance;
         
        address addr;
         
        bool enabled;
    }

     
    mapping(address => Account) accounts;
    
     
    function Yum() public {
        accounts[owner] = Account({
          addr: owner,
          balance: INITIAL_SUPPLY,
          enabled: true
        });
    }

     
    function balanceOf(address _owner) public constant returns (uint balance) {
        return accounts[_owner].balance;
    }
    
     
    function setEnabled(address _addr, bool _enabled) public {
        assert(msg.sender == owner);
        if (accounts[_addr].enabled != _enabled) {
            accounts[_addr].enabled = _enabled;
        }
    }
    
     
    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(_to != address(0));
        require(_amount <= accounts[msg.sender].balance);
         
        if (msg.sender == owner && !accounts[_to].enabled) {
            accounts[_to].enabled = true;
        }
        if (
             
            accounts[msg.sender].enabled
             
            && accounts[_to].enabled
             
            && accounts[msg.sender].balance >= _amount
             
            && _amount > 0
             
            && accounts[_to].balance + _amount > accounts[_to].balance) {
                 
                accounts[msg.sender].balance -= _amount;
                 
                accounts[_to].balance += _amount;
                Transfer(msg.sender, _to, _amount);
                return true;
        }
        return false;
    }
}