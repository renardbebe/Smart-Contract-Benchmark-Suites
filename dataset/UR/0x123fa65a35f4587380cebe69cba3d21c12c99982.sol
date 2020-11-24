 

pragma solidity ^0.5.7;

 
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}


contract EIP20Interface {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract EIP20 is EIP20Interface {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) public {
        balances[msg.sender] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);  
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);  
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);  
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}


contract BitbattleExchange{
    using SafeMath for uint256;

    constructor(address _escrow, address _namiMultiSigWallet) public {
        require(_namiMultiSigWallet != address(0));
        escrow = _escrow;
        namiMultiSigWallet = _namiMultiSigWallet;
        
         
         
        TokenAddress[0] = 0xB8c77482e45F1F44dE1745F52C74426C631bDD52;
         
        TokenAddress[1] = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
         
        TokenAddress[2] = 0x0D8775F648430679A709E98d2b0Cb6250d2887EF;
         
        TokenAddress[3] = 0xd26114cd6EE289AccF82350c8d8487fedB8A0C07;
         
        TokenAddress[4] = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
         
        TokenAddress[5] = 0x6c6EE5e31d828De241282B9606C8e98Ea48526E2;
         
        TokenAddress[6] = 0x05f4a42e251f2d52b8ed15E9FEdAacFcEF1FAD27;
         
        TokenAddress[7] = 0x1985365e9f78359a9B6AD760e32412f4a445E862;
         
        TokenAddress[8] = 0xE41d2489571d322189246DaFA5ebDe1F4699F498;
         
        TokenAddress[9] = 0x3883f5e181fccaF8410FA61e12b59BAd963fb645;
         
        TokenAddress[10] = 0xA15C7Ebe1f07CaF6bFF097D8a589fb8AC49Ae5B3;
         
        TokenAddress[11] = 0xFA1a856Cfa3409CFa145Fa4e20Eb270dF3EB21ab;
         
        TokenAddress[12] = 0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c;
         
        TokenAddress[13] = 0x6f259637dcD74C767781E37Bc6133cd6A68aa161;
         
        TokenAddress[14] = 0x744d70FDBE2Ba4CF95131626614a1763DF805B9E;
        
         
        TokenAddress[15] = 0x8d80de8A78198396329dfA769aD54d24bF90E7aa;
         
        TokenAddress[16] = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
         
        TokenAddress[17] = 0xdd974D5C2e2928deA5F71b9825b8b646686BD200;
         
        TokenAddress[18] = 0xa74476443119A942dE498590Fe1f2454d7D4aC0d;
         
        TokenAddress[19] = 0xd4fa1460F537bb9085d22C7bcCB5DD450Ef28e3a;
         
        TokenAddress[20] = 0xB63B606Ac810a52cCa15e44bB630fd42D8d1d83d;
         
        TokenAddress[21] = 0xb7cB1C96dB6B22b0D3d9536E0108d062BD488F74;
         
        TokenAddress[22] = 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942;
         
        TokenAddress[23] = 0xA4e8C3Ec456107eA67d3075bF9e3DF3A75823DB0;
         
        TokenAddress[24] = 0xEF68e7C694F40c8202821eDF525dE3782458639f;
         
        TokenAddress[25] = 0xbf2179859fc6D5BEE9Bf9158632Dc51678a4100e;
         
        TokenAddress[26] = 0x595832F8FC6BF59c85C527fEC3740A1b7a361269;
         
        TokenAddress[27] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    }

     
     
    address public escrow;
    uint public minWithdraw = 1 * 10**18;
    uint public maxWithdraw = 1000000 * 10**18;

     
    address public namiMultiSigWallet;
    
     
    mapping(uint256 => address) public TokenAddress;


     
    mapping(address => bool) public isController;

     
    event Withdraw(address indexed user, uint amount, uint timeWithdraw, uint tokenIndex);

    modifier onlyEscrow() {
        require(msg.sender == escrow);
        _;
    }

    modifier onlyNamiMultisig {
        require(msg.sender == namiMultiSigWallet);
        _;
    }

    modifier onlyController {
        require(isController[msg.sender] == true);
        _;
    }

    
     
    function() external payable {}
    function changeEscrow(address _escrow) public
    onlyNamiMultisig
    {
        require(_escrow != address(0));
        escrow = _escrow;
    }

    function changeMinWithdraw(uint _minWithdraw) public
    onlyEscrow
    {
        require(_minWithdraw != 0);
        minWithdraw = _minWithdraw;
    }

    function changeMaxWithdraw(uint _maxNac) public
    onlyEscrow
    {
        require(_maxNac != 0);
        maxWithdraw = _maxNac;
    }

     
     
    function withdrawEther(uint _amount, address payable _to) public
    onlyEscrow
    {
        require(_to != address(0x0));
         
        if (address(this).balance > 0) {
            _to.transfer(_amount);
        }
    }

     
    function setController(address _controller)
    public
    onlyEscrow
    {
        require(!isController[_controller]);
        isController[_controller] = true;
    }

     
    function removeController(address _controller)
    public
    onlyEscrow
    {
        require(isController[_controller]);
        isController[_controller] = false;
    }
    
     
    function updateTokenAddress(address payable _tokenAddress, uint _tokenIndex) public
    onlyEscrow
    {
        require(_tokenAddress != address(0));
        TokenAddress[_tokenIndex] = _tokenAddress;
    }


    function withdrawToken(address _account, uint _amount, uint _tokenIndex) public
    onlyController
    {
        require(_account != address(0x0) && _amount != 0);
        require(_amount >= minWithdraw && _amount <= maxWithdraw);
        
         
        require(TokenAddress[_tokenIndex] != address(0));
        EIP20 ERC20Token = EIP20(TokenAddress[_tokenIndex]);
        if (ERC20Token.balanceOf(address(this)) >= _amount) {
            ERC20Token.transfer(_account, _amount);
        } else {
            revert();
        }
         
        emit Withdraw(_account, _amount, now, _tokenIndex);
    }
}