 

pragma solidity 0.5.6;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
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

 

pragma solidity 0.5.6;

 
library SafeMath
{

   
  function mul(
    uint256 _factor1,
    uint256 _factor2
  )
    internal
    pure
    returns (uint256 product)
  {
     
     
     
    if (_factor1 == 0)
    {
      return 0;
    }

    product = _factor1 * _factor2;
    require(product / _factor1 == _factor2);
  }

   
  function div(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 quotient)
  {
     
    require(_divisor > 0);
    quotient = _dividend / _divisor;
     
  }

   
  function sub(
    uint256 _minuend,
    uint256 _subtrahend
  )
    internal
    pure
    returns (uint256 difference)
  {
    require(_subtrahend <= _minuend);
    difference = _minuend - _subtrahend;
  }

   
  function add(
    uint256 _addend1,
    uint256 _addend2
  )
    internal
    pure
    returns (uint256 sum)
  {
    sum = _addend1 + _addend2;
    require(sum >= _addend1);
  }

   
  function mod(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 remainder) 
  {
    require(_divisor != 0);
    remainder = _dividend % _divisor;
  }

}

contract TestPayable is Ownable {
    
    using SafeMath for uint256;

    address public manager;
    uint256 public recordsCount;
    uint256 public vault;
    mapping (address => uint256) public addressValueMapping;
    mapping (address => bytes32) public addressMapping;
    mapping (bytes32 => address) public hashMapping;
    
    event ReceiveEther(address indexed _from , uint256 indexed value);
    event SendBackEther(address indexed _owner, uint256 indexed value);
    
    constructor () public {
        recordsCount = 0;
        vault = 0;
    }
    
    function() external payable {
        vault = vault.add(msg.value);
        recordsCount= recordsCount.add(1);
        emit ReceiveEther(msg.sender, msg.value);
    }
    
    function sendVaultEtherBack() external onlyOwner {
        address payable payableOwner = address(uint160(owner()));
        address _owner = owner();
        payableOwner.transfer(vault);
        vault = 0;
        emit SendBackEther(_owner, vault);
    }

    
}