 

pragma solidity ^0.4.11;

 
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

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        var _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) returns (bool) {

         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
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

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

contract MintableToken is StandardToken, Ownable, Pausable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;
    uint256 public constant maxTokensToMint = 100000000 ether;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _amount) whenNotPaused onlyOwner returns (bool) {
        return mintInternal(_to, _amount);
    }

     
    function finishMinting() whenNotPaused onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    function mintInternal(address _to, uint256 _amount) internal canMint returns (bool) {
        require(totalSupply.add(_amount) <= maxTokensToMint);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(this, _to, _amount);
        return true;
    }
}

contract WaBi is MintableToken {

    string public constant name = "WaBi";

    string public constant symbol = "WaBi";

    bool public transferEnabled = false;

    uint8 public constant decimals = 18;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 amount);


     
    function transfer(address _to, uint _value) whenNotPaused canTransfer returns (bool) {
	require(_to != address(this) && _to != address(0));
        return super.transfer(_to, _value);
    }
    
      
    function transferFrom(address _from, address _to, uint _value) whenNotPaused canTransfer returns (bool) {
	require(_to != address(this) && _to != address(0));
        return super.transferFrom(_from, _to, _value);
    }

     
    function approve(address _spender, uint256 _value) whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

     
    modifier canTransfer() {
        require(transferEnabled);
        _;
    }

     
    function enableTransfer() onlyOwner returns (bool) {
        transferEnabled = true;
        return true;
    }

}