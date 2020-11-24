 

pragma solidity ^0.4.13;

contract ERC20Basic  {
    function totalSupply()public view returns(uint256);
    function balanceOf(address who)public view returns(uint256);
    function transfer(address to, uint256 value)public returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)public view returns(uint256);

    function transferFrom(address from, address to, uint256 value)public returns(
        bool
    );

    function approve(address spender, uint256 value)public returns(bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner)public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

     
    function renounceOwnership()public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}

library SafeMath {

     
    function mul(uint256 a, uint256 b)internal pure returns(uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b)internal pure returns(uint256) {
        return a / b;
    }

     
    function sub(uint256 a, uint256 b)internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b)internal pure returns(uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract nix is Ownable, StandardToken {


    string public constant symbol =  "NIX";
    string public constantname =  "NIX";
    uint256 public constant decimals = 18;
    
    uint256 reserveTokensLockTime;
    address reserveTokenAddress;


    address public depositWalletAddress;
    uint256 public weiRaised;
    using SafeMath for uint256;
    
    constructor() public {
        owner = msg.sender;
        depositWalletAddress = owner;
        totalSupply_ = 500000000 ether;  
        balances[owner] = 150000000 ether;
        emit Transfer(address(0),owner, balances[owner]);

        reserveTokensLockTime = 182 days;  
        reserveTokenAddress = 0xf6c5dE9E1a6b36ABA36c6E6e86d500BcBA9CeC96;  
        balances[reserveTokenAddress] = 350000000 ether;
        emit Transfer(address(0),reserveTokenAddress, balances[reserveTokenAddress]);
    }


     
    event Buy(address _from, uint256 _ethInWei, string userId);
    function buy(string userId)public payable {
        require(msg.value > 0);
        require(msg.sender != address(0));
        weiRaised += msg.value;
        forwardFunds();
        emit Buy(msg.sender, msg.value, userId);
    }  

      
    function forwardFunds()internal {
        depositWalletAddress.transfer(msg.value);
    }


    function changeDepositWalletAddress(address newDepositWalletAddr)public onlyOwner {
        require(newDepositWalletAddr != 0);
        depositWalletAddress = newDepositWalletAddr;
    }

    function transfer(address _to, uint256 _value) public reserveTokenLock returns (bool) {
        super.transfer(_to,_value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public reserveTokenLock returns (bool){
        super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public reserveTokenLock returns (bool) {
        super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public reserveTokenLock returns (bool) {
        super.increaseApproval(_spender, _addedValue);
    }


    modifier reserveTokenLock () {
        if(msg.sender == reserveTokenAddress){
            require(block.timestamp > reserveTokensLockTime);
            _;
        }
        else{
            _;
        }
    }
}