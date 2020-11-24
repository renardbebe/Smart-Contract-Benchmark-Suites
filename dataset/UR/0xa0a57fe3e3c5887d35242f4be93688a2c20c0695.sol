 

pragma solidity ^0.4.16;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Token {
    uint256 public totalSupply;

    function balanceOf(address who) public constant returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public constant returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is Token {
    using SafeMath for uint256;
    mapping (address => mapping (address => uint256)) internal allowed;

    mapping (address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        }
        else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

 
contract Ownable {
    address public owner;


     
    function Ownable() {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

}

 
contract Pausable is Ownable {
    event Pause();

    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

     
    function unpause() onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}

contract Razoom is StandardToken, Pausable {
    using SafeMath for uint256;

    string public constant name = "RAZOOM PreToken";

    string public constant symbol = "RZMP";

    uint256 public constant decimals = 18;

    uint256 public constant tokenCreationCap = 10000000 * 10 ** decimals;

    address public multiSigWallet;

     
    uint public oneTokenInWei = 350000000000000;

    event CreateRZM(address indexed _to, uint256 _value);

    function Razoom(address multisig) {
        owner = msg.sender;
        multiSigWallet = multisig;
        balances[0x4E68FA0ca21cf33Db77edCdb7B0da15F26Bd6722] = 5000000 * 10 ** decimals;
        totalSupply = 5000000 * 10 ** decimals;
    }

    function() payable {
        createTokens();
    }

    function createTokens() internal whenNotPaused {
        if (msg.value <= 0) revert();

        uint multiplier = 10 ** decimals;
        uint256 tokens = msg.value.mul(multiplier) / oneTokenInWei;

        uint256 checkedSupply = totalSupply.add(tokens);
        if (tokenCreationCap < checkedSupply) revert();

        balances[msg.sender] += tokens;
        totalSupply = totalSupply.add(tokens);
    }

    function withdraw() external onlyOwner {
        multiSigWallet.transfer(this.balance);
    }

    function setEthPrice(uint _tokenPrice) onlyOwner {
        oneTokenInWei = _tokenPrice;
    }

    function replaceMultisig(address newMultisig) onlyOwner {
        multiSigWallet = newMultisig;
    }

}