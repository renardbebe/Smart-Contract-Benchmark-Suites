 

 
 

pragma solidity ^0.4.24;

 
contract Ownable {
  address private _owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    _owner = msg.sender;
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 

contract ERC20 {
    mapping(address => uint) balances;
    mapping(address => mapping (address => uint)) allowed;

    function balanceOf(address _owner) public view returns (uint);
    function transfer(address _to, uint _value) public returns (bool);
    function transferFrom(address _from, address _to, uint _value) public returns (bool);
    function approve(address _spender, uint _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

} 


 
library SafeMath {

   
  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
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
}

 
contract CryptoIndexToken is ERC20, Ownable() {
    using SafeMath for uint;

    string public name = "Cryptoindex 100";
    string public symbol = "CIX100";
    uint public decimals = 18;

    uint public totalSupply = 300000000*1e18;
    uint public mintedAmount;

    uint public advisorsFundPercent = 3;  
    uint public teamFundPercent = 7;  

    uint public bonusFundValue;
    uint public forgetFundValue;

    bool public mintingIsStarted;
    bool public mintingIsFinished;

    address public teamFund;
    address public advisorsFund;
    address public bonusFund;
    address public forgetFund;
    address public reserveFund;

    modifier onlyController() {
        require(controllers[msg.sender] == true);
        _;
    }

     
    mapping(address => bool) public controllers;

     
    event Burn(address indexed from, uint value);
    event MintingStarted(uint timestamp);
    event MintingFinished(uint timestamp);
    

    
    constructor(address _forgetFund, address _teamFund, address _advisorsFund, address _bonusFund, address _reserveFund) public {
        controllers[msg.sender] = true;
        forgetFund = _forgetFund;
        teamFund = _teamFund;
        advisorsFund = _advisorsFund;
        bonusFund = _bonusFund;
        reserveFund = _reserveFund;
    }

    
    function startMinting(uint _forgetFundValue, uint _bonusFundValue) public onlyOwner {
        forgetFundValue = _forgetFundValue;
        bonusFundValue = _bonusFundValue;
        mintingIsStarted = true;
        emit MintingStarted(now);
    }

    
    function finishMinting() public onlyOwner {
        require(mint(forgetFund, forgetFundValue));
        uint currentMintedAmount = mintedAmount;
        require(mint(teamFund, currentMintedAmount.mul(teamFundPercent).div(100)));
        require(mint(advisorsFund, currentMintedAmount.mul(advisorsFundPercent).div(100)));
        require(mint(bonusFund, bonusFundValue));
        require(mint(reserveFund, totalSupply.sub(mintedAmount)));
        mintingIsFinished = true;
        emit MintingFinished(now);
    }

    
    function balanceOf(address _holder) public view returns (uint) {
        return balances[_holder];
    }

    
    function transfer(address _to, uint _amount) public returns (bool) {
        require(mintingIsFinished);
        require(_to != address(0) && _to != address(this));
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

     
    function batchTransfer(address[] _adresses, uint[] _values) public returns (bool) {
        require(_adresses.length == _values.length);
        for (uint i = 0; i < _adresses.length; i++) {
            require(transfer(_adresses[i], _values[i]));
        }
        return true;
    }

    
    function transferFrom(address _from, address _to, uint _amount) public returns (bool) {
        require(mintingIsFinished);

        require(_to != address(0) && _to != address(this));
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

     
    function addController(address _controller) public onlyOwner {
        require(mintingIsStarted);
        controllers[_controller] = true;
    }
    
     
    function removeController(address _controller) public onlyOwner {
        controllers[_controller] = false;
    }
    
     
    function batchMint(address[] _adresses, uint[] _values) public onlyController {
        require(_adresses.length == _values.length);
        for (uint i = 0; i < _adresses.length; i++) {
            require(mint(_adresses[i], _values[i]));
            emit Transfer(address(0), _adresses[i], _values[i]);
        }
    }

    function burn(address _from, uint _value) public {
        if (msg.sender != _from) {
          require(!mintingIsFinished);
           
           
          require(msg.sender == this.owner());
          mintedAmount = mintedAmount.sub(_value);          
        } else {
          require(mintingIsFinished);
          totalSupply = totalSupply.sub(_value);
        }
        balances[_from] = balances[_from].sub(_value);
        emit Burn(_from, _value);
    }
    
    function approve(address _spender, uint _amount) public returns (bool) {
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }


    
    function allowance(address _owner, address _spender) public view returns (uint) {
        return allowed[_owner][_spender];
    }

     
    function transferAnyTokens(address _tokenAddress, uint _amount) 
        public
        returns (bool success) {
        return ERC20(_tokenAddress).transfer(this.owner(), _amount);
    }

    function mint(address _to, uint _value) internal returns (bool) {
         
        require(mintingIsStarted);
        require(!mintingIsFinished);
        require(mintedAmount.add(_value) <= totalSupply);
        balances[_to] = balances[_to].add(_value);
        mintedAmount = mintedAmount.add(_value);
        return true;
    }
}