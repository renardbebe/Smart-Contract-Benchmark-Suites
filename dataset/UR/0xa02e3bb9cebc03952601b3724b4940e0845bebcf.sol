 

pragma solidity ^0.4.18;

 
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
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

         
         

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
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

     
    function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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
        Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

contract BethereumToken is MintableToken, PausableToken {
    string public constant name = "Bethereum";
    string public constant symbol = "BTHR";
    uint256 public constant decimals = 18;

    function BethereumToken(){
        pause();
    }

}

 
contract Crowdsale {
    using SafeMath for uint256;

     
    MintableToken public token;

     
    uint256 public startTime;
    uint256 public endTime;

     
    address public wallet;

     
    uint256 public weiRaised;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


    function Crowdsale(uint256 _endTime, address _wallet) {

        require(_endTime >= now);
        require(_wallet != 0x0);

        token = createTokenContract();
        endTime = _endTime;
        wallet = _wallet;
    }

     
     
    function createTokenContract() internal returns (BethereumToken) {
        return new BethereumToken();
    }


     
    function () payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public payable {  }

     
     
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
    
    bool public weiCapReached = false;

    event Finalized();

     
    function finalize() onlyOwner public {
        require(!isFinalized);
        
        finalization();
        Finalized();

        isFinalized = true;
    }

     
    function finalization() internal {
    }
}

