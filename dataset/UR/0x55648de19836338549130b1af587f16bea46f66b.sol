 

pragma solidity ^0.4.18;

 
interface Token {

     
     
     

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


 

contract Pebbles is Token {

    string public constant name = "Pebbles";
    string public constant symbol = "PBL";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 33787150 * 10**18;

    uint public launched = 0;  
    address public founder = 0xa99Ab2FcC5DdFd5c1Cbe6C3D760420D2dDb63d99;  
    address public team = 0xe32A4bb42AcE38DcaAa7f23aD94c41dE0334A500;  
    address public treasury = 0xc46e5D11754129790B336d62ee90b12479af7cB5;  
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    uint256 public balanceTeam = 0;  
    uint256 public withdrawnTeam = 0;
    uint256 public balanceTreasury = 0;  

    function Pebbles() public {
        balances[founder] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] < _value) {
            return false;
        }
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
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

     
    function launch() public {
        require(msg.sender == founder);
        launched = block.timestamp;
        founder = 0x0;
    }

     
    function reserveTeam(uint256 _value) public {
        require(msg.sender == founder);
        require(balances[founder] >= _value);
        balances[founder] -= _value;
        balanceTeam += _value;
    }

     
    function reserveTreasury(uint256 _value) public {
        require(msg.sender == founder);
        require(balances[founder] >= _value);
        balances[founder] -= _value;
        balanceTreasury += _value;
    }

     
    function withdrawDeferred() public {
        require(msg.sender == team);
        require(launched != 0);
        uint yearsSinceLaunch = (block.timestamp - launched) / 1 years;
        if (yearsSinceLaunch < 5) {
            uint256 teamTokensAvailable = balanceTeam / 5 * yearsSinceLaunch;
            balances[team] += teamTokensAvailable - withdrawnTeam;
            withdrawnTeam = teamTokensAvailable;
        } else {
            balances[team] += balanceTeam - withdrawnTeam;
            balanceTeam = 0;
            withdrawnTeam = 0;
            team = 0x0;
        }
        if (block.timestamp - launched >= 90 days) {
            balances[treasury] += balanceTreasury;
            balanceTreasury = 0;
            treasury = 0x0;
        }
    }

    function() public {  
        revert();
    }

}