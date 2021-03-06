 

pragma solidity ^0.4.24;
 

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
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
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 




contract IMultiToken {
    function changeableTokenCount() external view returns(uint16 count);
    function tokens(uint256 i) public view returns(ERC20);
    function weights(address t) public view returns(uint256);
    function totalSupply() public view returns(uint256);
    function mint(address _to, uint256 _amount) public;
}


contract BancorBuyer {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public tokenBalances;  

    function sumWeightOfMultiToken(IMultiToken mtkn) public view returns(uint256 sumWeight) {
        for (uint i = mtkn.changeableTokenCount(); i > 0; i--) {
            sumWeight += mtkn.weights(mtkn.tokens(i - 1));
        }
    }
    
    function allBalances(address _account, address[] _tokens) public view returns(uint256[]) {
        uint256[] memory tokenValues = new uint256[](_tokens.length);
        for (uint i = 0; i < _tokens.length; i++) {
            tokenValues[i] = tokenBalances[_account][_tokens[i]];
        }
        return tokenValues;
    }

    function deposit(address _beneficiary, address[] _tokens, uint256[] _tokenValues) payable external {
        if (msg.value > 0) {
            balances[_beneficiary] = balances[_beneficiary].add(msg.value);
        }

        for (uint i = 0; i < _tokens.length; i++) {
            ERC20 token = ERC20(_tokens[i]);
            uint256 tokenValue = _tokenValues[i];

            uint256 balance = token.balanceOf(this);
            token.transferFrom(msg.sender, this, tokenValue);
            require(token.balanceOf(this) == balance.add(tokenValue));
            tokenBalances[_beneficiary][token] = tokenBalances[_beneficiary][token].add(tokenValue);
        }
    }
    
    function withdrawInternal(address _to, uint256 _value, address[] _tokens, uint256[] _tokenValues) internal {
        if (_value > 0) {
            _to.transfer(_value);
            balances[msg.sender] = balances[msg.sender].sub(_value);
        }

        for (uint i = 0; i < _tokens.length; i++) {
            ERC20 token = ERC20(_tokens[i]);
            uint256 tokenValue = _tokenValues[i];

            uint256 tokenBalance = token.balanceOf(this);
            token.transfer(_to, tokenValue);
            require(token.balanceOf(this) == tokenBalance.sub(tokenValue));
            tokenBalances[msg.sender][token] = tokenBalances[msg.sender][token].sub(tokenValue);
        }
    }

    function withdraw(address _to, uint256 _value, address[] _tokens, uint256[] _tokenValues) external {
        withdrawInternal(_to, _value, _tokens, _tokenValues);
    }
    
    function withdrawAll(address _to, address[] _tokens) external {
        uint256[] memory tokenValues = allBalances(msg.sender, _tokens);
        withdrawInternal(_to, balances[msg.sender], _tokens, tokenValues);
    }

     
     
     
     
     

     
     
     

     
     

     
     
     

     
     
     
     
     
    
    function buyInternal(
        ERC20 token,
        address _exchange,
        uint256 _value,
        bytes _data
    ) 
        internal
    {
        uint256 tokenBalance = token.balanceOf(this);
        require(_exchange.call.value(_value)(_data));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        tokenBalances[msg.sender][token] = tokenBalances[msg.sender][token]
            .add(token.balanceOf(this).sub(tokenBalance));
    }
    
    function mintInternal(
        IMultiToken _mtkn,
        uint256[] _notUsedValues
    ) 
        internal
    {
        uint256 totalSupply = _mtkn.totalSupply();
        uint256 bestAmount = uint256(-1);
        uint256 tokensCount = _mtkn.changeableTokenCount();
        for (uint i = 0; i < tokensCount; i++) {
            ERC20 token = _mtkn.tokens(i);

             
            uint256 thisTokenBalance = tokenBalances[msg.sender][token];
            uint256 mtknTokenBalance = token.balanceOf(_mtkn);
            _notUsedValues[i] = token.balanceOf(this);
            token.approve(_mtkn, thisTokenBalance);
            
            uint256 amount = totalSupply.mul(thisTokenBalance).div(mtknTokenBalance);
            if (amount < bestAmount) {
                bestAmount = amount;
            }
        }

         
        _mtkn.mint(msg.sender, bestAmount);
        
        for (i = 0; i < tokensCount; i++) {
            token = _mtkn.tokens(i);
            token.approve(_mtkn, 0);
            tokenBalances[msg.sender][token] = tokenBalances[msg.sender][token]
                .sub(token.balanceOf(this).sub(_notUsedValues[i]));
        }
    }
    
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    
     
    
    function buy1(
        address[] _tokens,
        address[] _exchanges,
        uint256[] _values,
        bytes _data1
    ) 
        payable
        public
    {
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        buyInternal(ERC20(_tokens[0]), _exchanges[0], _values[0], _data1);
    }

    function buy2(
        address[] _tokens,
        address[] _exchanges,
        uint256[] _values,
        bytes _data1,
        bytes _data2
    ) 
        payable
        public
    {
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        buyInternal(ERC20(_tokens[0]), _exchanges[0], _values[0], _data1);
        buyInternal(ERC20(_tokens[1]), _exchanges[1], _values[1], _data2);
    }
    
    function buy3(
        address[] _tokens,
        address[] _exchanges,
        uint256[] _values,
        bytes _data1,
        bytes _data2,
        bytes _data3
    ) 
        payable
        public
    {
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        buyInternal(ERC20(_tokens[0]), _exchanges[0], _values[0], _data1);
        buyInternal(ERC20(_tokens[1]), _exchanges[1], _values[1], _data2);
        buyInternal(ERC20(_tokens[2]), _exchanges[2], _values[2], _data3);
    }
    
    function buy4(
        address[] _tokens,
        address[] _exchanges,
        uint256[] _values,
        bytes _data1,
        bytes _data2,
        bytes _data3,
        bytes _data4
    ) 
        payable
        public
    {
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        buyInternal(ERC20(_tokens[0]), _exchanges[0], _values[0], _data1);
        buyInternal(ERC20(_tokens[1]), _exchanges[1], _values[1], _data2);
        buyInternal(ERC20(_tokens[2]), _exchanges[2], _values[2], _data3);
        buyInternal(ERC20(_tokens[3]), _exchanges[3], _values[3], _data4);
    }
    
    function buy5(
        address[] _tokens,
        address[] _exchanges,
        uint256[] _values,
        bytes _data1,
        bytes _data2,
        bytes _data3,
        bytes _data4,
        bytes _data5
    ) 
        payable
        public
    {
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        buyInternal(ERC20(_tokens[0]), _exchanges[0], _values[0], _data1);
        buyInternal(ERC20(_tokens[1]), _exchanges[1], _values[1], _data2);
        buyInternal(ERC20(_tokens[2]), _exchanges[2], _values[2], _data3);
        buyInternal(ERC20(_tokens[3]), _exchanges[3], _values[3], _data4);
        buyInternal(ERC20(_tokens[4]), _exchanges[4], _values[4], _data5);
    }
    
     
    
    function buy1mint(
        IMultiToken _mtkn,
        address[] _tokens,
        address[] _exchanges,
        uint256[] _values,
        bytes _data1
    ) 
        payable
        public
    {
        buy1(_tokens, _exchanges, _values, _data1);
        mintInternal(_mtkn, _values);
    }
    
    function buy2mint(
        IMultiToken _mtkn,
        address[] _tokens,
        address[] _exchanges,
        uint256[] _values,
        bytes _data1,
        bytes _data2
    ) 
        payable
        public
    {
        buy2(_tokens, _exchanges, _values, _data1, _data2);
        mintInternal(_mtkn, _values);
    }
    
    function buy3mint(
        IMultiToken _mtkn,
        address[] _tokens,
        address[] _exchanges,
        uint256[] _values,
        bytes _data1,
        bytes _data2,
        bytes _data3
    ) 
        payable
        public
    {
        buy3(_tokens, _exchanges, _values, _data1, _data2, _data3);
        mintInternal(_mtkn, _values);
    }
    
    function buy4mint(
        IMultiToken _mtkn,
        address[] _tokens,
        address[] _exchanges,
        uint256[] _values,
        bytes _data1,
        bytes _data2,
        bytes _data3,
        bytes _data4
    ) 
        payable
        public
    {
        buy4(_tokens, _exchanges, _values, _data1, _data2, _data3, _data4);
        mintInternal(_mtkn, _values);
    }
    
    function buy5mint(
        IMultiToken _mtkn,
        address[] _tokens,
        address[] _exchanges,
        uint256[] _values,
        bytes _data1,
        bytes _data2,
        bytes _data3,
        bytes _data4,
        bytes _data5
    ) 
        payable
        public
    {
        buy5(_tokens, _exchanges, _values, _data1, _data2, _data3, _data4, _data5);
        mintInternal(_mtkn, _values);
    }
    
     
    
    function buyOne(
        address _token,
        address _exchange,
        uint256 _value,
        bytes _data
    ) 
        payable
        public
    {
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        buyInternal(ERC20(_token), _exchange, _value, _data);
    }
    
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
     
     
     
     
     
     
     
     
     

     
     
     
     
     

     
            
     
     
     
     
     
     
     

     
     
     
     
     
     
     
     
     
     
     

     
     
     
     

     
     
     
     
     
            
     
     
     
     
     

     
     

     
     
     
     
     
     

}