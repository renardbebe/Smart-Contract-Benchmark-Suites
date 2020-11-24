 

 
pragma solidity ^0.4.18;


 
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

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract BasicERC20Token {
     
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balances[_from] >= _value);
         
        require(balances[_to] + _value > balances[_to]);
         
        uint previousBalances = balances[_from] + balances[_to];
         
        balances[_from] -= _value;
         
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balances[_from] + balances[_to] == previousBalances);
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
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
        require(balances[msg.sender] >= _value);    
        balances[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balances[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
}


 
contract SCCAIToken is BasicERC20Token {
    using SafeMath for uint256;
    string public name = "Source Code Chain AI Token";
    string public symbol = "SCC";
    uint public decimals = 18;

    uint public exchange = 100000;

    address public target;

    address public foundationTarget;


    bool public isStart = true;

    bool public isClose = false;

    modifier onlyOwner {
        if (target == msg.sender) {
            _;
        } else {
            revert();
        }
    }

    modifier inProgress {
        if(isStart && !isClose) {
            _;
        }else {
            revert();
        }
    }

    function SCCAIToken(address _target, address _foundationTarget) public{
        target = _target;
        foundationTarget = _foundationTarget;
        totalSupply = 10000000000 * 10 ** uint256(decimals);
        balances[target] = 2000000000 * 10 ** uint256(decimals);
        balances[foundationTarget] = 8000000000 * 10 ** uint256(decimals);
        emit Transfer(msg.sender, target, balances[target]);
        emit Transfer(msg.sender, foundationTarget, balances[foundationTarget]);
    }

    function open() public onlyOwner {
        isStart = true;
        isClose = false;
    }

    function close() public onlyOwner inProgress {
        isStart = false;
        isClose = true;
    }


    function () payable public {
        issueToken();
    }

    function issueToken() payable inProgress public{
        assert(balances[target] > 0);
        assert(msg.value >= 0.0001 ether);
        uint256 tokens = msg.value.mul(exchange);

        if (tokens > balances[target]) {
            revert();
        }

        balances[target] = balances[target].sub(tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);

        emit Transfer(target, msg.sender, tokens);

        if (!target.send(msg.value)) {
            revert();
        }

    }

}