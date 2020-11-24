 

pragma solidity ^0.4.24;

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 
library SafeERC20 {
    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }
}

 
contract OraclizeInterface {
  function getEthPrice() public view returns (uint256);
}

 
contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private balances;

  mapping (address => mapping (address => uint256)) private allowed;

  uint256 private totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

   
  function allowance( address _owner, address _spender ) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function transferFrom( address _from, address _to, uint256 _value ) public returns (bool) {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function increaseApproval( address _spender, uint256 _addedValue ) public returns (bool) {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval( address _spender, uint256 _subtractedValue ) public returns (bool) {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function _mint(address _account, uint256 _amount) internal {
    require(_account != 0);
    totalSupply_ = totalSupply_.add(_amount);
    balances[_account] = balances[_account].add(_amount);
    emit Transfer(address(0), _account, _amount);
  }

   
  function _burn(address _account, uint256 _amount) internal {
    require(_account != 0);
    require(_amount <= balances[_account]);

    totalSupply_ = totalSupply_.sub(_amount);
    balances[_account] = balances[_account].sub(_amount);
    emit Transfer(_account, address(0), _amount);
  }

   
  function _burnFrom(address _account, uint256 _amount) internal {
    require(_amount <= allowed[_account][msg.sender]);

     
     
    allowed[_account][msg.sender] = allowed[_account][msg.sender].sub(_amount);
    _burn(_account, _amount);
  }
}

 
contract BurnableToken is StandardToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

   
  function burnFrom(address _from, uint256 _value) public {
    _burnFrom(_from, _value);
  }

   
  function _burn(address _who, uint256 _value) internal {
    super._burn(_who, _value);
    emit Burn(_who, _value);
  }
}

 
contract EVOAIToken is BurnableToken {
    string public constant name = "EVOAI";
    string public constant symbol = "EVOT";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 10000000 * 1 ether;  

     
    constructor() public {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}

 
contract Crowdsale is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for EVOAIToken;

    struct State {
        string roundName;
        uint256 round;     
        uint256 tokens;    
        uint256 rate;      
    }

    State public state;
    EVOAIToken public token;
    OraclizeInterface public oraclize;

    bool public open;
    address public fundsWallet;
    uint256 public weiRaised;
    uint256 public usdRaised;
    uint256 public privateSaleMinContrAmount = 1000;    
    uint256 public privateSaleMaxContrAmount = 10000;   

     
    event TokensPurchased(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    event RoundStarts(uint256 timestamp, string round);

     
    constructor(address _tokenColdWallet, address _fundsWallet, address _oraclize) public {
        token = new EVOAIToken();
        oraclize = OraclizeInterface(_oraclize);
        open = false;
        fundsWallet = _fundsWallet;
        state.roundName = "Crowdsale doesnt started yet";
        token.safeTransfer(_tokenColdWallet, 3200000 * 1 ether);
    }

     
     
     

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

         
        uint256 usdAmount = _getEthToUsdPrice(weiAmount);

        if(state.round == 1) {
            _validateUSDAmount(usdAmount);
        }

         
        uint256 tokens = _getTokenAmount(usdAmount);

        assert(tokens <= state.tokens);

        usdAmount = usdAmount.div(100);  

         
        state.tokens = state.tokens.sub(tokens);
        weiRaised = weiRaised.add(weiAmount);
        usdRaised = usdRaised.add(usdAmount);

        _processPurchase(_beneficiary, tokens);

        emit TokensPurchased(
        msg.sender,
        _beneficiary,
        weiAmount,
        tokens
        );

        _forwardFunds();
    }

    function changeFundsWallet(address _newFundsWallet) public onlyOwner {
        require(_newFundsWallet != address(0));
        fundsWallet = _newFundsWallet;
    }

    function burnUnsoldTokens() public onlyOwner {
        require(state.round > 8, "Crowdsale does not finished yet");

        uint256 unsoldTokens = token.balanceOf(this);
        token.burn(unsoldTokens);
    }

    function changeRound() public onlyOwner {
        if(state.round == 0) {
            state = State("Private sale", 1, 300000 * 1 ether, 35);
            emit RoundStarts(now, "Private sale starts.");
        } else if(state.round == 1) {
            state = State("Pre sale", 2, 500000 * 1 ether, 45);
            emit RoundStarts(now, "Pre sale starts.");
        } else if(state.round == 2) {
            state = State("1st round", 3, 1000000 * 1 ether, 55);
            emit RoundStarts(now, "1st round starts.");
        } else if(state.round == 3) {
            state = State("2nd round",4, 1000000 * 1 ether, 65);
            emit RoundStarts(now, "2nd round starts.");
        } else if(state.round == 4) {
            state = State("3th round",5, 1000000 * 1 ether, 75);
            emit RoundStarts(now, "3th round starts.");
        } else if(state.round == 5) {
            state = State("4th round",6, 1000000 * 1 ether, 85);
            emit RoundStarts(now, "4th round starts.");
        } else if(state.round == 6) {
            state = State("5th round",7, 1000000 * 1 ether, 95);
            emit RoundStarts(now, "5th round starts.");
        } else if(state.round == 7) {
            state = State("6th round",8, 1000000 * 1 ether, 105);
            emit RoundStarts(now, "6th round starts.");
        } else if(state.round >= 8) {
            state = State("Crowdsale finished!",9, 0, 0);
            emit RoundStarts(now, "Crowdsale finished!");
        }
    }

    function endCrowdsale() external onlyOwner {
        open = false;
    }

    function startCrowdsale() external onlyOwner {
        open = true;
    }

     
     
     

     
    function _preValidatePurchase( address _beneficiary, uint256 _weiAmount ) internal view {
        require(open);
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

     
    function _validateUSDAmount( uint256 _usdAmount) internal view {
        require(_usdAmount.div(100) > privateSaleMinContrAmount);
        require(_usdAmount.div(100) < privateSaleMaxContrAmount);
    }

     
    function _getEthToUsdPrice(uint256 _weiAmount) internal view returns(uint256) {
        return _weiAmount.mul(_getEthUsdPrice()).div(1 ether);
    }

     
    function _getEthUsdPrice() internal view returns (uint256) {
        return oraclize.getEthPrice();
    }

     
    function _deliverTokens( address _beneficiary, uint256 _tokenAmount ) internal {
        token.safeTransfer(_beneficiary, _tokenAmount);
    }

     
    function _processPurchase( address _beneficiary, uint256 _tokenAmount ) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

     
    function _getTokenAmount(uint256 _usdAmount) internal view returns (uint256) {
        return _usdAmount.div(state.rate).mul(1 ether);
    }

     
    function _forwardFunds() internal {
        fundsWallet.transfer(msg.value);
    }
}