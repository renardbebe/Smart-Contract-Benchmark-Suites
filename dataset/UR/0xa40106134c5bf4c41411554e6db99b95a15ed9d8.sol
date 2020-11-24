 

pragma solidity ^0.4.20;


 
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
    function totalSupply() public view returns (uint256);
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

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
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


contract MintableToken is StandardToken, Ownable, Pausable {

    event Mint(address indexed to, uint256 amount);

    event MintFinished();

    bool public mintingFinished = false;

    uint256 public maxTokensToMint = 25000000 ether;

    uint8 public currentRound = 1;

    struct Round {
    uint256 total;
    bool finished;
    bool active;
    uint256 issuedTokens;
    uint256 startMinimumTime;
    }

    Round[] rounds;

    modifier canMint() {
        require(!mintingFinished);
        require(rounds[currentRound-1].active);
        _;
    }

     
    function mint(address _to, uint256 _amount) whenNotPaused onlyOwner returns (bool) {
        require(mintInternal(_to, _amount));
        return true;
    }

     
    function finishMinting() whenNotPaused onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    function mintInternal(address _to, uint256 _amount) internal canMint returns (bool) {
        require(rounds[currentRound-1].issuedTokens.add(_amount) <= rounds[currentRound-1].total);
        require(totalSupply_.add(_amount) <= maxTokensToMint);
        totalSupply_ = totalSupply_.add(_amount);
        rounds[currentRound-1].issuedTokens = rounds[currentRound-1].issuedTokens.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }
}


contract Rock is MintableToken {

    string public constant name = "Rocket Token";

    string public constant symbol = "ROCK";

    bool public transferEnabled = false;

    uint8 public constant decimals = 18;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 amount);

    function Rock(){
        Round memory roundone = Round({total : 4170000 ether, active: true, finished: false, issuedTokens : 0, startMinimumTime: 0});
        Round memory roundtwo = Round({total : 6945000 ether, active: false, finished: false, issuedTokens : 0, startMinimumTime: 1534291200 });
        Round memory roundthree = Round({total : 13885000 ether, active: false, finished: false, issuedTokens : 0, startMinimumTime: 0});
        rounds.push(roundone);
        rounds.push(roundtwo);
        rounds.push(roundthree);
    }

     
    function transfer(address _to, uint _value) whenNotPaused canTransfer returns (bool) {
        require(_to != address(this));
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint _value) whenNotPaused canTransfer returns (bool) {
        require(_to != address(this));
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

     
    function finishRound() onlyOwner returns (bool) {
        require(currentRound - 1 < 3);
        require(rounds[currentRound-1].active);

        uint256 tokensToBurn = rounds[currentRound-1].total.sub(rounds[currentRound-1].issuedTokens);

        rounds[currentRound-1].active = false;
        rounds[currentRound-1].finished = true;
        maxTokensToMint = maxTokensToMint.sub(tokensToBurn);

        return true;
    }

     
    function startRound() onlyOwner returns (bool) {
        require(currentRound - 1 < 2);
        require(rounds[currentRound-1].finished);
        if(rounds[currentRound].startMinimumTime > 0){
            require(block.timestamp >= rounds[currentRound].startMinimumTime);
        }

        currentRound ++;
        rounds[currentRound-1].active = true;

        return true;
    }

    function getCurrentRoundTotal() constant returns (uint256 total) {
        return rounds[currentRound-1].total;
    }

    function getCurrentRoundIsFinished() constant returns (bool) {
        return rounds[currentRound-1].finished;
    }

    function getCurrentRoundIsActive() constant returns (bool) {
        return rounds[currentRound-1].active;
    }

    function getCurrentRoundMinimumTime() constant returns (uint256) {
        return rounds[currentRound-1].startMinimumTime;
    }

    function getCurrentRoundIssued() constant returns (uint256 issued) {
        return rounds[currentRound-1].issuedTokens;
    }

}