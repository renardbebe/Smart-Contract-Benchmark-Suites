 

pragma solidity ^0.4.25;


 
library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
         
        uint c = a / b;
         
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}


 
contract ERC20Basic {
    uint public totalSupply;

    function balanceOf(address who) public view returns (uint);

    function transfer(address to, uint value) public;

    event Transfer(address indexed from, address indexed to, uint value);
}


 
contract BasicToken is ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) balances;

     
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length == size + 4, "payload size does not match");
        _;
    }

     
    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) public {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
    }

     
    function balanceOf(address _owner) public view returns (uint balance)  {
        return balances[_owner];
    }

}


 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint);

    function transferFrom(address from, address to, uint value) public;

    function approve(address spender, uint value) public;

    event Approval(address indexed owner, address indexed spender, uint value);
}


 
contract StandardToken is BasicToken, ERC20 {

    mapping(address => mapping(address => uint)) allowed;


     
    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) public {

         
         

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

     
    function approve(address _spender, uint _value) public {

         
         
         
         
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

     
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}


 
contract Ownable {
    address public owner;


     
    constructor() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call");
        _;
    }


     
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}


 

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint value);
    event MintFinished();

    bool public mintingFinished = false;
    uint public totalSupply = 0;


    modifier canMint() {
        require(!mintingFinished, "mint finished.");
        _;
    }

     
    function mint(address _to, uint _amount) onlyOwner canMint public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(0x0, _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}


 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused, "contract not paused");
        _;
    }

     
    modifier whenPaused {
        require(paused, "contract paused");
        _;
    }

     
    function pause() onlyOwner whenNotPaused public returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

     
    function unpause() onlyOwner whenPaused public returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}


 

contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint _value) whenNotPaused public {
        super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) whenNotPaused public {
        super.transferFrom(_from, _to, _value);
    }
}


 
contract TokenTimelock {

     
    ERC20Basic token;

     
    address beneficiary;

     
    uint releaseTime;

    constructor(ERC20Basic _token, address _beneficiary, uint _releaseTime) public {
        require(_releaseTime > now);
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

     
    function claim() public {
        require(msg.sender == beneficiary);
        require(now >= releaseTime);

        uint amount = token.balanceOf(this);
        require(amount > 0);

        token.transfer(beneficiary, amount);
    }
}


 
contract Token is PausableToken, MintableToken {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(
        string tokenName,
        string tokenSymbol,
        address tokenOwner,
        uint256 initialSupply,
        uint8 decimalUnits
    ) public {
         
        name = tokenName;
         
        symbol = tokenSymbol;
         
        decimals = decimalUnits;
         
        owner = tokenOwner;
         
        totalSupply = initialSupply;
        balances[tokenOwner] = initialSupply;
        emit Mint(tokenOwner, initialSupply);
        emit Transfer(0x0, tokenOwner, initialSupply);
    }

     
    function mintTimelocked(address _to, uint256 _amount, uint256 _releaseTime)
    onlyOwner canMint public returns (TokenTimelock) {

        TokenTimelock timelock = new TokenTimelock(this, _to, _releaseTime);
        mint(timelock, _amount);

        return timelock;
    }

     
    function withdrawEther(uint256 amount) onlyOwner public {
        owner.transfer(amount);
    }

     
    function() payable public {
    }

}