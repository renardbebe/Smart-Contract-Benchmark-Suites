 

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
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
contract GTXRecord is Ownable {
    using SafeMath for uint256;

     
     
    uint256 public conversionRate;

     
    bool public lockRecords;

     
    uint256 public maxRecords;

     
    uint256 public totalClaimableGTX;

     
     
    mapping (address => uint256) public claimableGTX;

    event GTXRecordCreate(
        address indexed _recordAddress,
        uint256 _finPointAmount,
        uint256 _gtxAmount
    );

    event GTXRecordUpdate(
        address indexed _recordAddress,
        uint256 _finPointAmount,
        uint256 _gtxAmount
    );

    event GTXRecordMove(
        address indexed _oldAddress,
        address indexed _newAddress,
        uint256 _gtxAmount
    );

    event LockRecords();

     
    modifier canRecord() {
        require(conversionRate > 0);
        require(!lockRecords);
        _;
    }

     
    constructor (uint256 _maxRecords) public {
        maxRecords = _maxRecords;
    }

     
    function setConversionRate(uint256 _conversionRate) external onlyOwner{
        require(_conversionRate <= 1000);  
        require(_conversionRate > 0);  
        conversionRate = _conversionRate;
    }

    
    function lock() public onlyOwner returns (bool) {
        lockRecords = true;
        emit LockRecords();
        return true;
    }

     
    function recordCreate(address _recordAddress, uint256 _finPointAmount, bool _applyConversionRate) public onlyOwner canRecord {
        require(_finPointAmount >= 100000, "cannot be less than 100000 FIN (in WEI)");  
        uint256 afterConversionGTX;
        if(_applyConversionRate == true) {
            afterConversionGTX = _finPointAmount.mul(conversionRate).div(100);
        } else {
            afterConversionGTX = _finPointAmount;
        }
        claimableGTX[_recordAddress] = claimableGTX[_recordAddress].add(afterConversionGTX);
        totalClaimableGTX = totalClaimableGTX.add(afterConversionGTX);
        require(totalClaimableGTX <= maxRecords, "total token record (contverted GTX) cannot exceed GTXRecord token limit");
        emit GTXRecordCreate(_recordAddress, _finPointAmount, claimableGTX[_recordAddress]);
    }

     
    function recordUpdate(address _recordAddress, uint256 _finPointAmount, bool _applyConversionRate) public onlyOwner canRecord {
        require(_finPointAmount >= 100000, "cannot be less than 100000 FIN (in WEI)");  
        uint256 afterConversionGTX;
        totalClaimableGTX = totalClaimableGTX.sub(claimableGTX[_recordAddress]);
        if(_applyConversionRate == true) {
            afterConversionGTX  = _finPointAmount.mul(conversionRate).div(100);
        } else {
            afterConversionGTX  = _finPointAmount;
        }
        claimableGTX[_recordAddress] = afterConversionGTX;
        totalClaimableGTX = totalClaimableGTX.add(claimableGTX[_recordAddress]);
        require(totalClaimableGTX <= maxRecords, "total token record (contverted GTX) cannot exceed GTXRecord token limit");
        emit GTXRecordUpdate(_recordAddress, _finPointAmount, claimableGTX[_recordAddress]);
    }

     
    function recordMove(address _oldAddress, address _newAddress) public onlyOwner canRecord {
        require(claimableGTX[_oldAddress] != 0, "cannot move a zero record");
        require(claimableGTX[_newAddress] == 0, "destination must not already have a claimable record");

        claimableGTX[_newAddress] = claimableGTX[_oldAddress];
        claimableGTX[_oldAddress] = 0;

        emit GTXRecordMove(_oldAddress, _newAddress, claimableGTX[_newAddress]);
    }

}