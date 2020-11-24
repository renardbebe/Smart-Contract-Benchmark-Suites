 

pragma solidity ^0.4.18;

contract AbstractToken {
     
    function totalSupply() public constant returns (uint256) {}
    function balanceOf(address owner) public constant returns (uint256 balance);
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function allowance(address owner, address spender) public constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Issuance(address indexed to, uint256 value);
}
 
contract SafeMath {
  function mul(uint256 a, uint256 b) constant internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) constant internal returns (uint256) {
    assert(b != 0);  
    uint256 c = a / b;
    assert(a == b * c + a % b);  
    return c;
  }

  function sub(uint256 a, uint256 b) constant internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) constant internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function mulByFraction(uint256 number, uint256 numerator, uint256 denominator) internal returns (uint256) {
      return div(mul(number, numerator), denominator);
  }
}

contract PreIco is SafeMath {
     
    string public constant name = "Remechain Presale Token";
    string public constant symbol = "iRMC";
    uint public constant decimals = 18;

     
    address public manager;
    address public reserveManager;
     
    address public escrow;
    address public reserveEscrow;

     
    uint constant BASE = 1000000000000000000;

     
    uint public tokensSupplied = 0;
     
    uint public bountySupplied = 0;
     
    uint public constant SOFT_CAPACITY = 2000000 * BASE;
     
    uint public constant TOKENS_SUPPLY = 6000000 * BASE;
     
    uint public constant BOUNTY_SUPPLY = 350000 * BASE;
     
    uint public constant totalSupply = TOKENS_SUPPLY + BOUNTY_SUPPLY;

     

    uint public constant TOKEN_PRICE = 3125000000000000;
    uint tokenAmount1 = 6000000 * BASE;

    uint tokenPriceMultiply1 = 1;
    uint tokenPriceDivide1 = 1;

    uint[] public tokenPriceMultiplies;
    uint[] public tokenPriceDivides;
    uint[] public tokenAmounts;

     
    mapping(address => uint) public ethBalances;
    uint[] public prices;
    uint[] public amounts;

    mapping(address => uint) private balances;

     
    uint public constant defaultDeadline = 1519567200;
    uint public deadline = defaultDeadline;

     
    bool public isIcoStopped = false;

     
    address[] public allowedTokens;
     
    mapping(address => uint) public tokenAmount;
     
    mapping(address => uint) public tokenPrice;

     
    address[] public usersList;
    mapping(address => bool) isUserInList;
     
    uint numberOfUsersReturned = 0;

     
    mapping(address => address[]) public userTokens;
     
    mapping(address => mapping(address => uint)) public userTokensValues;

     

    event BuyTokens(address indexed _user, uint _ethValue, uint _boughtTokens);
    event BuyTokensWithTokens(address indexed _user, address indexed _token, uint _tokenValue, uint _boughtTokens);
    event GiveReward(address indexed _to, uint _value);

    event IcoStoppedManually();
    event IcoRunnedManually();

    event WithdrawEther(address indexed _escrow, uint _ethValue);
    event WithdrawToken(address indexed _escrow, address indexed _token, uint _value);
    event ReturnEthersFor(address indexed _user, uint _value);
    event ReturnTokensFor(address indexed _user, address indexed _token, uint _value);

    event AddToken(address indexed _token, uint _amount, uint _price);
    event RemoveToken(address indexed _token);

    event MoveTokens(address indexed _from, address indexed _to, uint _value);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

     

    modifier onlyManager {
        assert(msg.sender == manager || msg.sender == reserveManager);
        _;
    }
    modifier onlyManagerOrContract {
        assert(msg.sender == manager || msg.sender == reserveManager || msg.sender == address(this));
        _;
    }
    modifier IcoIsActive {
        assert(isIcoActive());
        _;
    }


     
     
     
     
     
     
    function PreIco(address _manager, address _reserveManager, address _escrow, address _reserveEscrow, uint _deadline) public {
        assert(_manager != 0x0);
        assert(_reserveManager != 0x0);
        assert(_escrow != 0x0);
        assert(_reserveEscrow != 0x0);

        manager = _manager;
        reserveManager = _reserveManager;
        escrow = _escrow;
        reserveEscrow = _reserveEscrow;

        if (_deadline != 0) {
            deadline = _deadline;
        }
        tokenPriceMultiplies.push(tokenPriceMultiply1);
        tokenPriceDivides.push(tokenPriceDivide1);
        tokenAmounts.push(tokenAmount1);
    }

     
     
    function balanceOf(address _user) public returns(uint balance) {
        return balances[_user];
    }

     
    function isIcoActive() public returns(bool isActive) {
        return !isIcoStopped && now < deadline;
    }

     
    function isIcoSuccessful() public returns(bool isSuccessful) {
        return tokensSupplied >= SOFT_CAPACITY;
    }

     
     
     
     
    function getTokensAmount(uint _amountOfToken, uint _priceAmountOfToken,  uint _value) private returns(uint tokensToBuy) {
        uint currentStep;
        uint tokensRemoved = tokensSupplied;
        for (currentStep = 0; currentStep < tokenAmounts.length; currentStep++) {
            if (tokensRemoved >= tokenAmounts[currentStep]) {
                tokensRemoved -= tokenAmounts[currentStep];
            } else {
                break;
            }
        }
        assert(currentStep < tokenAmounts.length);

        uint result = 0;

        for (; currentStep <= tokenAmounts.length; currentStep++) {
            assert(currentStep < tokenAmounts.length);

            uint tokenOnStepLeft = tokenAmounts[currentStep] - tokensRemoved;
            tokensRemoved = 0;
            uint howManyTokensCanBuy = _value
                    * _amountOfToken / _priceAmountOfToken
                    * tokenPriceDivides[currentStep] / tokenPriceMultiplies[currentStep];

            if (howManyTokensCanBuy > tokenOnStepLeft) {
                result = add(result, tokenOnStepLeft);
                uint spent = tokenOnStepLeft
                    * _priceAmountOfToken / _amountOfToken
                    * tokenPriceMultiplies[currentStep] / tokenPriceDivides[currentStep];
                if (_value <= spent) {
                    break;
                }
                _value -= spent;
                tokensRemoved = 0;
            } else {
                result = add(result, howManyTokensCanBuy);
                break;
            }
        }

        return result;
    }

     
     
    function getTokensAmountWithEth(uint _value) private returns(uint tokensToBuy) {
        return getTokensAmount(BASE, TOKEN_PRICE, _value);
    }

     
     
     
    function getTokensAmountByTokens(address _token, uint _tokenValue) private returns(uint tokensToBuy) {
        assert(tokenPrice[_token] > 0);
        return getTokensAmount(tokenPrice[_token], tokenAmount[_token], _tokenValue);
    }

     
     
     
    function buyTokens(address _user, uint _value) private IcoIsActive {
        uint boughtTokens = getTokensAmountWithEth(_value);
        burnTokens(boughtTokens);

        balances[_user] = add(balances[_user], boughtTokens);
        addUserToList(_user);
        BuyTokens(_user, _value, boughtTokens);
    }

     
     
     
     
    function addToken(address _token, uint _amount, uint _price) onlyManager public {
        assert(_token != 0x0);
        assert(_amount > 0);
        assert(_price > 0);

        bool isNewToken = true;
        for (uint i = 0; i < allowedTokens.length; i++) {
            if (allowedTokens[i] == _token) {
                isNewToken = false;
                break;
            }
        }
        if (isNewToken) {
            allowedTokens.push(_token);
        }

        tokenPrice[_token] = _price;
        tokenAmount[_token] = _amount;
    }

     
     
    function removeToken(address _token) onlyManager public {
        for (uint i = 0; i < allowedTokens.length; i++) {
            if (_token == allowedTokens[i]) {
                if (i < allowedTokens.length - 1) {
                    allowedTokens[i] = allowedTokens[allowedTokens.length - 1];
                }
                allowedTokens[allowedTokens.length - 1] = 0x0;
                allowedTokens.length--;
                break;
            }
        }

        tokenPrice[_token] = 0;
        tokenAmount[_token] = 0;
    }

     
     
    function addUserToList(address _user) private {
        if (!isUserInList[_user]) {
            isUserInList[_user] = true;
            usersList.push(_user);
        }
    }

     
     
    function burnTokens(uint _amount) private {
        assert(add(tokensSupplied, _amount) <= TOKENS_SUPPLY);
        tokensSupplied = add(tokensSupplied, _amount);
    }

     
     
    function buyWithTokens(address _token) public {
        buyWithTokensBy(msg.sender, _token);
    }

     
     
     
    function buyWithTokensBy(address _user, address _token) public IcoIsActive {
         
        assert(tokenPrice[_token] > 0);

        AbstractToken token = AbstractToken(_token);
        uint tokensToSend = token.allowance(_user, address(this));
        assert(tokensToSend > 0);

        uint boughtTokens = getTokensAmountByTokens(_token, tokensToSend);
        burnTokens(boughtTokens);
        balances[_user] = add(balances[_user], boughtTokens);

        uint prevBalance = token.balanceOf(address(this));
        assert(token.transferFrom(_user, address(this), tokensToSend));
        assert(token.balanceOf(address(this)) - prevBalance == tokensToSend);

        userTokensValues[_user][_token] = add(userTokensValues[_user][_token], tokensToSend);

        addTokenToUser(_user, _token);
        addUserToList(_user);
        BuyTokensWithTokens(_user, _token, tokensToSend, boughtTokens);
    }

     
     
     
     
     
    function addTokensToReturn(address _user, address _token, uint _tokenValue, bool _buyTokens) public onlyManager {
         
        assert(tokenPrice[_token] > 0);

        if (_buyTokens) {
            uint boughtTokens = getTokensAmountByTokens(_token, _tokenValue);
            burnTokens(boughtTokens);
            balances[_user] = add(balances[_user], boughtTokens);
            BuyTokensWithTokens(_user, _token, _tokenValue, boughtTokens);
        }

        userTokensValues[_user][_token] = add(userTokensValues[_user][_token], _tokenValue);
        addTokenToUser(_user, _token);
        addUserToList(_user);
    }


     
     
     
    function addTokenToUser(address _user, address _token) private {
        for (uint i = 0; i < userTokens[_user].length; i++) {
            if (userTokens[_user][i] == _token) {
                return;
            }
        }
        userTokens[_user].push(_token);
    }

     
    function returnFunds() public {
        assert(!isIcoSuccessful() && !isIcoActive());

        returnFundsFor(msg.sender);
    }

     
    function moveIcoTokens(address _from, address _to, uint _value) public onlyManager {
        balances[_from] = sub(balances[_from], _value);
        balances[_to] = add(balances[_to], _value);

        MoveTokens(_from, _to, _value);
    }

     
     
    function returnFundsFor(address _user) public onlyManagerOrContract returns(bool) {
        if (ethBalances[_user] > 0) {
            if (_user.send(ethBalances[_user])) {
                ReturnEthersFor(_user, ethBalances[_user]);
                ethBalances[_user] = 0;
            }
        }

        for (uint i = 0; i < userTokens[_user].length; i++) {
            address tokenAddress = userTokens[_user][i];
            uint userTokenValue = userTokensValues[_user][tokenAddress];
            if (userTokenValue > 0) {
                AbstractToken token = AbstractToken(tokenAddress);
                if (token.transfer(_user, userTokenValue)) {
                    ReturnTokensFor(_user, tokenAddress, userTokenValue);
                    userTokensValues[_user][tokenAddress] = 0;
                }
            }
        }

        balances[_user] = 0;
    }

     
     
    function returnFundsForMultiple(address[] _users) public onlyManager {
        for (uint i = 0; i < _users.length; i++) {
            returnFundsFor(_users[i]);
        }
    }

     
    function returnFundsForAll() public onlyManager {
        assert(!isIcoActive() && !isIcoSuccessful());

        uint first = numberOfUsersReturned;
        uint last  = (first + 50 < usersList.length) ? first + 50 : usersList.length;

        for (uint i = first; i < last; i++) {
            returnFundsFor(usersList[i]);
        }

        numberOfUsersReturned = last;
    }

     
     
    function withdrawEtherTo(address _escrow) private {
        assert(isIcoSuccessful());

        if (this.balance > 0) {
            if (_escrow.send(this.balance)) {
                WithdrawEther(_escrow, this.balance);
            }
        }

        for (uint i = 0; i < allowedTokens.length; i++) {
            AbstractToken token = AbstractToken(allowedTokens[i]);
            uint tokenBalance = token.balanceOf(address(this));
            if (tokenBalance > 0) {
                if (token.transfer(_escrow, tokenBalance)) {
                    WithdrawToken(_escrow, address(token), tokenBalance);
                }
            }
        }
    }

     
    function withdrawEther() public onlyManager {
        withdrawEtherTo(escrow);
    }

     
    function withdrawEtherToReserveEscrow() public onlyManager {
        withdrawEtherTo(reserveEscrow);
    }

     
    function runIco() public onlyManager {
        assert(isIcoStopped);
        isIcoStopped = false;
        IcoRunnedManually();
    }

     
    function stopIco() public onlyManager {
        isIcoStopped = true;
        IcoStoppedManually();
    }

     
    function () public payable {
        buyTokens(msg.sender, msg.value);
    }

     
     
     
    function giveReward(address _to, uint _amount) public onlyManager {
        assert(_to != 0x0);
        assert(_amount > 0);
        assert(add(bountySupplied, _amount) <= BOUNTY_SUPPLY);

        bountySupplied = add(bountySupplied, _amount);
        balances[_to] = add(balances[_to], _amount);

        GiveReward(_to, _amount);
    }

     
    function transfer(address _to, uint _value) public returns (bool success) {
        return false;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        return false;
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        return false;
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return 0;
    }
}