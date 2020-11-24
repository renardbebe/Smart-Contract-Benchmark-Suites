 

pragma solidity ^0.4.24;



 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}



interface DelegatedERC20 {
    function allowance(address _owner, address _spender) external view returns (uint256); 
    function transferFrom(address from, address to, uint256 value, address sender) external returns (bool); 
    function approve(address _spender, uint256 _value, address sender) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value, address sender) external returns (bool);
}


interface ICapTables {
    function balanceOf(uint256 token, address user) external view returns (uint256);
    function initialize(uint256 supply, address holder) external returns (uint256);
    function migrate(uint256 security, address newAddress) external;
    function totalSupply(uint256 security) external view returns (uint256);
    function transfer(uint256 security, address src, address dest, uint256 amount) external;
}


 
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


 
contract DelegatedTokenLogic is Ownable, DelegatedERC20 {
    using SafeMath for uint256;

    address public capTables;
    address public front;

     
    uint256 public index;

    mapping (address => mapping (address => uint256)) internal allowed;

    modifier onlyFront() {
        require(msg.sender == front, "this method is reserved for the token front");
        _;
    }

     
    function setFront(address _front) public onlyOwner {
        front = _front;
    }

     
    function totalSupply() public view returns (uint256) {
        return ICapTables(capTables).totalSupply(index);
    }

     
    function transfer(address _to, uint256 _value, address sender) 
        public 
        onlyFront 
        returns (bool) 
    {
        require(_to != address(0), "tokens MUST NOT be transferred to the zero address");
        ICapTables(capTables).transfer(index, sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ICapTables(capTables).balanceOf(index, _owner);
    }
     
    function transferFrom(address _from, address _to, uint256 _value, address sender) 
        public 
        onlyFront
        returns (bool) 
    {
        require(_to != address(0), "tokens MUST NOT go to the zero address");
        require(_value <= allowed[_from][sender], "transfer value MUST NOT exceed allowance");

        ICapTables(capTables).transfer(index, _from, _to, _value);
        allowed[_from][sender] = allowed[_from][sender].sub(_value);
        return true;
    }

     
    function approve(address _spender, uint256 _value, address sender) 
        public 
        onlyFront
        returns (bool) 
    {
        allowed[sender][_spender] = _value;
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

}


 
contract IndexConsumer {

    using SafeMath for uint256;

     
    uint256 private freshIndex = 0;

     
    function nextIndex() internal returns (uint256) {
        uint256 theIndex = freshIndex;
        freshIndex = freshIndex.add(1);
        return theIndex;
    }

}




 

contract SimplifiedLogic is IndexConsumer, DelegatedTokenLogic {

    string public name = "Test Fox Token";
    string public symbol = "TFT";


    enum TransferStatus {
        Unused,
        Active,
        Resolved
    }

     
    struct TokenTransfer {
        address src;
        address dest;
        uint256 amount;
        address spender;
        TransferStatus status;
    }
    
     
    address public resolver;

     
    mapping(uint256 => TokenTransfer) public transferRequests;

     
    bool public contractActive = true;
    
     
    event TransferRequest(
        uint256 indexed index,
        address src,
        address dest,
        uint256 amount,
        address spender
    );
    
     
    event TransferResult(
        uint256 indexed index,
        uint16 code
    );
        
     
    modifier onlyActive() {
        require(contractActive, "the contract MUST be active");
        _;
    }
    
     
    modifier onlyResolver() {
        require(msg.sender == resolver, "this method is reserved for the designated resolver");
        _;
    }

    constructor(
        uint256 _index,
        address _capTables,
        address _owner,
        address _resolver
    ) public {
        index = _index;
        capTables = _capTables;
        owner = _owner;
        resolver = _resolver;
    }

    function transfer(address _dest, uint256 _amount, address _sender) 
        public 
        onlyFront 
        onlyActive 
        returns (bool) 
    {
        uint256 txfrIndex = nextIndex();
        transferRequests[txfrIndex] = TokenTransfer(
            _sender, 
            _dest, 
            _amount, 
            _sender, 
            TransferStatus.Active
        );
        emit TransferRequest(
            txfrIndex,
            _sender,
            _dest,
            _amount,
            _sender
        );
        return false;  
    }

    function transferFrom(address _src, address _dest, uint256 _amount, address _sender) 
        public 
        onlyFront 
        onlyActive 
        returns (bool)
    {
        require(_amount <= allowed[_src][_sender], "the transfer amount MUST NOT exceed the allowance");
        uint txfrIndex = nextIndex();
        transferRequests[txfrIndex] = TokenTransfer(
            _src, 
            _dest, 
            _amount, 
            _sender, 
            TransferStatus.Active
        );
        emit TransferRequest(
            txfrIndex,
            _src,
            _dest,
            _amount,
            _sender
        );
        return false;  
    }

    function setResolver(address _resolver)
        public
        onlyOwner
    {
        resolver = _resolver;
    }

    function resolve(uint256 _txfrIndex, uint16 _code) 
        public 
        onlyResolver
        returns (bool result)
    {
        require(transferRequests[_txfrIndex].status == TransferStatus.Active, "the transfer request MUST be active");
        TokenTransfer storage tfr = transferRequests[_txfrIndex];
        result = false;
        if (_code == 0) {
            result = true;
            if (tfr.spender == tfr.src) {
                 
                ICapTables(capTables).transfer(index, tfr.src, tfr.dest, tfr.amount);
            } else {
                 
                ICapTables(capTables).transfer(index, tfr.src, tfr.dest, tfr.amount);
                allowed[tfr.src][tfr.spender] = allowed[tfr.src][tfr.spender].sub(tfr.amount);
            }
        } 
        transferRequests[_txfrIndex].status = TransferStatus.Resolved;
        emit TransferResult(_txfrIndex, _code);
    }

    function migrate(address newLogic) public onlyOwner {
        contractActive = false;
        ICapTables(capTables).migrate(index, newLogic);
    }

}