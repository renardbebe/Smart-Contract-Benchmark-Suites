 

pragma solidity ^0.5.2;


 


library ToAddress {
    function toAddr(uint _source) internal pure returns(address payable) {
        return address(_source);
    }

    function toAddr(bytes memory _source) internal pure returns(address payable addr) {
         
        assembly { addr := mload(add(_source,0x14)) }
        return addr;
    }

    function isNotContract(address addr) internal view returns(bool) {
         
        uint256 length;
        assembly { length := extcodesize(addr) }
        return length == 0;
    }
}


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);  
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


 
 
 
 
contract ERC20Interface {
    function tokensOwner() public view returns (uint256);
    function contracBalance() public view returns (uint256);
    function balanceOf(address _tokenOwner) public view returns (uint256 balanceOwner);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event EtherTransfer(address indexed from, address indexed to, uint256 etherAmount);
}


 
 
 
contract ERC20 is ERC20Interface {
    using SafeMath for uint;
    using ToAddress for *;

    string constant public symbol = "URA";
    string constant public  name = "URA market coin";
    uint8 constant internal decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) balances;


     
     
     
    function contracBalance() public view returns (uint256 contractBalance) {
        contractBalance = address(this).balance;
    }


     
     
     
    function balanceOf(address _tokenOwner) public view returns (uint256 balanceOwner) {
        return balances[_tokenOwner];
    }


     
     
     
    function tokensOwner() public view returns (uint256 tokens) {
        tokens = balances[msg.sender];
    }

}


 
 
 
contract Dividend is ERC20 {

    uint8 public constant dividendsCosts = 10;  
    uint16 public constant day = 6000;
    uint256 public dividendes;  

    mapping(address => uint256) bookKeeper;


    event SendOnDividend(address indexed customerAddress, uint256 dividendesAmount);
    event WithdrawDividendes(address indexed customerAddress, uint256 dividendesAmount);

    constructor() public {}


     
     
     
    function withdrawDividendes() external payable returns(bool success) {
        require(msg.sender.isNotContract(),
                "the contract can not hold tokens");

        uint256 _tokensOwner = balanceOf(msg.sender);

        require(_tokensOwner > 0, "cannot pass 0 value");
        require(bookKeeper[msg.sender] > 0,
                "to withdraw dividends, please wait");

        uint256 _dividendesAmount = dividendesCalc(_tokensOwner);

        require(_dividendesAmount > 0, "dividendes amount > 0");

        bookKeeper[msg.sender] = block.number;
        dividendes = dividendes.sub(_dividendesAmount);

        msg.sender.transfer(_dividendesAmount);

        emit WithdrawDividendes(msg.sender, _dividendesAmount);

        return true;
    }


     
     
     
    function dividendesOf(address _owner)
        public
        view
        returns(uint256 dividendesAmount) {
        uint256 _tokens = balanceOf(_owner);

        dividendesAmount = dividendesCalc(_tokens);
    }


     
     
     
    function onDividendes(uint256 _value, uint8 _dividendsCosts)
        internal
        pure
        returns(uint256 forDividendes) {
        return _value.mul(_dividendsCosts).div(100);
    }


     
     
     
     
     
     
     
    function dividendesCalc(uint256 _tokensAmount)
        internal
        view
        returns(uint256 dividendesReceived) {
        if (_tokensAmount == 0) {
            return 0;
        }

        uint256 _tokens = _tokensAmount.mul(10e18);
        uint256 _dividendesPercent = dividendesPercent(_tokens);  

        dividendesReceived = dividendes.mul(_dividendesPercent).div(100);
        dividendesReceived = dividendesReceived.div(10e18);
    }


     
     
     
     
     
    function dividendesPercent(uint256 _tokens)
        internal
        view
        returns(uint256 percent) {
        if (_tokens == 0) {
            return 0;
        }

        uint256 _interest = accumulatedInterest();

        if (_interest > 100) {
            _interest = 100;
        }

        percent = _tokens.mul(_interest).div(totalSupply);
    }


     
     
     
    function accumulatedInterest() private view returns(uint256 interest) {
        if (bookKeeper[msg.sender] == 0) {
            interest = 0;
        } else {
            interest = block.number.sub(bookKeeper[msg.sender]).div(day);
        }
    }

}


 
 
 
contract URA is ERC20, Dividend {

     
    uint128 constant tokenPriceInit = 0.00000000001 ether;
    uint128 public constant limiter = 15 ether;

    uint8 public constant advertisingCosts = 5;  
    uint8 public constant forReferralCosts = 2;  
    uint8 public constant forWithdrawCosts = 3;  

     
    address payable constant advertising = 0x4d332E1f9d55d9B89dc2a8457B693Beaa7b36b2e;


    event WithdrawTokens(address indexed customerAddress, uint256 ethereumWithdrawn);
    event ReverseAccess(uint256 etherAmount);
    event ForReferral(uint256 etherAmount);


     
     
     
    constructor() public { }


     
     
     
     
     
     
     
     
     
    function () external payable {
        require(msg.sender.isNotContract(),
                "the contract can not hold tokens");

        address payable _referralAddress = msg.data.toAddr();
        uint256 _incomingEthereum = msg.value;

        uint256 _forReferral;
        uint256 _reverseAccessOfLimiter;

        if (_incomingEthereum > limiter) {
            _reverseAccessOfLimiter = _incomingEthereum.sub(limiter);
            _incomingEthereum = limiter;
        }

        uint256 _aTokenPrice = tokenPrice();
        uint256 _dividendesOwner = dividendesOf(msg.sender);
        uint256 _forAdvertising = _incomingEthereum.mul(advertisingCosts).div(100);
        uint256 _forDividendes = onDividendes(_incomingEthereum, dividendsCosts);

        if (_referralAddress != address(0)) {
            _forReferral = _incomingEthereum.mul(forReferralCosts).div(100);
            _forAdvertising = _forAdvertising.sub(_forReferral);
        }

        _incomingEthereum = _incomingEthereum.sub(
            _forDividendes
        ).sub(
            _forAdvertising
        ).sub(
            _forReferral
        );

        require(_incomingEthereum >= _aTokenPrice,
                "the amount of ether is not enough");

        (uint256 _amountOfTokens,
         uint256 _reverseAccess) = ethereumToTokens(_incomingEthereum, _aTokenPrice);

        advertising.transfer(_forAdvertising);

        _reverseAccessOfLimiter = _reverseAccessOfLimiter.add(_reverseAccess);

        if (_reverseAccessOfLimiter > 0) {
             
            msg.sender.transfer(_reverseAccessOfLimiter);
            emit ReverseAccess(_reverseAccessOfLimiter);
        }
        if (_forReferral > 0 && _referralAddress != address(0)) {
            _referralAddress.transfer(_forReferral);
            emit ForReferral(_forReferral);
        }
        if (_dividendesOwner > _aTokenPrice) {
            reinvest();
        }

        bookKeeper[msg.sender] = block.number;
        balances[msg.sender] = balances[msg.sender].add(_amountOfTokens);
        totalSupply = totalSupply.add(_amountOfTokens);
        dividendes = dividendes.add(_forDividendes);

        emit EtherTransfer(msg.sender, advertising, _forAdvertising);
        emit Transfer(address(0), msg.sender, _amountOfTokens);
        emit SendOnDividend(msg.sender, _forDividendes);
    }


     
     
     
     
     
    function tokenPrice() public view returns(uint256 priceForToken) {
        uint256 _contracBalance = contracBalance();

        if (totalSupply == 0 || _contracBalance == 0) {
            return tokenPriceInit;
        }

        return _contracBalance.div(totalSupply).mul(4).div(3);
    }


     
     
     
     
     
     
     
     
     
    function withdraw(uint256 _valueTokens) external payable returns(bool success) {
        require(msg.sender.isNotContract(),
                "the contract can not hold tokens");

        uint256 _tokensOwner = balanceOf(msg.sender);

        require(_valueTokens > 0, "cannot pass 0 value");
        require(_tokensOwner >= _valueTokens,
                "you do not have so many tokens");

        uint256 _aTokenPrice = tokenPrice();
        uint256 _etherForTokens = tokensToEthereum(_valueTokens, _aTokenPrice);
        uint256 _contracBalance = contracBalance();
        uint256 _forDividendes = onDividendes(_etherForTokens, forWithdrawCosts);
        uint256 _dividendesAmount = dividendesCalc(_tokensOwner);

        _etherForTokens = _etherForTokens.sub(_forDividendes);
        totalSupply = totalSupply.sub(_valueTokens);

        if (_dividendesAmount > 0) {
            dividendes = dividendes.sub(_dividendesAmount);
            _etherForTokens = _etherForTokens.add(_dividendesAmount);
            emit WithdrawDividendes(msg.sender, _dividendesAmount);
        }
        if (_tokensOwner == _valueTokens) {
             
            bookKeeper[msg.sender] = 0;
            balances[msg.sender] = 0;
        } else {
           bookKeeper[msg.sender] = block.number;
           balances[msg.sender] = balances[msg.sender].sub(_valueTokens);
        }
        if (_etherForTokens > _contracBalance) {
            _etherForTokens = _contracBalance;
        }

        msg.sender.transfer(_etherForTokens);

        emit WithdrawTokens(msg.sender, _etherForTokens);
        emit SendOnDividend(address(0), _forDividendes);

        return true;
    }


     
     
     
    function reinvest() public payable returns(bool success) {
        require(msg.sender.isNotContract(),
                "the contract can not hold tokens");

        uint256 _dividendes = dividendesOf(msg.sender);
        uint256 _aTokenPrice = tokenPrice();

        require(_dividendes >= _aTokenPrice, "not enough dividends");

        (uint256 _amountOfTokens,
         uint256 _reverseAccess) = ethereumToTokens(_dividendes, _aTokenPrice);

        require(_amountOfTokens > 0, "tokens amount not zero");

        dividendes = dividendes.sub(_dividendes.sub(_reverseAccess));
        balances[msg.sender] = balances[msg.sender].add(_amountOfTokens);
        totalSupply = totalSupply.add(_amountOfTokens);
        bookKeeper[msg.sender] = block.number;

        emit Transfer(address(0), msg.sender, _amountOfTokens);

        return true;
    }



     
     
     
    function ethereumToTokens(uint256 _incomingEthereum, uint256 _aTokenPrice)
        private
        pure
        returns(uint256 tokensReceived, uint256 reverseAccess) {
        require(_incomingEthereum >= _aTokenPrice,
                "input ether > a token price");

        tokensReceived = _incomingEthereum.div(_aTokenPrice);

        require(tokensReceived > 0, "you can not buy 0 tokens");

        reverseAccess = _incomingEthereum.sub(tokensReceived.mul(_aTokenPrice));
    }


     
     
     
    function tokensToEthereum(uint256 _tokens, uint256 _aTokenPrice)
        private
        pure
        returns(uint256 etherReceived) {
        require(_tokens > 0, "0 tokens cannot be counted");

        etherReceived = _aTokenPrice.mul(_tokens);
    }

}