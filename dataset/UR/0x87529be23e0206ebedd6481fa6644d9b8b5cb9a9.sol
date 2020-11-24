 

pragma solidity ^0.4.25;


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}


contract UsdPrice {
    function USD(uint _id) public constant returns (uint256);
}


contract Ownable {
    
    address public owner;

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event OwnershipTransferred(address indexed from, address indexed to);

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract ERC20Basic {
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    function balanceOf(address who) constant public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
    
    using SafeMath for uint256;
    
    mapping (address => uint256) internal balances;
    
     
    function balanceOf(address _who) public view returns(uint256) {
        return balances[_who];
    }
    
     
    function transfer(address _to, uint256 _value) public returns(bool) {
        require(balances[msg.sender] >= _value && _value > 0 && _to != 0x0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant public returns (uint256);
    function transferFrom(address from, address to, uint256 value) public  returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StandardToken is BasicToken, ERC20, Ownable {
    
    address public MembershipContractAddr = 0x0;
    
    mapping (address => mapping (address => uint256)) internal allowances;
    
    function changeMembershipContractAddr(address _newAddr) public onlyOwner returns(bool) {
        require(_newAddr != address(0));
        MembershipContractAddr = _newAddr;
    }
    
     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }
    
    event TransferFrom(address msgSender);
     
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool) {
        require(allowances[_from][msg.sender] >= _value || msg.sender == MembershipContractAddr);
        require(balances[_from] >= _value && _value > 0 && _to != address(0));
        emit TransferFrom(msg.sender);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(msg.sender != MembershipContractAddr) {
            allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);
        }
        emit Transfer(_from, _to, _value);
        return true;
    }
    
     
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != 0x0 && _value > 0);
        if(allowances[msg.sender][_spender] > 0 ) {
            allowances[msg.sender][_spender] = 0;
        }
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}

contract BurnableToken is StandardToken {
    
    address public ICOaddr;
    address public privateSaleAddr;
    
    constructor() public {
        ICOaddr = 0x0;
        privateSaleAddr = 0x0;
    }
    
    event TokensBurned(address indexed burner, uint256 value);
    
    function burnFrom(address _from, uint256 _tokens) public onlyOwner {
        require(ICOaddr == _from || privateSaleAddr == _from);
        if(balances[_from] < _tokens) {
            emit TokensBurned(_from,balances[_from]);
            emit Transfer(_from, address(0), balances[_from]);
            balances[_from] = 0;
            totalSupply = totalSupply.sub(balances[_from]);
        } else {
            balances[_from] = balances[_from].sub(_tokens);
            totalSupply = totalSupply.sub(_tokens);
            emit TokensBurned(_from, _tokens);
            emit Transfer(_from, address(0), _tokens);
        }
    }
}


contract AIB is BurnableToken {
    
    constructor() public {
        name = "AI Bank";
        symbol = "AIB";
        decimals = 18;
        totalSupply = 856750000e18;
        balances[owner] = totalSupply;
        emit Transfer(address(this), owner, totalSupply);
    }
}


contract PrivateSale is Ownable {
    
    using SafeMath for uint256;
    
    event PurchaseMade(address indexed by, uint256 tokensPurchased, uint256 tokenPricee);
    event TokenPriceChanged(uint256 oldPrice, uint256 newPrice);
    event BonusChanged(uint256 oldBonus, uint256 newBonus);
    
    UsdPrice public fiat;
    AIB public AIBToken;
    
    uint256 public tokenPrice;
    uint256 public bonus;
    uint256 public deadline;
    
    constructor() public {
        fiat = UsdPrice(0x8055d0504666e2B6942BeB8D6014c964658Ca591);
        tokenPrice = 5;
        bonus = 35;
        deadline = 0;
    }
    
    function startSale() public onlyOwner {
        deadline = now.add(120 days);
    }
    
     
    function setBonus(uint256 _newBonus) public onlyOwner {
        require(_newBonus != bonus && _newBonus > 0);
        emit BonusChanged(bonus, _newBonus);
        bonus = _newBonus;
    }
    
    
     
    function setTokenPrice(uint256 _newPrice) public onlyOwner {
        require(_newPrice != tokenPrice && _newPrice > 0);
        emit TokenPriceChanged(tokenPrice, _newPrice);
        tokenPrice = _newPrice;
    }
    
    
     
    function setAIBTokenAddress(address _addr) public onlyOwner {
        require(_addr != address(0));
        AIBToken = AIB(_addr);
    }
    
    
     
    function getTokenPriceInETH() public view returns(uint256) {
        return fiat.USD(0).mul(tokenPrice);
    }
    
     
    function getRate() public view returns(uint256) {
        uint256 e18 = 1e18;
        return e18.div(getTokenPriceInETH());
    }
    
     
    function addBonus(uint256 _tokens) internal view returns(uint256) {
        return (_tokens.add((_tokens.mul(bonus)).div(100)));
    }
    
    
     
    function buyTokens(address _addr) public payable returns(bool){
        require(_addr != address(0) && msg.value > 0);
        require(now <= deadline);
        uint256 toTransfer = addBonus(msg.value.mul(getRate()));
        AIBToken.transfer(_addr, toTransfer);
        emit PurchaseMade(_addr, toTransfer, msg.value);
        owner.transfer(msg.value);
        return true;
    }
    
    
    function() public payable {
        buyTokens(msg.sender);
    }
    
    
     
    function withdrawTokens(address _to, uint256 _value) public onlyOwner {
        require(_to != address(0) && _value > 0);
        AIBToken.transfer(_to, _value);
    }
    
}