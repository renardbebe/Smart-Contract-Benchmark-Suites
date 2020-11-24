 

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

    mapping(address => mapping(address => uint256)) internal allowed;


     
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

contract MintableToken is PausableToken {
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

contract TokenImpl is MintableToken {
    string public name;
    string public symbol;

     
    uint256 public rate;

    uint256 public eth_decimal_num = 100000;

     
    ERC20Basic public targetToken;

    uint256 public exchangedNum;

    event Exchanged(address _owner, uint256 _value);

    function TokenImpl(string _name, string _symbol, uint256 _decimal_num) public {
        name = _name;
        symbol = _symbol;
        eth_decimal_num = _decimal_num;
        paused = true;
    }
     
    function exchange(address _exchanger, uint256 _value) internal {
        require(canExchange());
        uint256 _tokens = (_value.mul(rate)).div(eth_decimal_num);
        targetToken.transfer(_exchanger, _tokens);
        exchangedNum = exchangedNum.add(_value);
        Exchanged(_exchanger, _tokens);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (_to == address(this) || _to == owner) {
            exchange(msg.sender, _value);
        }
        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        if (_to == address(this) || _to == owner) {
            exchange(msg.sender, _value);
        }
        return super.transfer(_to, _value);
    }

    function balanceOfTarget(address _owner) public view returns (uint256 targetBalance) {
        if (targetToken != address(0)) {
            return targetToken.balanceOf(_owner);
        } else {
            return 0;
        }
    }

    function canExchangeNum() public view returns (uint256) {
        if (canExchange()) {
            uint256 _tokens = targetToken.balanceOf(this);
            return (eth_decimal_num.mul(_tokens)).div(rate);
        } else {
            return 0;
        }
    }

    function updateTargetToken(address _target, uint256 _rate) onlyOwner public {
        rate = _rate;
        targetToken = ERC20Basic(_target);
    }

    function canExchange() public view returns (bool) {
        return targetToken != address(0) && rate > 0;
    }


}

contract Crowdsale is Pausable {
    using SafeMath for uint256;

    string public projectName;

    string public tokenName;
    string public tokenSymbol;

     
    uint256 public rate;

     
    uint256 public ethRaised;
    uint256 public eth_decimal_num = 100000;

     
    uint256 public cap;

     
    TokenImpl public token;

     
    ERC20Basic public targetToken;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value);
    event IncreaseCap(uint256 cap);
    event DecreaseCap(uint256 cap);


    function Crowdsale(string _projectName, string _tokenName, string _tokenSymbol, uint256 _cap) public {
        require(_cap > 0);
        projectName = _projectName;
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        cap = _cap.mul(eth_decimal_num);
        token = createTokenContract();
    }

    function newCrowdSale(string _projectName, string _tokenName,
        string _tokenSymbol, uint256 _cap) onlyOwner public {
        require(_cap > 0);
        projectName = _projectName;
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        cap = _cap.mul(eth_decimal_num);
        ethRaised = 0;
        token.transferOwnership(owner);
        token = createTokenContract();
        rate = 0;
        targetToken = ERC20Basic(0);
    }


    function createTokenContract() internal returns (TokenImpl) {
        return new TokenImpl(tokenName, tokenSymbol, eth_decimal_num);
    }

     
    function() external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) whenNotPaused public payable {
        require(beneficiary != address(0));
        require(msg.value >= (0.00001 ether));

        uint256 ethAmount = (msg.value.mul(eth_decimal_num)).div(1 ether);

         
        ethRaised = ethRaised.add(ethAmount);
        require(ethRaised <= cap);

        token.mint(beneficiary, ethAmount);
        TokenPurchase(msg.sender, beneficiary, ethAmount);

        forwardFunds();
    }

     
     
    function forwardFunds() internal {
        owner.transfer(msg.value);
    }

     
    function increaseCap(uint256 _cap_inc) onlyOwner public {
        require(_cap_inc > 0);
        cap = cap.add(_cap_inc.mul(eth_decimal_num));
        IncreaseCap(cap);
    }

    function decreaseCap(uint256 _cap_dec) onlyOwner public {
        require(_cap_dec > 0);
        cap = cap.sub(_cap_dec.mul(eth_decimal_num));
        if (cap <= ethRaised) {
            cap = ethRaised;
        }
        DecreaseCap(cap);
    }

    function saleRatio() public view returns (uint256 ratio) {
        if (cap == 0) {
            return 0;
        } else {
            return ethRaised.mul(10000).div(cap);
        }
    }


    function balanceOf(address _owner) public view returns (uint256 balance) {
        return token.balanceOf(_owner);
    }

    function balanceOfTarget(address _owner) public view returns (uint256 targetBalance) {
        return token.balanceOfTarget(_owner);
    }

    function canExchangeNum() public view returns (uint256) {
        return token.canExchangeNum();
    }

    function updateTargetToken(address _target, uint256 _rate) onlyOwner public {
        rate = _rate;
        targetToken = ERC20Basic(_target);
        token.updateTargetToken(_target, _rate);
    }

     
    function releaseTargetToken(uint256 _value) onlyOwner public returns (bool) {
        if (targetToken != address(0)) {
            return targetToken.transfer(owner, _value);
        } else {
            return false;
        }
    }


     
    function pauseToken() onlyOwner public {
        token.pause();
    }

     
    function unpauseToken() onlyOwner public {
        token.unpause();
    }


     
    function hasEnded() public view returns (bool) {
        return ethRaised >= cap;
    }

}