contract BTHRTokenSale is FinalizableCrowdsale {
    using SafeMath for uint256;

     
    uint public constant RATE = 17500;
    uint public constant TOKEN_SALE_LIMIT = 25000 * 1000000000000000000;

    uint256 public constant TOKENS_FOR_OPERATIONS = 400000000*(10**18);
    uint256 public constant TOKENS_FOR_SALE = 600000000*(10**18);

    uint public constant TOKENS_FOR_PRESALE = 315000000*(1 ether / 1 wei);

    uint public constant FRST_CRWDSALE_RATIO = TOKENS_FOR_PRESALE + 147875000*(1 ether / 1 wei); 
    uint public constant SCND_CRWDSALE_RATIO = FRST_CRWDSALE_RATIO + 110687500*(1 ether / 1 wei); 

    enum Phase {
        Created, 
        PresaleRunning,  
        Paused,  
        ICORunning,  
        FinishingICO  
    }

    Phase public currentPhase = Phase.Created;

    event LogPhaseSwitch(Phase phase);

     
    function BTHRTokenSale(uint256 _end, address _wallet)
    FinalizableCrowdsale()
    Crowdsale(_end, _wallet) {
    }

     
    function buyTokens(address _buyer) public payable {
         
        require((currentPhase == Phase.PresaleRunning) || (currentPhase == Phase.ICORunning));
        require(_buyer != address(0));
        require(msg.value > 0);
        require(validPurchase());

        uint tokensWouldAddTo = 0;
        uint weiWouldAddTo = 0;
        
        uint256 weiAmount = msg.value;
        
        uint newTokens = msg.value.mul(RATE);
        
        weiWouldAddTo = weiRaised.add(weiAmount);
        
        require(weiWouldAddTo <= TOKEN_SALE_LIMIT);

        newTokens = addBonusTokens(token.totalSupply(), newTokens);
        
        tokensWouldAddTo = newTokens.add(token.totalSupply());
        require(tokensWouldAddTo <= TOKENS_FOR_SALE);
        
        token.mint(_buyer, newTokens);
        TokenPurchase(msg.sender, _buyer, weiAmount, newTokens);
        
        weiRaised = weiWouldAddTo;
        forwardFunds();
        if (weiRaised == TOKENS_FOR_SALE){
            weiCapReached = true;
        }
    }

     
     
     
    function addBonusTokens(uint256 _totalSupply, uint256 _newTokens) internal view returns (uint256) {

        uint returnTokens = 0;
        uint tokensToAdd = 0;
        uint tokensLeft = _newTokens;

        if(currentPhase == Phase.PresaleRunning){
            if(_totalSupply < TOKENS_FOR_PRESALE){
                if(_totalSupply + tokensLeft + tokensLeft.mul(50).div(100) > TOKENS_FOR_PRESALE){
                    tokensToAdd = TOKENS_FOR_PRESALE.sub(_totalSupply);
                    tokensToAdd = tokensToAdd.mul(100).div(150);
                    
                    returnTokens = returnTokens.add(tokensToAdd);
                    returnTokens = returnTokens.add(tokensToAdd.mul(50).div(100));
                    tokensLeft = tokensLeft.sub(tokensToAdd);
                    _totalSupply = _totalSupply.add(tokensToAdd.add(tokensToAdd.mul(50).div(100)));
                } else { 
                    returnTokens = returnTokens.add(tokensLeft).add(tokensLeft.mul(50).div(100));
                    tokensLeft = tokensLeft.sub(tokensLeft);
                }
            }
        } 
        
        if (tokensLeft > 0 && _totalSupply < FRST_CRWDSALE_RATIO) {
            
            if(_totalSupply + tokensLeft + tokensLeft.mul(30).div(100)> FRST_CRWDSALE_RATIO){
                tokensToAdd = FRST_CRWDSALE_RATIO.sub(_totalSupply);
                tokensToAdd = tokensToAdd.mul(100).div(130);
                returnTokens = returnTokens.add(tokensToAdd).add(tokensToAdd.mul(30).div(100));
                tokensLeft = tokensLeft.sub(tokensToAdd);
                _totalSupply = _totalSupply.add(tokensToAdd.add(tokensToAdd.mul(30).div(100)));
                
            } else { 
                returnTokens = returnTokens.add(tokensLeft);
                returnTokens = returnTokens.add(tokensLeft.mul(30).div(100));
                tokensLeft = tokensLeft.sub(tokensLeft);
            }
        }
        
        if (tokensLeft > 0 && _totalSupply < SCND_CRWDSALE_RATIO) {
            
            if(_totalSupply + tokensLeft + tokensLeft.mul(15).div(100) > SCND_CRWDSALE_RATIO){

                tokensToAdd = SCND_CRWDSALE_RATIO.sub(_totalSupply);
                tokensToAdd = tokensToAdd.mul(100).div(115);
                returnTokens = returnTokens.add(tokensToAdd).add(tokensToAdd.mul(15).div(100));
                tokensLeft = tokensLeft.sub(tokensToAdd);
                _totalSupply = _totalSupply.add(tokensToAdd.add(tokensToAdd.mul(15).div(100)));
            } else { 
                returnTokens = returnTokens.add(tokensLeft);
                returnTokens = returnTokens.add(tokensLeft.mul(15).div(100));
                tokensLeft = tokensLeft.sub(tokensLeft);
            }
        }
        
        if (tokensLeft > 0)  {
            returnTokens = returnTokens.add(tokensLeft);
            tokensLeft = tokensLeft.sub(tokensLeft);
        }
        return returnTokens;
    }

    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        bool isRunning = ((currentPhase == Phase.ICORunning) || (currentPhase == Phase.PresaleRunning));
        return withinPeriod && nonZeroPurchase && isRunning;
    }

    function setSalePhase(Phase _nextPhase) public onlyOwner {
    
        bool canSwitchPhase
        =  (currentPhase == Phase.Created && _nextPhase == Phase.PresaleRunning)
        || (currentPhase == Phase.PresaleRunning && _nextPhase == Phase.Paused)
        || ((currentPhase == Phase.PresaleRunning || currentPhase == Phase.Paused)
        && _nextPhase == Phase.ICORunning)
        || (currentPhase == Phase.ICORunning && _nextPhase == Phase.Paused)
        || (currentPhase == Phase.Paused && _nextPhase == Phase.PresaleRunning)
        || (currentPhase == Phase.Paused && _nextPhase == Phase.FinishingICO)
        || (currentPhase == Phase.ICORunning && _nextPhase == Phase.FinishingICO);

        require(canSwitchPhase);
        currentPhase = _nextPhase;
        LogPhaseSwitch(_nextPhase);
    }

     
    function finalization() internal {
        uint256 toMint = TOKENS_FOR_OPERATIONS;
        token.mint(wallet, toMint);
        token.finishMinting();
        token.transferOwnership(wallet);
    }
}