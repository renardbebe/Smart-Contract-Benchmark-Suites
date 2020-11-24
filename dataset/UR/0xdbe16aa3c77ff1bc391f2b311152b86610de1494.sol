 

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


 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}


 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
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

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}


 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
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

 

contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}


 

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

 
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}


 
contract IDCToken is PausableToken, MintableToken, BurnableToken {
    using SafeMath for uint256;

     
    string public name;
    string public symbol;
    uint256 public decimals;

     
    uint256 public startTime;
    uint256 public endTime;

     
    uint256 public rate;

     
    uint256 public weiRaised;

     
    uint256 public tokenSelled;

     
     
    address public creator;

     
    address public wallet;

     
    mapping(address => address) whiteList;

     
    mapping(address => uint256) tokensBuyed;

     
    uint256 public capPerAddress;

    event SellTokens(address indexed recipient, uint sellTokens, uint payEther, uint ratio);

     
    function IDCToken (
        string    _tokenName,
        string    _tokenSymbol,
        uint256   _tokenDecimals,
        uint256   _startTime,
        uint256   _endTime,
        uint256   _totalSupply,
        uint256   _rate,
        uint256   _capPerAddress,
        address   _wallet
    ) public {

         
        require(_endTime >= _startTime);
        require(_startTime >= now);
        require(_totalSupply > 0);
        require(_capPerAddress > 0);
        require(_wallet != address(0));

        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _tokenDecimals;
        startTime = _startTime;
        endTime = _endTime;
        totalSupply = _totalSupply;
        rate = _rate;
        capPerAddress = _capPerAddress;
        wallet = _wallet;

         
        balances[msg.sender] = totalSupply;
        creator = msg.sender;
    }

     
    function addWhiteList(address user) public onlyOwner {
        require(user != address(0));

         
        whiteList[user] = user;
    }

     
    function checkExist(address user) public view returns(bool) {
        return(whiteList[user] == user);
    }

     
    function () external payable whenNotPaused preSaleActive {
        sellTokens();
    }

     
    function sellTokens() public payable whenNotPaused preSaleActive {

        require(msg.value > 0);
         
        require(checkExist(msg.sender) == true);

        uint256 amount = msg.value;
        uint256 tokens =  calculateTokenAmount(amount);

         
        require(tokensBuyed[msg.sender].add(tokens) <= calculateTokenAmount(capPerAddress));
         
        require(tokens <= balances[creator]);

         
         
        tokensBuyed[msg.sender] = tokensBuyed[msg.sender].add(tokens);

        tokenSelled = tokenSelled.add(tokens);
        weiRaised = weiRaised.add(amount);

         
         
         
        balances[creator] = balances[creator].sub(tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);

        Transfer(creator, msg.sender, tokens);
        SellTokens(msg.sender, tokens, amount, rate);

        forwardFunds();
    }

     
     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

     
    modifier preSaleActive() {
        require(now >= startTime);
        require(now <= endTime);
        _;
    }

     
    function timeNow() public view returns(uint256) {
        return now;
    }

     
    function calculateTokenAmount(uint256 amount) public constant returns(uint256) {
        return amount.mul(rate);
    }
}