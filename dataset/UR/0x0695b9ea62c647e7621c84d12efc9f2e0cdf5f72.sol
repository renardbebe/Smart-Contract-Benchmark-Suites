 

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
        require(
             
            !(_data[0] == 0xa9 && _data[1] == 0x05 && _data[2] == 0x9c && _data[3] == 0xbb) &&
             
            !(_data[0] == 0x09 && _data[1] == 0x5e && _data[2] == 0xa7 && _data[3] == 0xb3) &&
             
            !(_data[0] == 0x23 && _data[1] == 0xb8 && _data[2] == 0x72 && _data[3] == 0xdd),
            "buyInternal: Do not try to call transfer, approve or transferFrom"
        );
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
                .sub(_notUsedValues[i].sub(token.balanceOf(this)));
        }
    }
    
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    
     
    
    function buy10(
        address[] _tokens,
        address[] _exchanges,
        uint256[] _values,
        bytes _data1,
        bytes _data2,
        bytes _data3,
        bytes _data4,
        bytes _data5,
        bytes _data6,
        bytes _data7,
        bytes _data8,
        bytes _data9,
        bytes _data10
    ) 
        payable
        public
    {
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        buyInternal(ERC20(_tokens[0]), _exchanges[0], _values[0], _data1);
        if (_tokens.length == 1) {
            return;
        }
        buyInternal(ERC20(_tokens[1]), _exchanges[1], _values[1], _data2);
        if (_tokens.length == 2) {
            return;
        }
        buyInternal(ERC20(_tokens[2]), _exchanges[2], _values[2], _data3);
        if (_tokens.length == 3) {
            return;
        }
        buyInternal(ERC20(_tokens[3]), _exchanges[3], _values[3], _data4);
        if (_tokens.length == 4) {
            return;
        }
        buyInternal(ERC20(_tokens[4]), _exchanges[4], _values[4], _data5);
        if (_tokens.length == 5) {
            return;
        }
        buyInternal(ERC20(_tokens[5]), _exchanges[5], _values[5], _data6);
        if (_tokens.length == 6) {
            return;
        }
        buyInternal(ERC20(_tokens[6]), _exchanges[6], _values[6], _data7);
        if (_tokens.length == 7) {
            return;
        }
        buyInternal(ERC20(_tokens[7]), _exchanges[7], _values[7], _data8);
        if (_tokens.length == 8) {
            return;
        }
        buyInternal(ERC20(_tokens[8]), _exchanges[8], _values[8], _data9);
        if (_tokens.length == 9) {
            return;
        }
        buyInternal(ERC20(_tokens[9]), _exchanges[9], _values[9], _data10);
    }
    
     
    
    function buy10mint(
        IMultiToken _mtkn,
        address[] _tokens,
        address[] _exchanges,
        uint256[] _values,
        bytes _data1,
        bytes _data2,
        bytes _data3,
        bytes _data4,
        bytes _data5,
        bytes _data6,
        bytes _data7,
        bytes _data8,
        bytes _data9,
        bytes _data10
    ) 
        payable
        public
    {
        buy10(_tokens, _exchanges, _values, _data1, _data2, _data3, _data4, _data5, _data6, _data7, _data8, _data9, _data10);
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