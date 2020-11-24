 

pragma solidity ^0.5.12;

contract TigReceiver {
    function tokenFallback(address from, uint tokens, bytes32 data) public view;
}

contract Tig {

     
     

    string public constant symbol       = 'TIG';
    string public constant name         = 'TIG';
    uint8 public constant decimals      = 18;
    uint public constant _totalSupply   = 50000000 * 10**uint(decimals);
    address public owner;
    string public webAddress;

     
    mapping(address => uint256) balances;

     
    mapping(address => mapping(address => uint256)) allowed;

    constructor() public {
        balances[msg.sender]    = _totalSupply;
        owner                   = msg.sender;
        webAddress              = "https://hellotig.com";
    }

     
    function totalSupply() public pure returns (uint) {
        return _totalSupply;
    }

     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
     
    function isContractAdrs(address to) private view returns (bool is_contract_adrs) {
        uint length;
        assembly {
            length := extcodesize(to)
        }
        return (length > 0);
    } 
    
     
    function transfer(address to, uint tokens, bytes32 data) public returns (bool success) {
        if(isContractAdrs(to)) {
            return transferToContract(to, tokens, data);
        } else {
            return transferToAddress(to, tokens);
        }
    }
    
     
    function transfer(address to, uint tokens) public returns (bool success) {
        bytes32 empty;
        if(isContractAdrs(to)) {
            return transferToContract(to, tokens, empty);
        } else {
            return transferToAddress(to, tokens);
        }
    }
    
     
    function transferToContract(address to, uint tokens, bytes32 data) private returns (bool success) {
        require( balances[msg.sender] >= tokens && tokens > 0 );
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        TigReceiver receiver = TigReceiver(to);
        receiver.tokenFallback(msg.sender, tokens, data);
        emit Transfer(msg.sender, to, tokens, data);
        return true;
    }
    
     
    function transferToAddress(address to, uint tokens) private returns (bool success) {
        require( balances[msg.sender] >= tokens && tokens > 0 );
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require( allowed[from][msg.sender] >= tokens && balances[from] >= tokens && tokens > 0 );
        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }

     
    function approve(address sender, uint256 tokens) public returns (bool success) {
        allowed[msg.sender][sender] = tokens;
        emit Approval(msg.sender, sender, tokens);
        return true;
    }

     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    
     
    event Transfer(address indexed _from, address indexed _to, uint256 _amount, bytes32 data);
     
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _to, uint256 _amount);
}