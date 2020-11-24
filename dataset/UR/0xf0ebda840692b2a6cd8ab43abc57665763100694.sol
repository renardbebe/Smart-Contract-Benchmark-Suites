 

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

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
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

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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
        Transfer(0x0, _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

 
contract SignalsToken is PausableToken, MintableToken {

     
    string constant public name = "SGNPresaleToken";
    string constant public symbol = "SGN";
    uint8 constant public decimals = 9;

    event TokensBurned(address initiatior, address indexed _partner, uint256 _tokens);

     
    function SignalsToken() {
        pause();
    }
     
    function burnTokens(address _partner, uint256 _tokens) public onlyOwner {
        require(balances[_partner] >= _tokens);

        balances[_partner] -= _tokens;
        totalSupply -= _tokens;
        TokensBurned(msg.sender, _partner, _tokens);
    }
}

 
contract PresaleRegister is Ownable {

    mapping (address => bool) verified;
    event ApprovedInvestor(address indexed investor);

     
    function approve(address _investor) onlyOwner public{
        verified[_investor] = true;
        ApprovedInvestor(_investor);
    }

     
    function approved(address _investor) constant public returns (bool) {
        return verified[_investor];
    }

}

 
contract Crowdsale {
    using SafeMath for uint256;

     
    SignalsToken public token;

     
    uint256 public startTime;
    uint256 public endTime;

     
    address public wallet;

     
    uint256 public weiRaised;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


    function Crowdsale(uint256 _startTime, uint256 _endTime, address _wallet, SignalsToken _tokenAddress) {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_wallet != 0x0);

        token = _tokenAddress;
        startTime = _startTime;
        endTime = _endTime;
        wallet = _wallet;
    }


     
    function () payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) private {}

     
     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

     
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

     
    function hasEnded() public constant returns (bool) {
        return now > endTime;
    }


}

 
contract FinalizableCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint256;

    bool public isFinalized = false;

    event Finalized();

     
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasEnded());

        finalization();
        Finalized();

        isFinalized = true;
    }

     
    function finalization() internal {
    }
}


 
contract PublicPresale is FinalizableCrowdsale {

     
    uint256 tokensSold;
    uint256 toBeSold;
    uint256 price;
    PresaleRegister public register;

    event PresaleExtended(uint256 newEndTime);

     
    function PublicPresale(uint256 _startTime, uint256 _endTime, address _wallet, SignalsToken _token, PresaleRegister _register)
    FinalizableCrowdsale()
    Crowdsale(_startTime, _endTime, _wallet, _token)
    {
        register = _register;
        toBeSold = 1969482*1000000000;
        price = 692981;
    }

     
    function buyTokens(address beneficiary) private {
        require(beneficiary != 0x0);
        require(validPurchase());

         
        require(register.approved(beneficiary));

        uint256 weiAmount = msg.value;

         
        uint256 toGet = howMany(msg.value);

        require((toGet > 0) && (toGet.add(tokensSold) <= toBeSold));

         
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(toGet);

        token.mint(beneficiary, toGet);
        TokenPurchase(msg.sender, beneficiary, weiAmount, toGet);

        forwardFunds();

    }

     
    function howMany(uint256 value) view public returns (uint256){
        return (value/price);
    }

     
    function finalization() internal {
        token.transferOwnership(wallet);
    }

     
    function extendDuration(uint256 _newEndTime) onlyOwner {
        require(!isFinalized);
        require(endTime < _newEndTime);
        endTime = _newEndTime;
        PresaleExtended(_newEndTime);
    }
}