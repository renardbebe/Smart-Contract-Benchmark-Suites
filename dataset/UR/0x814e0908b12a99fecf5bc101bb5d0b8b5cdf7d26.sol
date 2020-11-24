 

pragma solidity ^0.4.18;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
    owner = newOwner;
    OwnershipTransferred(owner, newOwner);
  }

}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
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

contract ERC20 is ERC20Basic {
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC677 is ERC20 {
    function transferAndCall(address _to, uint256 _value, bytes _data) public returns (bool success);
    
    event ERC677Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
}

contract ERC677Receiver {
    function onTokenTransfer(address _sender, uint _value, bytes _data) public returns (bool success);
}

contract ERC677Token is ERC677 {

     
    function transferAndCall(address _to, uint256 _value, bytes _data) public returns (bool success) {
        require(super.transfer(_to, _value));
        ERC677Transfer(msg.sender, _to, _value, _data);
        if (isContract(_to)) {
            contractFallback(_to, _value, _data);
        }
        return true;
    }

     

    function contractFallback(address _to, uint256 _value, bytes _data) private {
        ERC677Receiver receiver = ERC677Receiver(_to);
        require(receiver.onTokenTransfer(msg.sender, _value, _data));
    }

     
    function isContract(address _addr) private view returns (bool hasCode) {
        uint length;
        assembly { length := extcodesize(_addr) }
        return length > 0;
    }
}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        var _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract MDToken is StandardToken, ERC677Token, Ownable {
    using SafeMath for uint256;

     
    string public constant name = "Measurable Data Token";
    string public constant symbol = "MDT";
    uint256 public constant decimals = 18;
    uint256 public constant maxSupply = 10 * (10**8) * (10**decimals);  

     
    uint256 public constant TEAM_TOKENS_RESERVED = 240 * (10**6) * (10**decimals);

     
    uint256 public constant USER_GROWTH_TOKENS_RESERVED = 150 * (10**6) * (10**decimals);

     
    uint256 public constant INVESTORS_TOKENS_RESERVED = 110 * (10**6) * (10**decimals);

     
    uint256 public constant BONUS_TOKENS_RESERVED = 200 * (10**6) * (10**decimals);

     
    address public tokenSaleAddress;

     
    address public mdtTeamAddress;

     
    address public userGrowthAddress;

     
    address public investorsAddress;

     
    address public mdtFoundationAddress;

    event Burn(address indexed _burner, uint256 _value);

     
    modifier validRecipient(address _recipient) {
        require(_recipient != address(0) && _recipient != address(this));
        _;
    }

     
    function MDToken(
        address _tokenSaleAddress,
        address _mdtTeamAddress,
        address _userGrowthAddress,
        address _investorsAddress,
        address _mdtFoundationAddress,
        uint256 _presaleAmount,
        uint256 _earlybirdAmount)
        public
    {

        require(_tokenSaleAddress != address(0));
        require(_mdtTeamAddress != address(0));
        require(_userGrowthAddress != address(0));
        require(_investorsAddress != address(0));
        require(_mdtFoundationAddress != address(0));

        tokenSaleAddress = _tokenSaleAddress;
        mdtTeamAddress = _mdtTeamAddress;
        userGrowthAddress = _userGrowthAddress;
        investorsAddress = _investorsAddress;
        mdtFoundationAddress = _mdtFoundationAddress;

         
        uint256 saleAmount = _presaleAmount.add(_earlybirdAmount).add(BONUS_TOKENS_RESERVED);
        mint(tokenSaleAddress, saleAmount);
        mint(mdtTeamAddress, TEAM_TOKENS_RESERVED);
        mint(userGrowthAddress, USER_GROWTH_TOKENS_RESERVED);
        mint(investorsAddress, INVESTORS_TOKENS_RESERVED);

         
        uint256 remainingTokens = maxSupply.sub(totalSupply);
        if (remainingTokens > 0) {
            mint(mdtFoundationAddress, remainingTokens);
        }
    }

     
    function mint(address _to, uint256 _amount)
        private
        validRecipient(_to)
        returns (bool)
    {
        require(totalSupply.add(_amount) <= maxSupply);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        Transfer(0x0, _to, _amount);
        return true;
    }

     
    function approve(address _spender, uint256 _value)
        public
        validRecipient(_spender)
        returns (bool)
    {
        return super.approve(_spender, _value);
    }

     
    function transfer(address _to, uint256 _value)
        public
        validRecipient(_to)
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

     
    function transferAndCall(address _to, uint256 _value, bytes _data)
        public
        validRecipient(_to)
        returns (bool success)
    {
        return super.transferAndCall(_to, _value, _data);
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validRecipient(_to)
        returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }

     
    function burn(uint256 _value)
        public
        onlyOwner
        returns (bool)
    {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value)
        public
        onlyOwner
        returns(bool)
    {
        var _allowance = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(_from, _value);
        return true;
    }

     
    function emergencyERC20Drain(ERC20 token, uint256 amount)
        public
        onlyOwner
    {
        token.transfer(owner, amount);
    }

     
    function changeTokenSaleAddress(address _tokenSaleAddress)
        public
        onlyOwner
        validRecipient(_tokenSaleAddress)
    {
        tokenSaleAddress = _tokenSaleAddress;
    }

     
    function changeMdtTeamAddress(address _mdtTeamAddress)
        public
        onlyOwner
        validRecipient(_mdtTeamAddress)
    {
        mdtTeamAddress = _mdtTeamAddress;
    }

     
    function changeUserGrowthAddress(address _userGrowthAddress)
        public
        onlyOwner
        validRecipient(_userGrowthAddress)
    {
        userGrowthAddress = _userGrowthAddress;
    }

     
    function changeInvestorsAddress(address _investorsAddress)
        public
        onlyOwner
        validRecipient(_investorsAddress)
    {
        investorsAddress = _investorsAddress;
    }

     
    function changeMdtFoundationAddress(address _mdtFoundationAddress)
        public
        onlyOwner
        validRecipient(_mdtFoundationAddress)
    {
        mdtFoundationAddress = _mdtFoundationAddress;
    }
}