 

pragma solidity ^0.4.23;

 
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



 
contract Ownable {
  address public owner;
  bool public canRenounce = false;
  mapping (address => bool) public authorities;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event AuthorityAdded(address indexed authority);
  event AuthorityRemoved(address indexed authority);

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  modifier onlyAuthority() {
      require(msg.sender == owner || authorities[msg.sender]);
      _;
  }

   
  function enableRenounceOwnership() onlyOwner public {
    canRenounce = true;
  }

   
  function transferOwnership(address _newOwner) onlyOwner public {
    if(!canRenounce){
      require(_newOwner != address(0));
    }
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

   

  function addAuthority(address _authority) onlyOwner public {
    authorities[_authority] = true;
    emit AuthorityAdded(_authority);
  }


   

  function removeAuthority(address _authority) onlyOwner public {
    authorities[_authority] = false;
    emit AuthorityRemoved(_authority);
  }
}



 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}



 
contract ERC223 {
    uint public totalSupply;

     
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function decimals() public view returns (uint8 _decimals);
    function balanceOf(address who) public view returns (uint);
    function totalSupply() public view returns (uint256 _supply);
    function transfer(address to, uint value) public returns (bool ok);
    function transfer(address to, uint value, bytes data) public returns (bool ok);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}



 
 contract ContractReceiver {
 
    function tokenFallback(address _from, uint _value, bytes _data) external;
}




 
contract YUKI is ERC223, Ownable, Pausable {
    using SafeMath for uint256;

    string public name = "YUKI";
    string public symbol = "YUKI";
    uint8 public decimals = 8;
    uint256 public totalSupply = 20e9 * 1e8;
    uint256 public codeSize = 0;
    bool public mintingFinished = false;

    address public initialMarketSales = 0x1b879912446d844Fb5915bf4f773F0Db9Cd16ADb;
    address public incentiveForHolder = 0x0908e3Df5Ed1E67D2AaF38401d4826B2879e8f4b;
    address public developmentFunds = 0x52F018dc3dd621c8b2D649AC0e22E271a0dE049e;
    address public marketingFunds = 0x6771a091C97c79a52c8DD5d98A59c5d3B27F99aA;
    address public organization = 0xD90E1f987252b8EA71ac1cF14465FE9A3803267F;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public cannotSend;
    mapping (address => bool) public cannotReceive;
    mapping (address => uint256) public cannotSendUntil;
    mapping (address => uint256) public cannotReceiveUntil;

    event FrozenFunds(address indexed target, bool cannotSend, bool cannotReceive);
    event LockedFunds(address indexed target, uint256 cannotSendUntil, uint256 cannotReceiveUntil);
    event Burn(address indexed from, uint256 amount);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

     
    constructor() public {
        owner = msg.sender;

        balanceOf[initialMarketSales] = totalSupply.mul(45).div(100);
        balanceOf[incentiveForHolder] = totalSupply.mul(5).div(100);
        balanceOf[developmentFunds] = totalSupply.mul(20).div(100);
        balanceOf[marketingFunds] = totalSupply.mul(175).div(1000);
        balanceOf[organization] = totalSupply.mul(125).div(1000);
    }

    function name() public view returns (string _name) {
        return name;
    }

    function symbol() public view returns (string _symbol) {
        return symbol;
    }

    function decimals() public view returns (uint8 _decimals) {
        return decimals;
    }

    function totalSupply() public view returns (uint256 _totalSupply) {
        return totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOf[_owner];
    }
    
     
    function freezeAccounts(address[] targets, bool _cannotSend, bool _cannotReceive) onlyOwner public {
        require(targets.length > 0);

        for (uint i = 0; i < targets.length; i++) {
            cannotSend[targets[i]] = _cannotSend;
            cannotReceive[targets[i]] = _cannotReceive;
            emit FrozenFunds(targets[i], _cannotSend, _cannotReceive);
        }
    }

     
    function lockupAccounts(address[] targets, uint256 _cannotSendUntil, uint256 _cannotReceiveUntil) onlyOwner public {
        require(targets.length > 0);

        for(uint i = 0; i < targets.length; i++){
            require(cannotSendUntil[targets[i]] <= _cannotSendUntil
                    && cannotReceiveUntil[targets[i]] <= _cannotReceiveUntil);

            cannotSendUntil[targets[i]] = _cannotSendUntil;
            cannotReceiveUntil[targets[i]] = _cannotReceiveUntil;
            emit LockedFunds(targets[i], _cannotSendUntil, _cannotReceiveUntil);
        }
    }

     
    function transfer(address _to, uint _value, bytes _data) whenNotPaused public returns (bool success) {
        require(_value > 0
                && cannotSend[msg.sender] == false
                && cannotReceive[_to] == false
                && now > cannotSendUntil[msg.sender]
                && now > cannotReceiveUntil[_to]);

        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

     
    function transfer(address _to, uint _value) whenNotPaused public returns (bool success) {
        require(_value > 0
                && cannotSend[msg.sender] == false
                && cannotReceive[_to] == false
                && now > cannotSendUntil[msg.sender]
                && now > cannotReceiveUntil[_to]);

        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }

  
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_addr) }
    return size > codeSize ;
  }

    function setCodeSize(uint256 _codeSize) onlyOwner public {
        codeSize = _codeSize;
    }

     
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused public returns (bool success) {
        require(_to != address(0)
                && _value > 0
                && balanceOf[_from] >= _value
                && allowance[_from][msg.sender] >= _value
                && cannotSend[msg.sender] == false
                && cannotReceive[_to] == false
                && now > cannotSendUntil[msg.sender]
                && now > cannotReceiveUntil[_to]);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }

     
    function burn(address _from, uint256 _unitAmount) onlyOwner public {
        require(_unitAmount > 0
                && balanceOf[_from] >= _unitAmount);

        balanceOf[_from] = balanceOf[_from].sub(_unitAmount);
        totalSupply = totalSupply.sub(_unitAmount);
        emit Burn(_from, _unitAmount);
        emit Transfer(_from, address(0), _unitAmount);

    }
    
    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _unitAmount) onlyOwner canMint public returns (bool) {
        require(_unitAmount > 0);

        totalSupply = totalSupply.add(_unitAmount);
        balanceOf[_to] = balanceOf[_to].add(_unitAmount);
        emit Mint(_to, _unitAmount);
        emit Transfer(address(0), _to, _unitAmount);
        return true;
    }

     
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

     
    function batchTransfer(address[] addresses, uint256 amount) whenNotPaused public returns (bool) {
        require(amount > 0
                && addresses.length > 0
                && cannotSend[msg.sender] == false
                && now > cannotSendUntil[msg.sender]);

        amount = amount.mul(1e8);
        uint256 totalAmount = amount.mul(addresses.length);
        require(balanceOf[msg.sender] >= totalAmount);

        for (uint i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0)
                    && cannotReceive[addresses[i]] == false
                    && now > cannotReceiveUntil[addresses[i]]);

            balanceOf[addresses[i]] = balanceOf[addresses[i]].add(amount);
            emit Transfer(msg.sender, addresses[i], amount);
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(totalAmount);
        return true;
    }

    function batchTransfer(address[] addresses, uint[] amounts) whenNotPaused public returns (bool) {
        require(addresses.length > 0
                && addresses.length == amounts.length
                && cannotSend[msg.sender] == false
                && now > cannotSendUntil[msg.sender]);

        uint256 totalAmount = 0;

        for(uint i = 0; i < addresses.length; i++){
            require(amounts[i] > 0
                    && addresses[i] != address(0)
                    && cannotReceive[addresses[i]] == false
                    && now > cannotReceiveUntil[addresses[i]]);

            amounts[i] = amounts[i].mul(1e8);
            balanceOf[addresses[i]] = balanceOf[addresses[i]].add(amounts[i]);
            totalAmount = totalAmount.add(amounts[i]);
            emit Transfer(msg.sender, addresses[i], amounts[i]);
        }

        require(balanceOf[msg.sender] >= totalAmount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(totalAmount);
        return true;
    }


     

    function transferFromTo(address _from, address _to, uint256 _value, bytes _data) onlyAuthority public returns (bool) {
        require(_value > 0
                && balanceOf[_from] >= _value
                && cannotSend[_from] == false
                && cannotReceive[_to] == false
                && now > cannotSendUntil[_from]
                && now > cannotReceiveUntil[_to]);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        if(isContract(_to)) {
            ContractReceiver receiver = ContractReceiver(_to);
            receiver.tokenFallback(_from, _value, _data);
        }
        emit Transfer(_from, _to, _value, _data);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transferFromTo(address _from, address _to, uint256 _value) onlyAuthority public returns (bool) {
        bytes memory empty;
        return transferFromTo(_from, _to, _value, empty);
    }

     
    function() payable public {
        revert();
    }

     
    function tokenFallback(address from_, uint256 value_, bytes data_) external pure {
        from_;
        value_;
        data_;
        revert();
    }
}